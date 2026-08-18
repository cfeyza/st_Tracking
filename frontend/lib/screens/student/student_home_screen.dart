import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';
import 'package:student_tracking_app/services/fcm_service.dart';
import 'dart:async';

import '../../models/announcement.dart';
import '../../models/paginated.dart';
import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/meta_badge.dart';
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

  final Map<int, DateTime> _localAcks = {};

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
    try {
      final teachers = await StudentService.listAnnouncementTeachers();
      if (mounted) setState(() => _teachers = teachers);
    } catch (_) {
      // Filter dropdown is optional; a failure here is non-fatal.
    }
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

  Future<void> _acknowledge(int announcementId) async {
    try {
      final readAt = await StudentService.acknowledgeAnnouncement(announcementId);
      if (mounted) setState(() => _localAcks[announcementId] = readAt);
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        _refresh();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _showFullTextDialog(String text) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dl10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: SingleChildScrollView(
            child: Text(
              text,
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(height: 1.6),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dl10n.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final showFilter = _teachers != null && _teachers!.length > 1;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.student),
        backgroundColor: cs.surface,
      ),
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
          if (showFilter) ...[
            Container(
              color: cs.surface,
              padding: AppInsets.filterBar(context),
              child: DropdownButtonFormField<int?>(
                initialValue: _selectedTeacherId,
                decoration: InputDecoration(
                  labelText: l10n.filterByTeacher,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.allTeachers)),
                  for (final t in _teachers!)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: _onTeacherChanged,
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
          ],
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
                        child: Text(snapshot.error is ApiException
                            ? (snapshot.error as ApiException).message
                            : snapshot.error.toString()),
                      ),
                    ]);
                  }
                  final result = snapshot.data!;
                  final announcements = result.items;
                  if (result.total == 0) {
                    return ListView(children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                        child: Column(
                          children: [
                            Icon(Icons.campaign_outlined,
                                size: 40,
                                color: cs.onSurfaceVariant.withAlpha(120)),
                            const SizedBox(height: 8),
                            Text(l10n.noAnnouncementsYet,
                                style: TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ]);
                  }
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: AppInsets.page(context),
                          itemCount: announcements.length,
                          itemBuilder: (context, index) {
                            final a = announcements[index];
                            final isRead = a.isRead || _localAcks.containsKey(a.id);
                            final readAt = a.readAt ?? _localAcks[a.id];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _StudentAnnouncementCard(
                                announcement: a,
                                isRead: isRead,
                                readAt: readAt,
                                onTap: () => _showFullTextDialog(a.text),
                                onAcknowledge: () => _acknowledge(a.id),
                              ),
                            );
                          },
                        ),
                      ),
                      if (result.totalPages > 1)
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

class _StudentAnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool isRead;
  final DateTime? readAt;
  final VoidCallback onTap;
  final VoidCallback onAcknowledge;

  const _StudentAnnouncementCard({
    required this.announcement,
    required this.isRead,
    required this.readAt,
    required this.onTap,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final dateStr = DateFormat('d MMM y · HH:mm').format(announcement.createdAt.toLocal());

    return Card(
      shape: AppCard.shape(cs),
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                announcement.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (announcement.teacherName != null)
                          MetaBadge.teacher(announcement.teacherName!),
                        for (final c in announcement.classrooms) MetaBadge.classroom(c),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!isRead)
                GestureDetector(
                  onTap: onAcknowledge,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.primary, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          l10n.markAsRead,
                          style: tt.labelMedium?.copyWith(color: cs.primary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      readAt != null
                          ? '${l10n.acknowledged} · ${DateFormat('d MMM y · HH:mm').format(readAt!.toLocal())}'
                          : l10n.acknowledged,
                      style: tt.labelSmall?.copyWith(color: cs.primary),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
