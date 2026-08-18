import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
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
    try {
      final token = tokenOverride ??
          await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 10));
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();

      if (!force && prefs.getString(_lastSentTokenKey) == token) {
        return;
      }
      await ApiClient.post('/student/device-token', body: {'token': token});
      await prefs.setString(_lastSentTokenKey, token);
    } catch (e) {
      debugPrint("Failed to register FCM token: $e");
    }
  }

  /// Removes this device's FCM token from the backend on logout.
  /// Must be called while the session is still valid (before Session.clear()).
  /// Clears the local cache regardless so the next login re-registers cleanly.
  static Future<void> deleteTokenFromBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_lastSentTokenKey);
    await prefs.remove(_lastSentTokenKey);
    if (token == null) return;
    try {
      final encodedToken = Uri.encodeQueryComponent(token);
      await ApiClient.delete('/student/device-token?token=$encodedToken');
    } catch (e) {
      debugPrint("Failed to delete FCM token: $e");
    }
  }
}