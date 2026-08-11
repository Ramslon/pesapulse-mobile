import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsSupportSection extends StatelessWidget {
  final VoidCallback onContactSupport;
  final VoidCallback onRateApp;
  final VoidCallback onShareApp;

  const SettingsSupportSection({
    super.key,
    required this.onContactSupport,
    required this.onRateApp,
    required this.onShareApp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final double horizontalPadding = isCompact
        ? 14
        : isLandscape
        ? 16
        : 18;

    final double cardRadius = isCompact ? 16 : 18;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Column(
        children: [
          _SupportTile(
            icon: Icons.support_agent,
            color: Colors.blue,
            title: 'Contact Support',
            subtitle: 'Need help? Reach out to our support team.',
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onTap: onContactSupport,
          ),

          const Divider(height: 1),

          _SupportTile(
            icon: Icons.star_rate_rounded,
            color: Colors.amber,
            title: 'Rate PesaPulse',
            subtitle: 'Share your experience with us.',
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onTap: onRateApp,
          ),

          const Divider(height: 1),

          _SupportTile(
            icon: Icons.share_rounded,
            color: Colors.green,
            title: 'Share App',
            subtitle: 'Invite your friends to use PesaPulse.',
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onTap: onShareApp,
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool compact;
  final double horizontalPadding;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.horizontalPadding,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double iconContainerSize = compact ? 38 : 40;
    final double iconSize = compact ? 20 : 21;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 2 : 4,
      ),

      leading: Container(
        width: iconContainerSize,
        height: iconContainerSize,
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(compact ? 11 : 12),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),

      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: compact ? 14 : null,
          fontWeight: FontWeight.w700,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: compact ? 11 : null,
          color: colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),

      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
        size: compact ? 20 : 22,
      ),

      onTap: onTap,
    );
  }
}
