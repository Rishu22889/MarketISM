import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile.dart';

enum ItemCategory { books, electronics, cycles, essentials, others, clothing, furniture, sports, other }
enum ItemCondition { new_item, likeNew, good, fair, poor }
enum ItemStatus { available, sold, removed }

class Item {
  final String id;
  final String title;
  final double price;
  final ItemCategory category;
  final ItemCondition condition;
  final String description;
  final List<String> images;
  final String sellerId;
  final SellerInfo sellerPublic;
  final DateTime createdAt;
  final ItemStatus status;
  final int views;
  final List<String> searchKeywords;

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    required this.images,
    required this.sellerId,
    required this.sellerPublic,
    required this.createdAt,
    this.status = ItemStatus.available,
    this.views = 0,
    this.searchKeywords = const [],
  });

  // Validation
  bool get isValidTitle => title.isNotEmpty && title.length <= 80;
  bool get isValidDescription => description.isNotEmpty && description.length <= 600;
  bool get isValidPrice => price > 0;
  bool get isValidImages => images.isNotEmpty && images.length <= 5;
  bool get isAvailable => status == ItemStatus.available;
  bool get isSold => status == ItemStatus.sold;

  // Helper
  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
  String get categoryDisplayName => category.name.toUpperCase();

  List<String> generateSearchKeywords() {
    final keywords = <String>{};

    keywords.addAll(title.toLowerCase().split(' '));
    keywords.add(category.name.toLowerCase());

    final descWords = description.toLowerCase().split(' ').take(10);
    keywords.addAll(descWords);

    keywords.addAll(sellerPublic.name.toLowerCase().split(' '));
    keywords.add(sellerPublic.dept.toLowerCase());

    return keywords.where((k) => k.isNotEmpty && k.length > 2).toList();
  }

  // ✅ Supabase-friendly JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'category': category.name,
      'condition': condition.name,
      'description': description,
      'images': images,
      'seller_id': sellerId,
      'seller_public': sellerPublic.toJson(),
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'views': views,
      'search_keywords': searchKeywords,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: ItemCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ItemCategory.others,
      ),
      condition: ItemCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => ItemCondition.good,
      ),
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      sellerId: json['seller_id'] ?? '',
      sellerPublic: SellerInfo.fromJson(
        (json['seller_public'] as Map<String, dynamic>?) ?? {},
      ),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ItemStatus.available,
      ),
      views: json['views'] ?? 0,
      searchKeywords: List<String>.from(json['search_keywords'] ?? []),
    );
  }

  // Copy with
  Item copyWith({
    String? id,
    String? title,
    double? price,
    ItemCategory? category,
    ItemCondition? condition,
    String? description,
    List<String>? images,
    String? sellerId,
    SellerInfo? sellerPublic,
    DateTime? createdAt,
    ItemStatus? status,
    int? views,
    List<String>? searchKeywords,
  }) {
    return Item(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      sellerPublic: sellerPublic ?? this.sellerPublic,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      views: views ?? this.views,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          id == other.id &&
          title == other.title &&
          price == other.price &&
          category == other.category &&
          condition == other.condition &&
          description == other.description &&
          images.toString() == other.images.toString() &&
          sellerId == other.sellerId &&
          sellerPublic == other.sellerPublic &&
          createdAt == other.createdAt &&
          status == other.status &&
          views == other.views;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        price,
        category,
        condition,
        description,
        images,
        sellerId,
        sellerPublic,
        createdAt,
        status,
        views,
      );

  @override
  String toString() => 'Item(id: $id, title: $title, price: $price, category: $category, status: $status)';
}

class ItemFilter {
  final ItemCategory? category;
  final double? minPrice;
  final double? maxPrice;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final ItemStatus? status;

  const ItemFilter({
    this.category,
    this.minPrice,
    this.maxPrice,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.status,
  });

  bool get hasFilters =>
      category != null ||
      minPrice != null ||
      maxPrice != null ||
      searchQuery != null ||
      startDate != null ||
      endDate != null ||
      status != null;

  ItemFilter copyWith({
    ItemCategory? category,
    double? minPrice,
    double? maxPrice,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    ItemStatus? status,
  }) {
    return ItemFilter(
      category: category ?? this.category,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
    );
  }

  ItemFilter clearFilter() => const ItemFilter();
}
