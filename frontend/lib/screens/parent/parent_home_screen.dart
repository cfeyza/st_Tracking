import 'package:flutter/material.dart';

import '../../models/announcement.dart';
import '../../models/paginated.dart';
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
  late Future<Paginated<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.listAnnouncements(page: _page);
  }

  Future<void> _refresh() async {
    setState(() => _future = ParentService.listAnnouncements(page: _page));
    await _future;
  }

  void _goToPage(int page) {
    setState(() {
      _page = page;
      _future = ParentService.listAnnouncements(page: _page);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent')),
      drawer: AppDrawer(
        onProfileTap: () => Navigator.of(context).pushNamed('/parent/profile'),
        actions: [
          DrawerAction(
            icon: Icons.qr_code,
            label: 'Add student code',
            onTap: () async {
              await Navigator.of(context).pushNamed('/parent/add-student-code');
              _refresh();
            },
          ),
          DrawerAction(
            icon: Icons.people_outline,
            label: 'My students',
            onTap: () => Navigator.of(context).pushNamed('/parent/students'),
          ),
        ],
      ),
      body: RefreshIndicator(
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
            if (announcements.isEmpty) {
              return ListView(children: const [
                Padding(padding: EdgeInsets.all(24), child: Text('No announcements yet.')),
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
                            'For ${a.studentName} · ${a.teacherName} · ${a.classrooms.join(", ")}\n'
                            '${a.createdAt.toLocal().toString().split('.').first}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
                PaginationBar(page: result.page, totalPages: result.totalPages, onPageChange: _goToPage),
              ],
            );
          },
        ),
      ),
    );
  }
}

