/// Model for marketplace listings
class Listing {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final List<String> photoUrls;
  final String category;
  final bool isSold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.photoUrls,
    required this.category,
    required this.isSold,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      sellerName: json['seller_name'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: json['category'] as String,
      isSold: json['is_sold'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'photo_urls': photoUrls,
      'category': category,
      'is_sold': isSold,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Listing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? title,
    String? description,
    double? price,
    List<String>? photoUrls,
    String? category,
    bool? isSold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      photoUrls: photoUrls ?? this.photoUrls,
      category: category ?? this.category,
      isSold: isSold ?? this.isSold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Categories for listings
class ListingCategory {
  static const String furniture = 'Furniture';
  static const String electronics = 'Electronics';
  static const String books = 'Books';
  static const String clothing = 'Clothing';
  static const String kitchenware = 'Kitchenware';
  static const String decor = 'Decor';
  static const String other = 'Other';

  static const List<String> all = [
    furniture,
    electronics,
    books,
    clothing,
    kitchenware,
    decor,
    other,
  ];
}
