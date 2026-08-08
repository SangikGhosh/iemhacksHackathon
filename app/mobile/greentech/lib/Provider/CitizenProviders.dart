import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:greentech/Model/AppNotification.dart';
import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Model/Leaderboard.dart';
import 'package:greentech/Model/Listing.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Model/Wallet.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/ApiService.dart';

final pickupsProvider = AsyncNotifierProvider<PickupsController, List<Pickup>>(
  PickupsController.new,
);

class PickupsController extends AsyncNotifier<List<Pickup>> {
  @override
  Future<List<Pickup>> build() async {
    final page = await ApiService.pickups(size: 50);
    return page.items;
  }

  Future<void> refresh() async {
    try {
      final page = await ApiService.pickups(size: 50);
      state = AsyncData(page.items);
    } on ApiException {
      return;
    }
  }

  Future<Pickup> cancel(String id, {String? reason}) async {
    final cancelled = await ApiService.cancelPickup(id, reason: reason);
    final current = state.value ?? const <Pickup>[];
    state = AsyncData([
      for (final pickup in current)
        if (pickup.id == cancelled.id) cancelled else pickup,
    ]);
    return cancelled;
  }

  void adopt(Pickup pickup) {
    final current = state.value ?? const <Pickup>[];
    final exists = current.any((item) => item.id == pickup.id);
    state = AsyncData(
      exists
          ? [
              for (final item in current)
                if (item.id == pickup.id) pickup else item,
            ]
          : [pickup, ...current],
    );
  }
}

final walletProvider = AsyncNotifierProvider<WalletController, Wallet>(
  WalletController.new,
);

class WalletController extends AsyncNotifier<Wallet> {
  @override
  Future<Wallet> build() => ApiService.wallet();

  Future<void> refresh() async {
    state = await AsyncValue.guard(ApiService.wallet);
  }
}

final leaderboardProvider =
    AsyncNotifierProvider<LeaderboardController, Leaderboard>(
      LeaderboardController.new,
    );

class LeaderboardController extends AsyncNotifier<Leaderboard> {
  @override
  Future<Leaderboard> build() => ApiService.leaderboard(limit: 50);

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ApiService.leaderboard(limit: 50));
  }
}

final detectionHistoryProvider =
    AsyncNotifierProvider<DetectionHistoryController, DetectionHistory>(
      DetectionHistoryController.new,
    );

class DetectionHistoryController extends AsyncNotifier<DetectionHistory> {
  @override
  Future<DetectionHistory> build() => ApiService.detectionHistory(size: 50);

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ApiService.detectionHistory(size: 50));
  }
}

final myListingsProvider =
    AsyncNotifierProvider<MyListingsController, List<Listing>>(
      MyListingsController.new,
    );

class MyListingsController extends AsyncNotifier<List<Listing>> {
  @override
  Future<List<Listing>> build() async {
    final page = await ApiService.myListings(size: 50);
    return page.items;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final page = await ApiService.myListings(size: 50);
      return page.items;
    });
  }
}

const String _notificationsKey = 'greenroute.notifications';
const String _pickupStatusKey = 'greenroute.pickupStatuses';

final notificationsProvider =
    NotifierProvider<NotificationsController, List<AppNotification>>(
      NotificationsController.new,
    );

class NotificationsController extends Notifier<List<AppNotification>> {
  Timer? _timer;

  @override
  List<AppNotification> build() {
    ref.onDispose(() => _timer?.cancel());
    _restore();
    return const [];
  }

  int get unreadCount => state.where((item) => !item.read).length;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = AppNotification.decodeList(
      prefs.getString(_notificationsKey),
    );
    if (stored.isNotEmpty) state = stored;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, AppNotification.encodeList(state));
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => syncFromServer(),
    );
    syncFromServer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> syncFromServer() async {
    if (ref.read(sessionProvider).value == null) return;

    try {
      final page = await ApiService.pickups(size: 50);
      await ingest(page.items);
      for (final pickup in page.items) {
        ref.read(pickupsProvider.notifier).adopt(pickup);
      }
    } on ApiException {
      return;
    } on StateError {
      return;
    }
  }

  Future<void> ingest(List<Pickup> pickups) async {
    if (pickups.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final rawSeen = prefs.getStringList(_pickupStatusKey) ?? const [];

    final seen = <String, PickupStatus>{};
    for (final entry in rawSeen) {
      final parts = entry.split('=');
      if (parts.length == 2) {
        seen[parts[0]] = PickupStatus.fromWire(parts[1]);
      }
    }

    final firstRun = seen.isEmpty;
    final now = DateTime.now();
    final fresh = <AppNotification>[];

    for (final pickup in pickups) {
      final previous = seen[pickup.id];
      if (!firstRun) {
        final notification = AppNotification.forTransition(
          pickup: pickup,
          previous: previous,
          now: now,
        );
        if (notification != null &&
            !state.any((item) => item.id == notification.id)) {
          fresh.add(notification);
        }
      }
      seen[pickup.id] = pickup.status;
    }

    await prefs.setStringList(
      _pickupStatusKey,
      seen.entries.map((entry) => '${entry.key}=${entry.value.wire}').toList(),
    );

    if (fresh.isEmpty) return;

    final merged = [...fresh, ...state]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = merged.take(60).toList();
    await _persist();
  }

  Future<void> markAllRead() async {
    state = state.map((item) => item.copyWith(read: true)).toList();
    await _persist();
  }

  Future<void> clear() async {
    state = const [];
    await _persist();
  }
}
