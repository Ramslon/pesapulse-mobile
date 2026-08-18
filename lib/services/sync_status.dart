import 'package:flutter/foundation.dart';

class SyncStatus {
  SyncStatus._();

  static final SyncStatus instance = SyncStatus._();

  final ValueNotifier<int> pendingChanges = ValueNotifier<int>(0);
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  void updatePending(int value) {
    pendingChanges.value = value;
  }

  void setSyncing(bool syncing) {
    isSyncing.value = syncing;
  }
}
