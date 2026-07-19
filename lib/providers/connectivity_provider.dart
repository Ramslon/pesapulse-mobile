import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../services/sync_status.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingChanges = 0;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  int get pendingChanges => _pendingChanges;

  ConnectivityProvider() {
    _initialize();
    SyncStatus.instance.pendingChanges.addListener(() {
      _pendingChanges = SyncStatus.instance.pendingChanges.value;
      notifyListeners();
    });
  }

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

  void setSyncing(bool value) {
    _isSyncing = value;
    notifyListeners();
  }

  void setPendingChanges(int value) {
    _pendingChanges = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
