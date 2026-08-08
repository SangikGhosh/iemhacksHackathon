import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const int _port = 8080;

  static String get baseUrl {
    if (_override.isNotEmpty) return _stripTrailingSlash(_override);
    if (kIsWeb) return 'http://localhost:$_port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$_port';
    return 'http://localhost:$_port';
  }

  static const Duration timeout = Duration(seconds: 20);

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool get isGoogleEnabled => googleServerClientId.isNotEmpty;

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  static Map<String, String> headers({String? token}) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  static String _stripTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}
