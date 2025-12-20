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
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return [];
  }

  void addToCart(Product product, String? size, String? color, int quantity) {
    if (size == null && product.sizes.isNotEmpty) return;
    if (color == null && product.colors.isNotEmpty) return;

    final existingIndex = state.indexWhere((item) => 
      item.product.id == product.id && 
      item.selectedSize == size && 
      item.selectedColor == color
    );

    if (existingIndex != -1) {
      final items = [...state];
      items[existingIndex].quantity += quantity;
      state = items;
    } else {
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
    final newQuantity = items[index].quantity + change;

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
