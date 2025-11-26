import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/Services/product_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'product_provider.g.dart';

@riverpod
ProductRepository productRepository(Ref ref) {
  return ProductRepository();
}

@riverpod
Stream<List<Product>> products(Ref ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
}

@riverpod
class ProductController extends _$ProductController {
  @override
  FutureOr<void> build() {
    // no-op
  }

  Future<void> addProduct(Product product) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).addProduct(product));
      if (state.hasError) {
        throw state.error!;
      }
    } finally {
      link.close();
    }
  }

  Future<void> updateProduct(Product product) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).updateProduct(product));
      if (state.hasError) {
        throw state.error!;
      }
    } finally {
      link.close();
    }
  }

  Future<void> deleteProduct(String productId) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() => ref.read(productRepositoryProvider).deleteProduct(productId));
      if (state.hasError) {
        throw state.error!;
      }
    } finally {
      link.close();
    }
  }
}
