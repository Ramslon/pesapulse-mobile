import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, network, child) {
        Widget icon;

        if (network.isSyncing) {
          icon = const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (network.pendingChanges > 0) {
          icon = Badge(
            label: Text(
              "${network.pendingChanges}",
              style: const TextStyle(fontSize: 10),
            ),
            child: const Icon(Icons.sync_problem, color: Colors.orange),
          );
        } else {
          icon = Icon(
            network.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: network.isOnline ? Colors.green : Colors.orange,
          );
        }

        return Tooltip(
          message: network.isSyncing
              ? "Syncing..."
              : network.pendingChanges > 0
              ? "${network.pendingChanges} pending change(s)"
              : network.isOnline
              ? "Online"
              : "Offline",
          child: icon,
        );
      },
    );
  }
}
