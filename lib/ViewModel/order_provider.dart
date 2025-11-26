import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'order_provider.g.dart';

@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepository();
}

@riverpod
Stream<List<Order>> orders(Ref ref) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrders();
}

@riverpod
class OrderController extends _$OrderController {
  @override
  FutureOr<void> build() {
    // no-op
  }

  Future<void> addOrder(Order order) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() => ref.read(orderRepositoryProvider).addOrder(order));
      if (state.hasError) {
        throw state.error!;
      }
    } finally {
      link.close();
    }
  }

  Future<void> updateOrder(Order order) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() => ref.read(orderRepositoryProvider).updateOrder(order));
      if (state.hasError) {
        throw state.error!;
      }
    } finally {
      link.close();
    }
  }

  Future<void> deleteOrder(String orderId) async {
    final link = ref.keepAlive();
    state = const AsyncLoading();
    try {
      state = await AsyncValue.guard(() => ref.read(orderRepositoryProvider).deleteOrder(orderId));
      if (state.hasError) {
        throw state.error!;
      }
    } finally {
      link.close();
    }
  }
}
