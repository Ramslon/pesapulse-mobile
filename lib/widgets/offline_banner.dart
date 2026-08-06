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
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;

  bool _dismissed = false;
  bool? _lastVisibleState;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animate(bool show) {
    if (show) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Consumer<ConnectivityProvider>(
      builder: (context, network, child) {
        final visible = network.isSyncing || !network.isOnline;

        _animate(visible);

        // Reset dismissal whenever visibility changes
        if (_lastVisibleState != visible) {
          _dismissed = false;
          _lastVisibleState = visible;
        }

        if (_dismissed || !visible) {
          return const SizedBox.shrink();
        }

        if (!visible) return const SizedBox.shrink();

        final bool syncing = network.isSyncing;

        final Color background = syncing
            ? Colors.blue.shade700
            : Colors.red.shade700;

        final IconData icon = syncing ? Icons.sync : Icons.cloud_off;

        final String text = syncing
            ? "Syncing your latest changes..."
            : "You're offline. Changes will be saved locally.";

        return SlideTransition(
          position: _offsetAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 10 : 12,
                vertical: isLandscape ? 5 : 8,
              ),
              child: Row(
                children: [
                  if (syncing)
                    SizedBox(
                      width: isLandscape ? 16 : 20,
                      height: isLandscape ? 16 : 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      color: Colors.white,
                      size: isLandscape ? 16 : 20,
                    ),

                  SizedBox(width: isLandscape ? 6 : 8),

                  Expanded(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isLandscape ? 11 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      _controller.reverse().then((_) {
                        if (mounted) {
                          setState(() {
                            _dismissed = true;
                          });
                        }
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.close, color: Colors.white, size: 18),
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
