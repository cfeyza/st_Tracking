import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../navigation.dart';
import 'session.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Thin wrapper around the FastAPI backend: attaches the JWT, encodes/decodes
/// JSON, and turns non-2xx responses into an [ApiException] whose message is
/// the backend's `detail` string (FastAPI's standard error shape).
class ApiClient {
  static const _kTimeout = Duration(seconds: 15);
  // Persistent client reuses TCP connections (keep-alive) across requests.
  static final http.Client _client = http.Client();

  static Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && Session.token != null) {
      headers['Authorization'] = 'Bearer ${Session.token}';
    }
    return headers;
  }

  /// If [auth] is true, a 401 means the session's JWT was rejected (expired
  /// or otherwise invalid) rather than a login attempt with bad credentials,
  /// so we drop the session and bounce back to the login screen. The
  /// `Session.token != null` guard avoids piling up redundant navigations
  /// when several authenticated requests 401 around the same time.
  static dynamic _decode(http.Response response, {bool auth = true}) {
    dynamic body;
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(response.statusCode, 'Request failed (${response.statusCode})');
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    if (auth && response.statusCode == 401 && Session.token != null) {
      Session.clear();
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
    String message = 'Request failed (${response.statusCode})';
    if (body is Map && body['detail'] != null) {
      message = body['detail'].toString();
    }
    throw ApiException(response.statusCode, message);
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await _client.get(Uri.parse('$apiBaseUrl$path'), headers: _headers(auth: auth)).timeout(_kTimeout);
    return _decode(response, auth: auth);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    ).timeout(_kTimeout);
    return _decode(response, auth: auth);
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await _client.delete(Uri.parse('$apiBaseUrl$path'), headers: _headers(auth: auth)).timeout(_kTimeout);
    return _decode(response, auth: auth);
  }

  static Future<dynamic> postMultipart(
    String path, {
    required String fieldName,
    required List<int> bytes,
    required String filename,
    bool auth = true,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$apiBaseUrl$path'));
    request.headers.addAll(_headers(auth: auth)..remove('Content-Type'));
    request.files.add(http.MultipartFile.fromBytes(fieldName, bytes, filename: filename));
    final streamed = await _client.send(request).timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    return _decode(response, auth: auth);
  }
}
