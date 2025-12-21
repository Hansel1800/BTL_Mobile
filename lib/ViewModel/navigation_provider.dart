import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationState {
  final int currentIndex;
  final bool showBackInCategory;

  NavigationState({this.currentIndex = 0, this.showBackInCategory = false});

  NavigationState copyWith({int? currentIndex, bool? showBackInCategory}) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      showBackInCategory: showBackInCategory ?? this.showBackInCategory,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState> {
  @override
  NavigationState build() {
    return NavigationState();
  }

  void setIndex(int index) {
    if (state.currentIndex != index) {
        state = state.copyWith(currentIndex: index, showBackInCategory: false);
    }
  }

  void goHomeFromCategory() {
     state = state.copyWith(currentIndex: 0, showBackInCategory: false);
  }

  void goToCategoryFromHome() {
     state = state.copyWith(currentIndex: 1, showBackInCategory: true);
  }
}

final navigationProvider = NotifierProvider<NavigationNotifier, NavigationState>(NavigationNotifier.new);
