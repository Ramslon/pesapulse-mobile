import 'package:flutter/foundation.dart';

class SyncStatus {
  SyncStatus._();

  static final SyncStatus instance = SyncStatus._();

  final ValueNotifier<int> pendingChanges = ValueNotifier<int>(0);

  void updatePending(int value) {
    pendingChanges.value = value;
  }
}
