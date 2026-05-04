import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _sesskeyKey = 'moodle_sesskey';

  // ─── Token management ───

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ─── Session key management ───

  static Future<void> saveSesskey(String? sesskey) async {
    if (sesskey != null) {
      await _storage.write(key: _sesskeyKey, value: sesskey);
    }
  }

  static Future<String?> getSesskey() async {
    return await _storage.read(key: _sesskeyKey);
  }

  static Future<void> deleteSesskey() async {
    await _storage.delete(key: _sesskeyKey);
    await _storage.delete(key: _tokenKey);
  }

  // ─── Headers ───

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ─── HTTP Methods ───

  static Future<Map<String, dynamic>> get(
    String url, {
    bool auth = false,
  }) async {
    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    // Add session key to URL if available
    String fullUrl = url;
    final sesskey = await getSesskey();
    if (sesskey != null && !url.contains('sesskey')) {
      fullUrl = url.contains('?') ? '$url&sesskey=$sesskey' : '$url?sesskey=$sesskey';
    }
    
    final response = await http.post(
      Uri.parse(fullUrl),
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> postMultipart(
    String url, {
    required String fileField,
    required String filePath,
    required List<int> fileBytes,
    Map<String, String>? fields,
    bool auth = false,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));

    if (auth) {
      final token = await getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    // Use fromBytes so it works on both web and native (dart:io not available on web)
    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: filePath.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(
    String url, {
    bool auth = false,
  }) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: await _headers(auth: auth),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // ─── Response handler ───

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final errorMsg = body['error'] ?? 'Something went wrong';
    throw ApiException(errorMsg, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
