import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';
import '../../utils/responsive_helper.dart';

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
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final bannerHorizontalPadding = desktop
        ? 18.0
        : tablet
        ? 16.0
        : compact
        ? 10.0
        : 12.0;

    final bannerVerticalPadding = landscape
        ? 5.0
        : desktop
        ? 10.0
        : compact
        ? 7.0
        : 8.0;

    final iconSize = desktop
        ? 22.0
        : tablet
        ? 21.0
        : landscape
        ? 16.0
        : compact
        ? 18.0
        : 20.0;

    final progressSize = desktop
        ? 22.0
        : tablet
        ? 21.0
        : landscape
        ? 16.0
        : compact
        ? 18.0
        : 20.0;

    final fontSize = desktop
        ? 14.0
        : tablet
        ? 13.0
        : landscape
        ? 11.0
        : compact
        ? 12.0
        : 14.0;

    final closeIconSize = compact
        ? 17.0
        : landscape
        ? 16.0
        : 18.0;

    final bannerRadius = compact
        ? 11.0
        : desktop
        ? 16.0
        : 14.0;

    return Consumer<ConnectivityProvider>(
      builder: (context, network, child) {
        final visible = network.isSyncing || !network.isOnline;

        _animate(visible);

        // Reset dismissal whenever visibility changes.
        if (_lastVisibleState != visible) {
          _dismissed = false;
          _lastVisibleState = visible;
        }

        if (_dismissed || !visible) {
          return const SizedBox.shrink();
        }

        final syncing = network.isSyncing;

        final background = syncing ? Colors.blue.shade700 : Colors.red.shade700;

        final icon = syncing ? Icons.sync : Icons.cloud_off_rounded;

        final text = syncing
            ? 'Syncing your latest changes...'
            : "You're offline. Changes will be saved locally.";

        return SlideTransition(
          position: _offsetAnimation,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(bannerRadius),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: bannerHorizontalPadding,
                      vertical: bannerVerticalPadding,
                    ),
                    child: Row(
                      children: [
                        if (syncing)
                          SizedBox(
                            width: progressSize,
                            height: progressSize,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        else
                          Icon(icon, color: Colors.white, size: iconSize),

                        SizedBox(
                          width: landscape
                              ? 6
                              : compact
                              ? 7
                              : spacing / 2,
                        ),

                        Expanded(
                          child: Text(
                            text,
                            maxLines: landscape || compact ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),

                        SizedBox(width: compact ? 4 : 8),

                        InkWell(
                          onTap: () {
                            _controller.reverse().then((_) {
                              if (mounted) {
                                setState(() {
                                  _dismissed = true;
                                });
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: closeIconSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
