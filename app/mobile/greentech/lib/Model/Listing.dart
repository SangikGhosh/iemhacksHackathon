enum ListingStatus {
  open('OPEN', 'Open'),
  sold('SOLD', 'Sold'),
  cancelled('CANCELLED', 'Withdrawn'),
  unknown('', 'Listing');

  const ListingStatus(this.wire, this.label);

  final String wire;

  final String label;

  static ListingStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == (value ?? '').toUpperCase(),
    orElse: () => ListingStatus.unknown,
  );
}

enum ListingSort {
  newest('newest', 'Newest'),
  oldest('oldest', 'Oldest'),
  priceAsc('price_asc', 'Cheapest lot'),
  priceDesc('price_desc', 'Dearest lot'),
  weightDesc('weight_desc', 'Heaviest');

  const ListingSort(this.wire, this.label);

  final String wire;

  final String label;
}

class ListingParty {
  const ListingParty({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String fullName;
  final String role;

  factory ListingParty.fromJson(Map<String, dynamic> json) => ListingParty(
    id: json['id']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
    role: json['role']?.toString() ?? '',
  );
}

class Listing {
  const Listing({
    required this.id,
    required this.status,
    required this.material,
    required this.weightKg,
    required this.price,
    required this.pricePerKg,
    required this.currency,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.seller,
    required this.buyer,
    required this.mine,
    required this.createdAt,
    required this.soldAt,
  });

  final String id;
  final ListingStatus status;
  final String material;
  final double weightKg;
  final double price;
  final double pricePerKg;
  final String currency;
  final String description;
  final String? imageUrl;
  final String location;
  final ListingParty? seller;
  final ListingParty? buyer;
  final bool mine;
  final DateTime? createdAt;
  final DateTime? soldAt;

  bool get canWithdraw => mine && status == ListingStatus.open;

  factory Listing.fromJson(Map<String, dynamic> json) {
    final seller = (json['seller'] as Map?)?.cast<String, dynamic>();
    final buyer = (json['buyer'] as Map?)?.cast<String, dynamic>();

    return Listing(
      id: json['id']?.toString() ?? '',
      status: ListingStatus.fromWire(json['status']?.toString()),
      material: json['material']?.toString() ?? 'Waste',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      pricePerKg: (json['pricePerKg'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      location: json['location']?.toString() ?? '',
      seller: seller == null ? null : ListingParty.fromJson(seller),
      buyer: buyer == null ? null : ListingParty.fromJson(buyer),
      mine: json['mine'] == true,
      createdAt: DateTime.tryParse(
        json['createdAt']?.toString() ?? '',
      )?.toLocal(),
      soldAt: DateTime.tryParse(json['soldAt']?.toString() ?? '')?.toLocal(),
    );
  }
}

class ListingPage {
  const ListingPage({
    required this.items,
    required this.totalItems,
    required this.hasMore,
  });

  final List<Listing> items;
  final int totalItems;
  final bool hasMore;

  factory ListingPage.fromJson(Map<String, dynamic> json) => ListingPage(
    items:
        (json['items'] as List?)
            ?.whereType<Map>()
            .map((item) => Listing.fromJson(item.cast<String, dynamic>()))
            .toList() ??
        const [],
    totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
    hasMore: json['hasMore'] == true,
  );
}
