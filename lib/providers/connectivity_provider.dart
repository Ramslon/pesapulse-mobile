import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../services/sync_status.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _initialize();

    SyncStatus.instance.pendingChanges.addListener(_onPendingChangesChanged);

    SyncStatus.instance.isSyncing.addListener(_onSyncingChanged);

    // Get the current values immediately.
    _pendingChanges = SyncStatus.instance.pendingChanges.value;

    _isSyncing = SyncStatus.instance.isSyncing.value;
  }

  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingChanges = 0;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingChanges => _pendingChanges;

  Future<void> _initialize() async {
    final result = await _connectivity.checkConnectivity();

    _updateConnection(result);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateConnection,
    );
  }

  void _updateConnection(List<ConnectivityResult> results) {
    _isOnline = !results.contains(ConnectivityResult.none);

    notifyListeners();
  }

  void _onPendingChangesChanged() {
    _pendingChanges = SyncStatus.instance.pendingChanges.value;

    notifyListeners();
  }

  void _onSyncingChanged() {
    _isSyncing = SyncStatus.instance.isSyncing.value;

    notifyListeners();
  }

  // Keep these methods for compatibility with existing UI code.
  void setSyncing(bool value) {
    SyncStatus.instance.setSyncing(value);
  }

  void setPendingChanges(int value) {
    SyncStatus.instance.updatePending(value);
  }

  @override
  void dispose() {
    _subscription?.cancel();

    SyncStatus.instance.pendingChanges.removeListener(_onPendingChangesChanged);

    SyncStatus.instance.isSyncing.removeListener(_onSyncingChanged);

    super.dispose();
  }
}
