import 'dart:convert';

import 'package:greentech/Model/Pickup.dart';

enum NotificationKind {
  pickupAccepted('PICKUP_ACCEPTED'),
  pickupCompleted('PICKUP_COMPLETED'),
  pickupCancelled('PICKUP_CANCELLED'),
  pickupRequested('PICKUP_REQUESTED'),
  pickupReleased('PICKUP_RELEASED');

  const NotificationKind(this.wire);

  final String wire;

  static NotificationKind fromWire(String? value) => values.firstWhere(
    (kind) => kind.wire == value,
    orElse: () => NotificationKind.pickupRequested,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.pickupId,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String pickupId;
  final DateTime createdAt;
  final bool read;

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    pickupId: pickupId,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.wire,
    'title': title,
    'body': body,
    'pickupId': pickupId,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        kind: NotificationKind.fromWire(json['kind']?.toString()),
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        pickupId: json['pickupId']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        read: json['read'] == true,
      );

  static String encodeList(List<AppNotification> items) =>
      jsonEncode(items.map((item) => item.toJson()).toList());

  static List<AppNotification> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => AppNotification.fromJson(item.cast<String, dynamic>()))
          .toList();
    } on FormatException {
      return const [];
    }
  }

  static AppNotification? forTransition({
    required Pickup pickup,
    required PickupStatus? previous,
    required DateTime now,
  }) {
    if (previous == pickup.status) return null;

    final id = '${pickup.id}:${pickup.status.wire}';
    final collector = pickup.collector?.fullName;

    return switch (pickup.status) {
      PickupStatus.accepted => AppNotification(
        id: id,
        kind: NotificationKind.pickupAccepted,
        title: 'A collector is on the way',
        body: collector == null
            ? 'Your ${pickup.mode.label.toLowerCase()} pickup was accepted. It can no longer be cancelled.'
            : '$collector accepted your ${pickup.mode.label.toLowerCase()} pickup. It can no longer be cancelled.',
        pickupId: pickup.id,
        createdAt: pickup.acceptedAt ?? now,
        read: false,
      ),
      PickupStatus.completed => AppNotification(
        id: id,
        kind: NotificationKind.pickupCompleted,
        title: 'Pickup completed',
        body:
            'You earned ${pickup.rewardPoints} points'
            '${pickup.money.finalAmount == null ? '' : ' and ₹${pickup.money.finalAmount!.toStringAsFixed(2)}'}'
            ' for ${pickup.materials.isEmpty ? 'your waste' : pickup.materials}.',
        pickupId: pickup.id,
        createdAt: pickup.completedAt ?? now,
        read: false,
      ),
      PickupStatus.cancelled => AppNotification(
        id: id,
        kind: NotificationKind.pickupCancelled,
        title: 'Pickup cancelled',
        body: pickup.cancelReason == null || pickup.cancelReason!.isEmpty
            ? 'Your pickup was cancelled.'
            : 'Cancelled: ${pickup.cancelReason}',
        pickupId: pickup.id,
        createdAt: pickup.cancelledAt ?? now,
        read: false,
      ),
      PickupStatus.requested =>
        previous == PickupStatus.accepted
            ? AppNotification(
                id: '${pickup.id}:RELEASED',
                kind: NotificationKind.pickupReleased,
                title: 'Back in the queue',
                body:
                    'The collector could not make it. Your pickup is waiting for someone else.',
                pickupId: pickup.id,
                createdAt: now,
                read: false,
              )
            : null,
      _ => null,
    };
  }
}
