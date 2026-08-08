import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:greentech/Config/ApiConfig.dart';
import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Service/UserService.dart';

enum ApiErrorKind { network, server }

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.kind = ApiErrorKind.server,
  });

  const ApiException.network(this.message)
    : statusCode = null,
      kind = ApiErrorKind.network;

  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  bool get isUnauthorized => statusCode == 401;

  bool get isNetwork => kind == ApiErrorKind.network;

  @override
  String toString() => message;
}

class ApiService {
  const ApiService._();

  static final http.Client _client = http.Client();

  static Future<void> sendOtp(String email) async {
    await _post('/auth/send-otp', {'email': email.trim()});
  }

  static Future<AuthSession> register({
    required String email,
    required String fullName,
    required String password,
    required String otp,
    required Role role,
  }) async {
    final json = await _post('/auth/register', {
      'email': email.trim(),
      'fullName': fullName.trim(),
      'password': password,
      'otp': otp,
      'role': role.wire,
    });
    return AuthSession.fromJson(json);
  }

  static Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _post('/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  static Future<AuthSession> loginWithGoogle({
    required String idToken,
    Role role = Role.citizen,
  }) async {
    final json = await _post('/auth/google', {
      'idToken': idToken,
      'role': role.wire,
    });
    return AuthSession.fromJson(json);
  }

  static Future<AppUser> me() async {
    final json = await _get('/auth/me');
    return AppUser.fromJson(json);
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final headers = await _headers();
    return _send(() => _client.get(ApiConfig.uri(path), headers: headers));
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final headers = await _headers();
    return _send(
      () => _client.post(
        ApiConfig.uri(path),
        headers: headers,
        body: jsonEncode(body),
      ),
    );
  }

  static Future<Map<String, String>> _headers() async {
    final token = await UserService.getToken();
    return ApiConfig.headers(token: token);
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException.network(
        'The server took too long to respond. Please try again.',
      );
    } on SocketException {
      throw const ApiException.network(
        "Can't reach the server. Check your connection and try again.",
      );
    } on http.ClientException {
      throw const ApiException.network(
        "Can't reach the server. Check your connection and try again.",
      );
    }

    final decoded = _decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(
      _messageFor(response.statusCode, decoded),
      statusCode: response.statusCode,
    );
  }

  static Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return const {};
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : {'value': value};
    } on FormatException {
      return const {};
    }
  }

  static String _messageFor(int status, Map<String, dynamic> body) {
    final error = body['error'];
    if (error is String && error.trim().isNotEmpty) return error.trim();

    return switch (status) {
      400 => 'That request looked invalid. Please check your details.',
      401 => 'Your session has expired. Please sign in again.',
      403 => "You don't have access to that.",
      404 => 'We could not find what you were looking for.',
      409 => 'That account already exists.',
      502 => 'A downstream service is unavailable. Please try again.',
      _ => 'Something went wrong on our side ($status). Please try again.',
    };
  }
}
