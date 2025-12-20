import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';

class FavoriteNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    return [];
  }

  void toggleFavorite(Product product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
  }

  bool isFavorite(String productId) {
    return state.any((p) => p.id == productId);
  }
}

final favoriteProvider = NotifierProvider<FavoriteNotifier, List<Product>>(FavoriteNotifier.new);
