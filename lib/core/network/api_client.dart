import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/env.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final _storage = const FlutterSecureStorage();
  final _client = http.Client();

  static const String tokenKey = 'trocly_access_token';
  static const String refreshTokenKey = 'trocly_refresh_token';
  static const String userKey = 'trocly_current_user';

  Future<String?> getAccessToken() async {
    return await _storage.read(key: tokenKey);
  }

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: tokenKey, value: accessToken);
    await _storage.write(key: refreshTokenKey, value: refreshToken);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: userKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Map<String, String> _headers(String? token, {bool isJson = true}) {
    final map = <String, String>{};
    if (isJson) {
      map['Content-Type'] = 'application/json';
    }
    if (token != null && token.isNotEmpty) {
      map['Authorization'] = 'Bearer $token';
    }
    return map;
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final urlString = '${Env.apiUrl}$cleanPath';
    final baseUri = Uri.parse(urlString);
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryMap = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return baseUri.replace(queryParameters: queryMap);
    }
    return baseUri;
  }

  Future<http.Response> get(String path, {Map<String, dynamic>? query}) async {
    final token = await getAccessToken();
    final uri = _uri(path, query);
    debugPrint('[API GET] $uri');
    return await _client.get(uri, headers: _headers(token));
  }

  Future<http.Response> post(String path, {dynamic body}) async {
    final token = await getAccessToken();
    final uri = _uri(path);
    debugPrint('[API POST] $uri');
    return await _client.post(
      uri,
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> patch(String path, {dynamic body}) async {
    final token = await getAccessToken();
    final uri = _uri(path);
    debugPrint('[API PATCH] $uri');
    return await _client.patch(
      uri,
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  Future<http.Response> delete(String path) async {
    final token = await getAccessToken();
    final uri = _uri(path);
    debugPrint('[API DELETE] $uri');
    return await _client.delete(uri, headers: _headers(token));
  }
}
