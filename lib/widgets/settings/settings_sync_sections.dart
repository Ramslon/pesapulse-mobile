import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connectivity_provider.dart';
import '../../services/sync_service.dart';
import '../../utils/responsive_helper.dart';

class SettingsSyncSection extends StatelessWidget {
  final bool isGuest;
  final DateTime? lastSyncTime;
  final String Function(DateTime?) formatLastSync;

  const SettingsSyncSection({
    super.key,
    required this.isGuest,
    required this.lastSyncTime,
    required this.formatLastSync,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = isCompact
        ? 14.0
        : isLandscape
        ? 16.0
        : 18.0;

    if (isGuest) {
      return _GuestSyncCard(
        compact: isCompact,
        horizontalPadding: horizontalPadding,
      );
    }

    return Consumer<ConnectivityProvider>(
      builder: (context, network, child) {
        return _AuthenticatedSyncCard(
          network: network,
          lastSyncTime: lastSyncTime,
          formatLastSync: formatLastSync,
          compact: isCompact,
          horizontalPadding: horizontalPadding,
        );
      },
    );
  }
}

class _GuestSyncCard extends StatelessWidget {
  final bool compact;
  final double horizontalPadding;

  const _GuestSyncCard({
    required this.compact,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        side: BorderSide(color: Colors.orange.withOpacity(.14)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SyncIcon(
              icon: Icons.cloud_off_outlined,
              color: Colors.orange,
              compact: compact,
            ),

            SizedBox(width: compact ? 10 : 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cloud Sync Unavailable',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: compact ? 14 : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "You're using PesaPulse as a guest. "
                    'Create an account to enable cloud sync, '
                    'automatic backups, and access your data across devices.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 11 : null,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedSyncCard extends StatelessWidget {
  final ConnectivityProvider network;
  final DateTime? lastSyncTime;
  final String Function(DateTime?) formatLastSync;
  final bool compact;
  final double horizontalPadding;

  const _AuthenticatedSyncCard({
    required this.network,
    required this.lastSyncTime,
    required this.formatLastSync,
    required this.compact,
    required this.horizontalPadding,
  });

  Future<void> _syncNow(BuildContext context) async {
    try {
      await SyncService.instance.syncPendingOperations();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final onlineColor = network.isOnline ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Column(
        children: [
          // Connection status
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 2 : 4,
            ),
            leading: _SyncIcon(
              icon: network.isOnline
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: onlineColor,
              compact: compact,
            ),
            title: Text(
              network.isOnline ? 'Online' : 'Offline',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: compact ? 14 : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              network.isOnline
                  ? 'Your data is syncing normally.'
                  : 'Changes will sync automatically when you are online.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 11 : null,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),

          const Divider(height: 1),

          // Pending changes
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 2 : 4,
            ),
            leading: _SyncIcon(
              icon: Icons.sync_problem_outlined,
              color: Colors.blue,
              compact: compact,
            ),
            title: Text(
              'Pending Changes',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: compact ? 14 : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${network.pendingChanges} item(s) waiting to sync',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 11 : null,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const Divider(height: 1),

          // Last sync
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 2 : 4,
            ),
            leading: _SyncIcon(
              icon: Icons.schedule_outlined,
              color: Colors.purple,
              compact: compact,
            ),
            title: Text(
              'Last Sync',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: compact ? 14 : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              formatLastSync(lastSyncTime),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 11 : null,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const Divider(height: 1),

          // Sync button
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: network.isSyncing
                    ? SizedBox(
                        width: compact ? 18 : 20,
                        height: compact ? 18 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.sync_rounded, size: compact ? 19 : 21),
                label: Text(
                  network.isSyncing ? 'Syncing...' : 'Sync Now',
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: network.isOnline && !network.isSyncing
                    ? () => _syncNow(context)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool compact;

  const _SyncIcon({
    required this.icon,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 42.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
      ),
      child: Icon(icon, color: color, size: compact ? 20 : 21),
    );
  }
}
