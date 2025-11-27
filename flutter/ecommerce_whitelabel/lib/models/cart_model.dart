class CartItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String image;
  final String provider;
  int quantity;
  final bool hasDiscount;
  final double? originalPrice;
  final int? discountPercentage;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.image,
    required this.provider,
    this.quantity = 1,
    this.hasDiscount = false,
    this.originalPrice,
    this.discountPercentage,
  });

  double get totalPrice => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      productId: productId,
      name: name,
      price: price,
      image: image,
      provider: provider,
      quantity: quantity ?? this.quantity,
      hasDiscount: hasDiscount,
      originalPrice: originalPrice,
      discountPercentage: discountPercentage,
    );
  }
}
