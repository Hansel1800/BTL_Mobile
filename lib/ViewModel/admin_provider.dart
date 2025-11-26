import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setIndex(int index) {
    state = index;
  }
}

final adminIndexProvider = NotifierProvider<AdminIndexNotifier, int>(AdminIndexNotifier.new);
