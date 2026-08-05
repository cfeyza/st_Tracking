import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'session.dart';

/// Handles FCM setup: permission request, local-notification display while
/// foregrounded, and keeping the backend's copy of this device's token
/// current. Android-only for now (no web push).
class FcmService {
  static const _channelId = 'announcements';
  static const _channelName = 'Announcements';
  static const _lastSentTokenKey = 'fcm_last_sent_token';

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'New announcements from your teachers',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, _channelName, importance: Importance.high),
        ),
      );
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      registerTokenWithBackend(tokenOverride:newToken);
    });

    if (Session.isLoggedIn && Session.role == 'student') {
      await registerTokenWithBackend();
    }
  }

  static Future<void> registerTokenWithBackend({String? tokenOverride, bool force = false}) async {
    final token = tokenOverride ?? await FirebaseMessaging.instance.getToken();
    print(">>> FCM TOKEN ALINDI: $token"); // Log 1
    if (token == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    // EĞER force true DEĞİLSE ve önceden kaydedilmişse atla
    if (!force && prefs.getString(_lastSentTokenKey) == token) {
      print(">>> FCM TOKEN ZATEN KAYITLI, ATLANDI."); // Log 2
      return;
    }
    print(">>> BACKEND'E TOKEN GÖNDERİLİYOR..."); // Log 3
    try {
      await ApiClient.post('/student/device-token', body: {'token': token});
      await prefs.setString(_lastSentTokenKey, token);
      print("FCM Token successfully registered with backend: $token");
    } catch (e) {
      print("Failed to register FCM token: $e");
    }
  }
}

// DİKKAT: Bu fonksiyon bir sınıfın dışında (Top-level) ve @pragma('vm:entry-point') ile tanımlanmalıdır!
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Arka planda veya uygulama kapalıyken mesaj geldiğinde işletim sistemi bildirimi otomatik gösterir.
  // Burada ekstra bir işlem yapmanız gerekirse yapabilirsiniz.
  print("Background FCM message received: ${message.messageId}");
}