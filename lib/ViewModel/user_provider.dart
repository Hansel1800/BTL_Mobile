import 'package:do_an_quan_ao/Model/user_model.dart';
import 'package:do_an_quan_ao/Services/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final usersProvider = StreamProvider<List<UserModel>>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUsers();
});

// Controller for user actions (like blocking/unblocking)
class UserController extends Notifier<AsyncValue<void>> {
  late final UserRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(userRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<void> toggleUserStatus(String userId, bool currentStatus) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateUserStatus(userId, !currentStatus);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final userControllerProvider = NotifierProvider<UserController, AsyncValue<void>>(UserController.new);
