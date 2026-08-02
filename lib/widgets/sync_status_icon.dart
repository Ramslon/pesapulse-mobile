import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ConnectivityProvider>(
      builder: (context, network, child) {
        Widget icon;

        if (network.isSyncing) {
          icon = SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary, // ✅ adapts to theme
              ),
            ),
          );
        } else if (network.pendingChanges > 0) {
          icon = Badge(
            label: Text(
              "${network.pendingChanges}",
              style: const TextStyle(fontSize: 10),
            ),
            child: Icon(
              Icons.sync_problem,
              color: colorScheme.error, // ✅ theme error color
            ),
          );
        } else {
          icon = Icon(
            network.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: network.isOnline
                ? colorScheme
                      .primary // ✅ theme primary for online
                : colorScheme.tertiary, // ✅ theme tertiary for offline
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
