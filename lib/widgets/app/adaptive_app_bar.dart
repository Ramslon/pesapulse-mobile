import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool centerTitle;

  const AdaptiveAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final toolbarHeight = _toolbarHeight(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    return AppBar(
      toolbarHeight: toolbarHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,

      titleSpacing: compact
          ? 12
          : tablet
          ? 16
          : 16,

      title:
          titleWidget ??
          (title == null ? null : ResponsiveAppBarTitle(title: title!)),

      actions: actions == null
          ? null
          : _buildActions(context, actions!, compact: compact),
    );
  }

  double _toolbarHeight({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return landscape ? 56 : 64;
    }

    if (tablet) {
      return landscape ? 48 : 60;
    }

    if (compact) {
      return landscape ? 44 : 56;
    }

    return landscape ? 48 : kToolbarHeight;
  }

  List<Widget> _buildActions(
    BuildContext context,
    List<Widget> actions, {
    required bool compact,
  }) {
    return actions.map((action) {
      return Padding(
        padding: EdgeInsets.only(right: compact ? 6 : 8),
        child: action,
      );
    }).toList();
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(kToolbarHeight);
  }
}

/// Responsive title used by [AdaptiveAppBar].
///
/// Handles both simple text titles and titles containing
/// an icon + text combination.
class ResponsiveAppBarTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;

  const ResponsiveAppBarTitle({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final fontSize = _fontSize(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final iconSize = _iconSize(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final iconSpacing = compact
        ? 6.0
        : landscape
        ? 7.0
        : 8.0;

    final text = Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
    );

    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        SizedBox(width: iconSpacing),
        Flexible(child: text),
      ],
    );
  }

  double _fontSize({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 20;
    }

    if (tablet) {
      return 19;
    }

    if (compact) {
      return landscape ? 14 : 17;
    }

    return landscape ? 16 : 18;
  }

  double _iconSize({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 23;
    }

    if (tablet) {
      return 22;
    }

    if (compact) {
      return landscape ? 18 : 21;
    }

    return landscape ? 20 : 22;
  }
}
