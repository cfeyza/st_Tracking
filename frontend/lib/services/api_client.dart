import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
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
  static Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (auth && Session.token != null) {
      headers['Authorization'] = 'Bearer ${Session.token}';
    }
    return headers;
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    String message = 'Request failed (${response.statusCode})';
    if (body is Map && body['detail'] != null) {
      message = body['detail'].toString();
    }
    throw ApiException(response.statusCode, message);
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    final response = await http.get(Uri.parse('$apiBaseUrl$path'), headers: _headers(auth: auth));
    return _decode(response);
  }

  static Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: _headers(auth: auth),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> delete(String path, {bool auth = true}) async {
    final response = await http.delete(Uri.parse('$apiBaseUrl$path'), headers: _headers(auth: auth));
    return _decode(response);
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
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }
}
