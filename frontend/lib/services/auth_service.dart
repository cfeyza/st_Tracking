import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/auth.dart';
import 'api_client.dart';
import 'fcm_service.dart';
import 'session.dart';

class AuthService {
  static Future<void> register({
    required String role,
    required String name,
    required String surname,
    required String email,
    required String password,
    int? schoolId,
  }) async {
    await ApiClient.post(
      '/auth/register',
      auth: false,
      body: {
        'role': role,
        'name': name,
        'surname': surname,
        'email': email,
        'password': password,
        'school_id': ?schoolId,
      },
    );
  }

  static Future<LoginResponse> login(String email, String password) async {
    final json = await ApiClient.post(
      '/auth/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    final response = LoginResponse.fromJson(json as Map<String, dynamic>);
    await Session.save(response.accessToken, response.role);
    if (response.role == 'student' && !kIsWeb) {
      // Fire-and-forget: FCM setup (Android-only, see FcmService) must never
      // block login/navigation if it hangs or fails (e.g. a device without
      // push permission). Web doesn't send push, so skip it entirely there.
      unawaited(FcmService.registerTokenWithBackend());
    }
    return response;
  }

  static Future<void> logout() async {
    if (!kIsWeb && Session.role == 'student') {
      await FcmService.deleteTokenFromBackend();
    }
    await Session.clear();
  }
}
