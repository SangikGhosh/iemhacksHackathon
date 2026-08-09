class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'https://console.jotterly.tech';

  static const String googleServerClientId =
      '819603256526-to4me888iii7rh7tpipjac3jufqtam89.apps.googleusercontent.com';

  static const Duration timeout = Duration(seconds: 20);

  static const Duration uploadTimeout = Duration(seconds: 90);

  static const Duration chatTimeout = Duration(seconds: 60);

  static bool get isGoogleEnabled => googleServerClientId.isNotEmpty;

  static Uri uri(String path) => Uri.parse('$baseUrl$path');

  static Map<String, String> headers({String? token}) => {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
