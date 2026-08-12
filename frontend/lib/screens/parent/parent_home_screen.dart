import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/announcement.dart';
import '../../models/paginated.dart';
import '../../models/parent.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/pagination_bar.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _page = 1;
  int? _selectedStudentId;
  List<ParentStudentListItem>? _students;
  late Future<Paginated<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.listAnnouncements(page: _page);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await ParentService.listStudents();
    if (mounted) setState(() => _students = students);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = ParentService.listAnnouncements(page: _page, studentId: _selectedStudentId);
    });
    await _future;
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _future = ParentService.listAnnouncements(page: _page, studentId: _selectedStudentId);
    });
  }

  void _onStudentChanged(int? studentId) {
    setState(() {
      _selectedStudentId = studentId;
      _page = 1;
      _future = ParentService.listAnnouncements(page: _page, studentId: _selectedStudentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showFilter = _students != null && _students!.length > 1;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.parent)),
      drawer: AppDrawer(
        onProfileTap: () => Navigator.of(context).pushNamed('/parent/profile'),
        actions: [
          DrawerAction(
            icon: Icons.qr_code,
            label: l10n.addStudentCode,
            onTap: () async {
              await Navigator.of(context).pushNamed('/parent/add-student-code');
              _refresh();
              _loadStudents();
            },
          ),
          DrawerAction(
            icon: Icons.people_outline,
            label: l10n.myStudents,
            onTap: () => Navigator.of(context).pushNamed('/parent/students'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            if (showFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    DropdownButton<int?>(
                      value: _selectedStudentId,
                      hint: Text(l10n.allStudents),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.allStudents)),
                        for (final s in _students!)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text('${s.name} ${s.surname}'),
                          ),
                      ],
                      onChanged: _onStudentChanged,
                    ),
                  ],
                ),
              ),
            if (showFilter) const Divider(height: 1),
            Expanded(
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
                        child: Text(
                          '${(snapshot.error as ApiException?)?.message ?? snapshot.error}',
                        ),
                      ),
                    ]);
                  }
                  final result = snapshot.data!;
                  final announcements = result.items;
                  if (announcements.isEmpty) {
                    return ListView(children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l10n.noAnnouncementsYet),
                      ),
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
                                  '${l10n.parentAnnouncementMeta(a.studentName ?? '', a.teacherName ?? '', a.classrooms.join(", "))}\n'
                                  '${a.createdAt.toLocal().toString().split('.').first}',
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
          ],
        ),
      ),
    );
  }
}
