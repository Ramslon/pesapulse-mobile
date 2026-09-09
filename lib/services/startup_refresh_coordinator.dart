import 'dart:async';
import 'package:flutter/foundation.dart';

class StartupRefreshCoordinator {
  StartupRefreshCoordinator._();

  static final StartupRefreshCoordinator instance =
      StartupRefreshCoordinator._();

  /// Maximum number of different API refresh operations that may
  /// run at the same time.
  ///
  /// 2 is intentional because the backend currently becomes
  /// unreliable when too many startup requests run concurrently.
  static const int _maxConcurrentRequests = 2;

  final Map<String, Future<dynamic>> _inFlight = {};

  final List<_QueuedRequest<dynamic>> _queue = [];

  int _activeRequests = 0;

  Future<T> run<T>(String key, Future<T> Function() task) {
    // ------------------------------------------------------------
    // SINGLE-FLIGHT
    // ------------------------------------------------------------
    //
    // If this resource is already being requested, do not create
    // another API request. Join the existing Future instead.
    //
    final existing = _inFlight[key];

    if (existing != null) {
      debugPrint('StartupRefreshCoordinator: JOIN existing request key=$key');

      return existing.then((value) => value as T);
    }

    // ------------------------------------------------------------
    // CREATE SHARED FUTURE
    // ------------------------------------------------------------

    final completer = Completer<T>();

    _inFlight[key] = completer.future;

    _queue.add(_QueuedRequest<T>(key: key, task: task, completer: completer));

    debugPrint(
      'StartupRefreshCoordinator: QUEUE request key=$key '
      '(active=$_activeRequests/$_maxConcurrentRequests)',
    );

    _processQueue();

    return completer.future;
  }

  void _processQueue() {
    while (_activeRequests < _maxConcurrentRequests && _queue.isNotEmpty) {
      final request = _queue.removeAt(0);

      _activeRequests++;

      debugPrint(
        'StartupRefreshCoordinator: START request key=${request.key} '
        '(active=$_activeRequests/$_maxConcurrentRequests)',
      );

      _execute(request);
    }
  }

  Future<void> _execute(_QueuedRequest<dynamic> request) async {
    try {
      final result = await request.task();

      debugPrint(
        'StartupRefreshCoordinator: COMPLETE request '
        'key=${request.key}',
      );

      if (!request.completer.isCompleted) {
        request.completer.complete(result);
      }
    } catch (e, stackTrace) {
      debugPrint(
        'StartupRefreshCoordinator: ERROR request '
        'key=${request.key}: $e',
      );

      if (!request.completer.isCompleted) {
        request.completer.completeError(e, stackTrace);
      }
    } finally {
      _inFlight.remove(request.key);

      _activeRequests--;

      debugPrint(
        'StartupRefreshCoordinator: RELEASE request '
        'key=${request.key} '
        '(active=$_activeRequests/$_maxConcurrentRequests)',
      );

      _processQueue();
    }
  }
}

class _QueuedRequest<T> {
  final String key;
  final Future<T> Function() task;
  final Completer<T> completer;

  _QueuedRequest({
    required this.key,
    required this.task,
    required this.completer,
  });
}
