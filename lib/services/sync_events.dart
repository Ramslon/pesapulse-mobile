import 'package:flutter/foundation.dart';

class SyncEvents {
  SyncEvents._();

  static final SyncEvents instance = SyncEvents._();

  final ValueNotifier<int> goalsRefresh = ValueNotifier<int>(0);

  void notifyGoalsUpdated() {
    goalsRefresh.value++;
  }
}
