import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';

class CartItem {
  final Product product;
  final String? selectedSize;
  final String? selectedColor;
  int quantity;

  CartItem({
    required this.product,
    this.selectedSize,
    this.selectedColor,
    this.quantity = 1,
  });

  double get price {
    if (selectedSize != null && selectedColor != null) {
      // Logic for variant price if exists
      try {
        final variant = product.variants.firstWhere(
          (v) => v.size == selectedSize && v.color == selectedColor
        );
        return variant.price;
      } catch (e) {
        // Fallback
      }
    }
    return product.price;
  }

  String get image {
    if (selectedSize != null && selectedColor != null) {
       try {
         final variant = product.variants.firstWhere(
           (v) => v.size == selectedSize && v.color == selectedColor
         );
         if (variant.imageUrl != null && variant.imageUrl!.isNotEmpty) {
           return variant.imageUrl!;
         }
       } catch (e) {
         // Fallback
       }
     }
    return product.imageUrl;
  }

  int get stock {
    if (selectedSize != null && selectedColor != null) {
      try {
        final variant = product.variants.firstWhere(
            (v) => v.size == selectedSize && v.color == selectedColor
        );
        return variant.stock;
      } catch (_) {}
    }
    return product.stock;
  }
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  int _getStock(Product product, String? size, String? color) {
    if (size != null && color != null) {
      try {
        final variant = product.variants.firstWhere(
            (v) => v.size == size && v.color == color
        );
        return variant.stock;
      } catch (_) {}
    }
    return product.stock;
  }

  void addToCart(Product product, String? size, String? color, int quantity) {
    if (size == null && product.sizes.isNotEmpty) return;
    if (color == null && product.colors.isNotEmpty) return;

    final availableStock = _getStock(product, size, color);

    final existingIndex = state.indexWhere((item) => 
      item.product.id == product.id && 
      item.selectedSize == size && 
      item.selectedColor == color
    );

    if (existingIndex != -1) {
      final items = [...state];
      final currentQty = items[existingIndex].quantity;
      if (currentQty + quantity > availableStock) {
        // Can't add more than stock
        return; 
      }
      items[existingIndex].quantity += quantity;
      state = items;
    } else {
      if (quantity > availableStock) return; // Can't add if initially requesting more than stock
      state = [
        ...state,
        CartItem(product: product, selectedSize: size, selectedColor: color, quantity: quantity)
      ];
    }
  }

  void removeFromCart(CartItem item) {
    state = state.where((i) => i != item).toList();
  }

  void updateQuantity(CartItem item, int change) {
    final index = state.indexOf(item);
    if (index == -1) return;

    final items = [...state];
    final currentQty = items[index].quantity;
    final newQuantity = currentQty + change;
    
    final availableStock = _getStock(item.product, item.selectedSize, item.selectedColor);

    if (newQuantity > availableStock) {
        // Did not update because stock limit reached
        return; 
    }

    if (newQuantity > 0) {
      items[index].quantity = newQuantity;
      state = items;
    } else {
      removeFromCart(item);
    }
  }

  void clearCart() {
    state = [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + (item.price * item.quantity));
  
  double get total => subtotal > 0 ? subtotal + 30000 : 0;
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
