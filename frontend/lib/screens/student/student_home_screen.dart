import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';
import 'package:student_tracking_app/services/fcm_service.dart';
import 'dart:async';
import '../../models/announcement.dart';
import '../../models/paginated.dart';
import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/pagination_bar.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _page = 1;
  int? _selectedTeacherId;
  List<TeacherFilterItem>? _teachers;
  late Future<Paginated<Announcement>> _future;
  StreamSubscription<RemoteMessage>? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    _future = StudentService.listAnnouncements(page: _page);
    _loadTeachers();
    if (!kIsWeb) {
      FcmService.registerTokenWithBackend(force: true);
      _fcmSubscription = FirebaseMessaging.onMessage.listen((_) => _refresh());
    }
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    final teachers = await StudentService.listAnnouncementTeachers();
    if (mounted) setState(() => _teachers = teachers);
  }

  Future<void> _refresh() async {
    final updated = await StudentService.listAnnouncements(
      page: _page,
      teacherId: _selectedTeacherId,
    );
    if (mounted) setState(() => _future = Future.value(updated));
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _future = StudentService.listAnnouncements(page: page, teacherId: _selectedTeacherId);
    });
  }

  void _onTeacherChanged(int? teacherId) {
    setState(() {
      _selectedTeacherId = teacherId;
      _page = 1;
      _future = StudentService.listAnnouncements(page: 1, teacherId: teacherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showFilter = _teachers != null && _teachers!.length > 1;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.student)),
      drawer: AppDrawer(
        onProfileTap: () => Navigator.of(context).pushNamed('/student/profile'),
        actions: [
          DrawerAction(
            icon: Icons.qr_code,
            label: l10n.addTeacherCode,
            onTap: () async {
              await Navigator.of(context).pushNamed('/student/add-teacher-code');
              _refresh();
            },
          ),
          DrawerAction(
            icon: Icons.grade_outlined,
            label: l10n.myGrades,
            onTap: () => Navigator.of(context).pushNamed('/student/grades'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: DropdownButtonFormField<int?>(
                value: _selectedTeacherId,
                decoration: InputDecoration(
                  labelText: l10n.filterByTeacher,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allTeachers)),
                  for (final t in _teachers!)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: _onTeacherChanged,
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<Paginated<Announcement>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('${(snapshot.error as ApiException?)?.message ?? snapshot.error}'),
                      ),
                    ]);
                  }
                  final result = snapshot.data!;
                  final announcements = result.items;
                  if (result.total == 0) {
                    return ListView(children: [
                      Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noAnnouncementsYet)),
                    ]);
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: announcements.length,
                          separatorBuilder: (_, _) => const Divider(),
                          itemBuilder: (context, index) {
                            final a = announcements[index];
                            return Card(
                              child: ListTile(
                                title: Text(a.text),
                                subtitle: Text(
                                  '${a.teacherName} · ${a.classrooms.join(", ")}\n${a.createdAt.toLocal().toString().split('.').first}',
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
                      PaginationBar(
                        page: result.page,
                        totalPages: result.totalPages,
                        onPageChange: _goToPage,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
