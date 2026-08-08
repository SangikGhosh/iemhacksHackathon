import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:greentech/Config/ApiConfig.dart';

class GoogleAuthCancelled implements Exception {
  const GoogleAuthCancelled();
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  const GoogleAuthService._();

  static Future<void>? _initialization;

  static Future<void> _ensureInitialized() async {
    final pending = _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: ApiConfig.googleServerClientId,
    );

    try {
      await pending;
    } catch (_) {
      _initialization = null;
      throw const GoogleAuthException(
        'Could not start Google sign-in. Please try again.',
      );
    }
  }

  static Future<String> signIn() async {
    if (!ApiConfig.isGoogleEnabled) {
      throw const GoogleAuthException('Google sign-in is not configured yet.');
    }

    await _ensureInitialized();

    final client = GoogleSignIn.instance;

    if (!client.supportsAuthenticate()) {
      throw const GoogleAuthException(
        'Google sign-in is not available on this device.',
      );
    }

    final GoogleSignInAccount account;
    try {
      await client.signOut();
      account = await client.authenticate();
    } on GoogleSignInException catch (error) {
      debugPrint(
        'GOOGLE_SIGN_IN_FAILED code=${error.code} '
        'description=${error.description} details=${error.details}',
      );
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleAuthCancelled();
      }
      throw GoogleAuthException(_messageFor(error));
    }

    final idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const GoogleAuthException(
        'Google did not return an ID token. Check the OAuth client setup.',
      );
    }

    return idToken;
  }

  static Future<void> signOut() async {
    if (_initialization == null) return;
    await GoogleSignIn.instance.signOut();
  }

  static String _messageFor(GoogleSignInException error) =>
      switch (error.code) {
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Google sign-in is misconfigured for this app.',
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable =>
          'Google sign-in was interrupted. Please try again.',
        _ => 'Google sign-in failed. Please try again.',
      };
}
