import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:greentech/Model/AppUser.dart';

class UserService {
  const UserService._();

  static const _tokenKey = 'auth.accessToken';
  static const _expiryKey = 'auth.expiresAt';
  static const _userKey = 'auth.user';

  static String? _token;
  static bool _tokenLoaded = false;

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static Future<void> saveSession(AuthSession session) async {
    final prefs = await _prefs;
    final expiresAt = DateTime.now().add(Duration(seconds: session.expiresIn));

    await prefs.setString(_tokenKey, session.accessToken);
    await prefs.setString(_expiryKey, expiresAt.toIso8601String());
    await prefs.setString(_userKey, jsonEncode(session.user.toJson()));

    _token = session.accessToken;
    _tokenLoaded = true;
  }

  static Future<void> saveUserDetails(AppUser user) async {
    final prefs = await _prefs;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<String?> getToken() async {
    if (_tokenLoaded) return _token;

    final prefs = await _prefs;
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      _token = null;
      _tokenLoaded = true;
      return null;
    }

    final rawExpiry = prefs.getString(_expiryKey);
    final expiresAt = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      await clear();
      return null;
    }

    _token = token;
    _tokenLoaded = true;
    return token;
  }

  static Future<AppUser?> getUserDetails() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return AppUser.fromJson(decoded);
      return null;
    } on FormatException {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiryKey);
    await prefs.remove(_userKey);

    _token = null;
    _tokenLoaded = true;
  }
}
