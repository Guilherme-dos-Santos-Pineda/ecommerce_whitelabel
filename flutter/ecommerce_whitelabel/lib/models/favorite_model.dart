class FavoriteItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String image;
  final String provider;
  final bool hasDiscount;
  final double? originalPrice;
  final int? discountPercentage;
  final DateTime addedAt;

  FavoriteItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.provider,
    this.hasDiscount = false,
    this.originalPrice,
    this.discountPercentage,
  }) : addedAt = DateTime.now();
}
