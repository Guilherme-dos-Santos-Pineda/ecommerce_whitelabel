import 'package:ecommerce_whitelabel/models/cart_model.dart';
import 'package:ecommerce_whitelabel/models/favorite_model.dart';
import 'package:flutter/foundation.dart';

class CartService with ChangeNotifier {
  final List<CartItem> _cartItems = [];
  final List<FavoriteItem> _favoriteItems = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  List<FavoriteItem> get favoriteItems => List.unmodifiable(_favoriteItems);

  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + item.totalPrice);

  // Carrinho
  void addToCart(CartItem item) {
    print('🛒 Tentando adicionar ao carrinho: ${item.name}');

    final existingIndex = _cartItems.indexWhere(
      (cartItem) => cartItem.productId == item.productId,
    );

    if (existingIndex != -1) {
      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
        quantity: _cartItems[existingIndex].quantity + 1,
      );
      print(
        '✅ Produto existente, quantidade aumentada para: ${_cartItems[existingIndex].quantity}',
      );
    } else {
      _cartItems.add(item);
      print('✅ Novo produto adicionado. Total de itens: ${_cartItems.length}');
    }

    notifyListeners();
    _printCartState();
    _saveToStorage(); // ✅ Salvar após adicionar
  }

  void removeFromCart(String productId) {
    print('🛒 Removendo produto: $productId');
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
    _printCartState();
    _saveToStorage();
  }

  void updateQuantity(String productId, int quantity) {
    print('🛒 Atualizando quantidade do produto: $productId para $quantity');

    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      notifyListeners();
      _printCartState();
      _saveToStorage();
    }
  }

  void clearCart() {
    print('🛒 Limpando carrinho');
    _cartItems.clear();
    notifyListeners();
    _printCartState();
    _saveToStorage();
  }

  // Favoritos
  void toggleFavorite(FavoriteItem item) {
    final existingIndex = _favoriteItems.indexWhere(
      (fav) => fav.productId == item.productId,
    );

    if (existingIndex != -1) {
      _favoriteItems.removeAt(existingIndex);
      print('❤️ Produto removido dos favoritos: ${item.name}');
    } else {
      _favoriteItems.add(item);
      print('❤️ Produto adicionado aos favoritos: ${item.name}');
    }
    notifyListeners();
    _saveToStorage();
  }

  bool isFavorite(String productId) {
    return _favoriteItems.any((fav) => fav.productId == productId);
  }

  void removeFromFavorites(String productId) {
    _favoriteItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
    _saveToStorage();
  }

  void _printCartState() {
    print('📦 ESTADO ATUAL DO CARRINHO:');
    print('   Total de itens: $totalItems');
    print('   Total de produtos únicos: ${_cartItems.length}');
    print('   Preço total: R\$ ${totalPrice.toStringAsFixed(2)}');

    for (var item in _cartItems) {
      print(
        '   - ${item.name} (x${item.quantity}) - R\$ ${item.price.toStringAsFixed(2)} cada',
      );
    }
    print('---');
  }

  void _saveToStorage() {
    if (kDebugMode) {
      print('💾 Salvando carrinho: ${_cartItems.length} itens');
      print('💾 Salvando favoritos: ${_favoriteItems.length} itens');
    }
  }

  void loadFromStorage() {
    notifyListeners();
  }
}
