enum WalletEntryType {
  credit('CREDIT'),
  debit('DEBIT'),
  unknown('');

  const WalletEntryType(this.wire);

  final String wire;

  bool get isCredit => this == credit;

  static WalletEntryType fromWire(String? value) => values.firstWhere(
    (type) => type.wire == (value ?? '').toUpperCase(),
    orElse: () => WalletEntryType.unknown,
  );
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.currency,
    required this.reason,
    required this.note,
    required this.listingId,
    required this.createdAt,
  });

  final String id;
  final WalletEntryType type;
  final double amount;
  final double balanceAfter;
  final String currency;
  final String reason;
  final String note;
  final String? listingId;
  final DateTime? createdAt;

  String get title => note.isNotEmpty ? note : _reasonLabel;

  String get _reasonLabel => switch (reason) {
    'LISTING_SOLD' => 'Listing sold',
    'LISTING_PURCHASED' => 'Listing purchased',
    _ => 'Transaction',
  };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id']?.toString() ?? '',
        type: WalletEntryType.fromWire(json['type']?.toString()),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
        currency: json['currency']?.toString() ?? 'INR',
        reason: json['reason']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        listingId: json['listingId']?.toString(),
        createdAt: DateTime.tryParse(
          json['createdAt']?.toString() ?? '',
        )?.toLocal(),
      );
}

class Wallet {
  const Wallet({
    required this.balance,
    required this.currency,
    required this.totalEarned,
    required this.totalSpent,
    required this.greenPoints,
    required this.transactions,
    required this.totalItems,
    required this.hasMore,
  });

  final double balance;
  final String currency;
  final double totalEarned;
  final double totalSpent;
  final int greenPoints;
  final List<WalletTransaction> transactions;
  final int totalItems;
  final bool hasMore;

  static const Wallet empty = Wallet(
    balance: 0,
    currency: 'INR',
    totalEarned: 0,
    totalSpent: 0,
    greenPoints: 0,
    transactions: [],
    totalItems: 0,
    hasMore: false,
  );

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    currency: json['currency']?.toString() ?? 'INR',
    totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0,
    totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
    greenPoints: (json['greenPoints'] as num?)?.toInt() ?? 0,
    transactions:
        (json['transactions'] as List?)
            ?.whereType<Map>()
            .map(
              (item) =>
                  WalletTransaction.fromJson(item.cast<String, dynamic>()),
            )
            .toList() ??
        const [],
    totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
    hasMore: json['hasMore'] == true,
  );
}
