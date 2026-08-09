import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:greentech/Config/ApiConfig.dart';
import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Model/CollectionPoint.dart';
import 'package:greentech/Model/CollectorRoute.dart';
import 'package:greentech/Model/Chat.dart';
import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Model/Leaderboard.dart';
import 'package:greentech/Model/Listing.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Model/Wallet.dart';
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

  static Future<Detection> scanWaste(File image) async {
    final token = await UserService.getToken();
    final path = image.path;

    final request = http.MultipartRequest(
      'POST',
      ApiConfig.uri('/api/v1/detections'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        path,
        filename: image.uri.pathSegments.last,
        contentType: _imageMediaType(path),
      ),
    );

    final json = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
      timeout: ApiConfig.uploadTimeout,
    );

    return Detection.fromJson(json);
  }

  static Future<List<CollectionPoint>> collectionPoints() async {
    final json = await _get('/api/v1/collection-points');
    return _pointsFrom(json);
  }

  static Future<List<CollectionPoint>> nearestCollectionPoints({
    required double lat,
    required double lon,
    int limit = 5,
  }) async {
    try {
      final json = await _get(
        '/api/v1/collection-points/nearest?lat=$lat&lon=$lon&limit=$limit',
      );
      return _pointsFrom(json);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return const [];
      rethrow;
    }
  }

  static Future<List<Municipality>> municipalities() async {
    final json = await _get('/api/v1/collection-points/municipalities');
    return (json['municipalities'] as List?)
            ?.whereType<Map>()
            .map((item) => Municipality.fromJson(item.cast<String, dynamic>()))
            .toList() ??
        const [];
  }

  static Future<CollectorRoute?> myRoute({String? municipalityCode}) async {
    final query = municipalityCode == null || municipalityCode.isEmpty
        ? ''
        : '?municipalityCode=$municipalityCode';
    try {
      final json = await _get('/api/v1/routes/my-route$query');
      return CollectorRoute.fromJson(json);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<DetectionHistory> detectionHistory({
    int page = 0,
    int size = 20,
  }) async {
    final json = await _get('/api/v1/detections?page=$page&size=$size');
    return DetectionHistory.fromJson(json);
  }

  static Future<Pickup> requestPickup({
    required String detectionId,
    required PickupMode mode,
    String? collectionPointId,
    String? address,
    String? landmark,
    String? contactPhone,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final json = await _post('/api/v1/pickups', {
      'detectionId': detectionId,
      'mode': mode.wire,
      if (collectionPointId != null) 'collectionPointId': collectionPointId,
      if (address != null && address.isNotEmpty) 'address': address,
      if (landmark != null && landmark.isNotEmpty) 'landmark': landmark,
      if (contactPhone != null && contactPhone.isNotEmpty)
        'contactPhone': contactPhone,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return Pickup.fromJson(json);
  }

  static Future<PickupPage> pickups({int page = 0, int size = 20}) async {
    final json = await _get('/api/v1/pickups?page=$page&size=$size');
    return PickupPage.fromJson(json);
  }

  static Future<Pickup> pickup(String id) async {
    final json = await _get('/api/v1/pickups/$id');
    return Pickup.fromJson(json);
  }

  static Future<Pickup> cancelPickup(String id, {String? reason}) async {
    final json = await _post('/api/v1/pickups/$id/cancel', {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return Pickup.fromJson(json);
  }

  static Future<PickupPage> availablePickups({int page = 0, int size = 50}) async {
    final json = await _get('/api/v1/pickups/available?page=$page&size=$size');
    return PickupPage.fromJson(json);
  }

  static Future<Pickup> acceptPickup(String id) async {
    final json = await _post('/api/v1/pickups/$id/accept', const {});
    return Pickup.fromJson(json);
  }

  static Future<Pickup> completePickup(
    String id, {
    required double finalWeightKg,
    required double finalAmount,
    String? collectorNotes,
  }) async {
    final json = await _post('/api/v1/pickups/$id/complete', {
      'finalWeightKg': finalWeightKg,
      'finalAmount': finalAmount,
      if (collectorNotes != null && collectorNotes.isNotEmpty)
        'collectorNotes': collectorNotes,
    });
    return Pickup.fromJson(json);
  }

  static Future<Pickup> releasePickup(String id, {String? reason}) async {
    final json = await _post('/api/v1/pickups/$id/release', {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return Pickup.fromJson(json);
  }

  static Future<Wallet> wallet({int page = 0, int size = 30}) async {
    final json = await _get('/api/v1/wallet?page=$page&size=$size');
    return Wallet.fromJson(json);
  }

  static Future<Leaderboard> leaderboard({int limit = 20}) async {
    final json = await _get('/api/v1/leaderboard?limit=$limit');
    return Leaderboard.fromJson(json);
  }

  static Future<ListingPage> myListings({int page = 0, int size = 20}) async {
    final json = await _get('/api/v1/listings/mine?page=$page&size=$size');
    return ListingPage.fromJson(json);
  }

  static Future<ListingPage> openListings({
    int page = 0,
    int size = 20,
    String? material,
    ListingSort sort = ListingSort.newest,
  }) async {
    final trimmed = material?.trim() ?? '';
    final json = await _get(
      '/api/v1/listings?page=$page&size=$size&sort=${sort.wire}'
      '${trimmed.isEmpty ? '' : '&material=${Uri.encodeQueryComponent(trimmed)}'}',
    );
    return ListingPage.fromJson(json);
  }

  static Future<Listing> createListing({
    required double price,
    String? detectionId,
    String? material,
    double? weightKg,
    String? description,
    String? location,
  }) async {
    final json = await _post('/api/v1/listings', {
      'price': price,
      if (detectionId != null) 'detectionId': detectionId,
      if (material != null && material.isNotEmpty) 'material': material,
      if (weightKg != null) 'weightKg': weightKg,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
    });
    return Listing.fromJson(json);
  }

  static Future<Listing> buyListing(String id) async {
    final json = await _post('/api/v1/listings/$id/interested', const {});
    return Listing.fromJson(json);
  }

  static Future<Listing> listing(String id) async {
    final json = await _get('/api/v1/listings/$id');
    return Listing.fromJson(json);
  }

  static Future<Listing> cancelListing(String id) async {
    final json = await _post('/api/v1/listings/$id/cancel', const {});
    return Listing.fromJson(json);
  }

  static Future<ChatCapabilities> chatCapabilities() async {
    try {
      final json = await _get('/api/v1/chat/capabilities');
      return ChatCapabilities.fromJson(json);
    } on ApiException catch (error) {
      if (error.statusCode == 503) return ChatCapabilities.disabled;
      rethrow;
    }
  }

  static Future<ChatReply> sendChat({
    required String message,
    String? conversationId,
    double? latitude,
    double? longitude,
    String? pickupId,
    String? listingId,
  }) async {
    final json = await _post('/api/v1/chat', {
      'message': message,
      if (conversationId != null) 'conversationId': conversationId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (pickupId != null) 'pickupId': pickupId,
      if (listingId != null) 'listingId': listingId,
    }, timeout: ApiConfig.chatTimeout);
    return ChatReply.fromJson(json);
  }

  static Future<List<ChatConversation>> chatConversations({
    int limit = 20,
  }) async {
    final json = await _get('/api/v1/chat/conversations?limit=$limit');
    final items = json['conversations'] ?? json['items'] ?? json['value'];
    return (items as List?)
            ?.whereType<Map>()
            .map(
              (item) => ChatConversation.fromJson(item.cast<String, dynamic>()),
            )
            .toList() ??
        const [];
  }

  static Future<List<ChatMessage>> chatTranscript(String id) async {
    final json = await _get('/api/v1/chat/conversations/$id');
    final items = json['messages'] ?? json['items'] ?? json['value'];
    return (items as List?)
            ?.whereType<Map>()
            .map((item) => ChatMessage.fromJson(item.cast<String, dynamic>()))
            .toList() ??
        const [];
  }

  static List<CollectionPoint> _pointsFrom(Map<String, dynamic> json) =>
      (json['points'] as List?)
          ?.whereType<Map>()
          .map((item) => CollectionPoint.fromJson(item.cast<String, dynamic>()))
          .toList() ??
      const [];

  static MediaType _imageMediaType(String path) {
    final extension = path.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'bmp' => MediaType('image', 'bmp'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final headers = await _headers();
    return _send(() => _client.get(ApiConfig.uri(path), headers: headers));
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    final headers = await _headers();
    return _send(
      () => _client.post(
        ApiConfig.uri(path),
        headers: headers,
        body: jsonEncode(body),
      ),
      timeout: timeout,
    );
  }

  static Future<Map<String, String>> _headers() async {
    final token = await UserService.getToken();
    return ApiConfig.headers(token: token);
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
  }) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout ?? ApiConfig.timeout);
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
      413 => 'That photo is too large. Please use one under 10 MB.',
      502 => 'A downstream service is unavailable. Please try again.',
      503 => 'The scanning service is busy right now. Please try again.',
      _ => 'Something went wrong on our side ($status). Please try again.',
    };
  }
}
