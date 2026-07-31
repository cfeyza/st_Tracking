import 'package:shared_preferences/shared_preferences.dart';

/// Persists the JWT and role across app restarts.
class Session {
  static const _tokenKey = 'access_token';
  static const _roleKey = 'role';

  static String? token;
  static String? role;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    role = prefs.getString(_roleKey);
  }

  static Future<void> save(String newToken, String newRole) async {
    token = newToken;
    role = newRole;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    await prefs.setString(_roleKey, newRole);
  }

  static Future<void> clear() async {
    token = null;
    role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
  }

  static bool get isLoggedIn => token != null && role != null;
}
