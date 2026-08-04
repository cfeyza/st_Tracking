import '../models/auth.dart';
import 'api_client.dart';
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
    return response;
  }

  static Future<void> logout() async {
    await Session.clear();
  }
}
