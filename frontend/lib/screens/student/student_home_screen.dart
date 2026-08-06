import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; //
import 'package:student_tracking_app/services/fcm_service.dart';
import 'dart:async';
import '../../models/announcement.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';
import '../../widgets/app_drawer.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late Future<List<Announcement>> _future;
  StreamSubscription<RemoteMessage>? _fcmSubscription; // FCM Aboneliği
  
  @override
  void initState() {
    super.initState();
    _future = StudentService.listAnnouncements();
    // Push bildirimleri sadece mobilde destekleniyor; web'de izin istemeyin.
    if (!kIsWeb) {
      // Öğrenci ekranı açıldığında token'ı backend'e yazmaya zorlayın
      FcmService.registerTokenWithBackend(force: true); //[cite: 7]

      // Uygulama açıkken (Foreground) yeni bir FCM bildirimi gelirse listenize otomatik yenileme atın
      _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) { //
        // Gelen bildirim bir anons ise arayüzü güncelleyin
        _refresh(); //[cite: 1]
      });
    }
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel(); // Memory leak olmaması için aboneliği kapatın
    super.dispose();
  }

  Future<void> _refresh() async {
    // 1. Yeni veriyi çekip bitmesini bekleyin
    final newAnnouncements = await StudentService.listAnnouncements();
    
    // 2. İşlem tamamlandıktan sonra setState ile ekranı güncelleyin
    if (mounted) {
      setState(() {
        _future = Future.value(newAnnouncements);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student')),
      drawer: AppDrawer(
        onProfileTap: () => Navigator.of(context).pushNamed('/student/profile'),
        actions: [
          DrawerAction(
            icon: Icons.qr_code,
            label: 'Add teacher code',
            onTap: () async {
              await Navigator.of(context).pushNamed('/student/add-teacher-code');
              _refresh();
            },
          ),
          DrawerAction(
            icon: Icons.grade_outlined,
            label: 'My grades',
            onTap: () => Navigator.of(context).pushNamed('/student/grades'),
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
                      '${a.teacherName} · ${a.classrooms.join(", ")}\n${a.createdAt.toLocal().toString().split('.').first}',
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
