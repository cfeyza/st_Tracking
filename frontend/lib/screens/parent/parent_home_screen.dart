import 'package:flutter/material.dart';

import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../widgets/app_drawer.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  late Future<List<Announcement>> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.listAnnouncements();
  }

  Future<void> _refresh() async {
    setState(() => _future = ParentService.listAnnouncements());
    await _future;
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
        child: FutureBuilder<List<Announcement>>(
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
            final announcements = snapshot.data!;
            if (announcements.isEmpty) {
              return ListView(children: const [
                Padding(padding: EdgeInsets.all(24), child: Text('No announcements yet.')),
              ]);
            }
            return ListView.separated(
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
                      '${a.createdAt.toLocal()}'.split('.').first,
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
