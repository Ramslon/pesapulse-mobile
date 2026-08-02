import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // start above screen
      end: Offset.zero, // slide into place
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerAnimation(bool show) {
    if (show) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ConnectivityProvider>(
      builder: (context, network, child) {
        final isVisible = network.isSyncing || !network.isOnline;
        _triggerAnimation(isVisible);

        if (!isVisible) return const SizedBox.shrink();

        final bool isSyncing = network.isSyncing;
        final bool isOnline = network.isOnline;
        final bool hasPending = network.pendingChanges > 0;

        // Theme‑aware background colors
        final Color bgColor = isSyncing
            ? colorScheme.primary
            : isOnline
            ? colorScheme.secondary
            : colorScheme.error;

        final IconData icon = isSyncing
            ? Icons.sync
            : hasPending
            ? Icons.sync_problem
            : isOnline
            ? Icons.cloud_done
            : Icons.cloud_off;

        final String message = isSyncing
            ? "Syncing your latest changes..."
            : hasPending
            ? "${network.pendingChanges} change(s) are waiting to sync."
            : isOnline
            ? "You’re online. All changes are synced."
            : "You’re offline. Changes will be saved locally.";

        return SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: colorScheme.onPrimary,
                  ), // ✅ theme‑aware icon color
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
