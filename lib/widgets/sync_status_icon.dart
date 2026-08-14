import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';
import '../../utils/responsive_helper.dart';

class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appBarTheme = theme.appBarTheme;
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final isCompact = compact || landscape;

    final iconColor = appBarTheme.foregroundColor ?? colorScheme.onPrimary;

    final iconSize = desktop
        ? 22.0
        : tablet
        ? 21.0
        : isCompact
        ? 18.0
        : 20.0;

    final progressSize = desktop
        ? 22.0
        : tablet
        ? 21.0
        : isCompact
        ? 18.0
        : 20.0;

    final progressStroke = isCompact ? 1.8 : 2.0;

    final badgeFontSize = isCompact ? 9.0 : 10.0;

    return Consumer<ConnectivityProvider>(
      builder: (context, network, child) {
        Widget icon;

        if (network.isSyncing) {
          icon = SizedBox(
            width: progressSize,
            height: progressSize,
            child: CircularProgressIndicator(
              strokeWidth: progressStroke,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          );
        } else if (network.pendingChanges > 0) {
          icon = Badge(
            label: Text(
              network.pendingChanges.toString(),
              style: TextStyle(
                fontSize: badgeFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Icon(
              Icons.sync_problem_rounded,
              color: Colors.orange.shade300,
              size: iconSize,
            ),
          );
        } else {
          icon = Icon(
            network.isOnline
                ? Icons.cloud_done_rounded
                : Icons.cloud_off_rounded,
            color: network.isOnline ? iconColor : Colors.orange.shade300,
            size: iconSize,
          );
        }

        return Tooltip(
          message: network.isSyncing
              ? 'Syncing...'
              : network.pendingChanges > 0
              ? '${network.pendingChanges} pending change(s)'
              : network.isOnline
              ? 'Online'
              : 'Offline',
          child: icon,
        );
      },
    );
  }
}
