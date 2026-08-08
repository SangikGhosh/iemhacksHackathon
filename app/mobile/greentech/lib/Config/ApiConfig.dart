class ApiConfig {
  const ApiConfig._();

  static const String baseUrl =
      'https://afdc-2409-40e0-1b8-4e8c-137c-f3d1-cfc7-976b.ngrok-free.app';

  static const String googleServerClientId =
      '819603256526-to4me888iii7rh7tpipjac3jufqtam89.apps.googleusercontent.com';

  static const Duration timeout = Duration(seconds: 20);

  static bool get isGoogleEnabled => googleServerClientId.isNotEmpty;

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  static Map<String, String> headers({String? token}) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
