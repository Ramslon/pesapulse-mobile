import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsAboutSection extends StatelessWidget {
  final VoidCallback onAbout;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTermsOfService;
  final String version;

  const SettingsAboutSection({
    super.key,
    required this.onAbout,
    required this.onPrivacyPolicy,
    required this.onTermsOfService,
    this.version = 'v1.0.0',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = isCompact
        ? 14.0
        : isLandscape
        ? 16.0
        : 18.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Column(
        children: [
          _AboutTile(
            icon: Icons.info_outline,
            color: Colors.blue,
            title: 'About PesaPulse',
            subtitle: 'Version, credits and application information.',
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onTap: onAbout,
          ),

          const Divider(height: 1),

          _AboutTile(
            icon: Icons.privacy_tip_outlined,
            color: Colors.purple,
            title: 'Privacy Policy',
            subtitle: 'Learn how your data is protected.',
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onTap: onPrivacyPolicy,
          ),

          const Divider(height: 1),

          _AboutTile(
            icon: Icons.description_outlined,
            color: Colors.teal,
            title: 'Terms of Service',
            subtitle: 'Review the terms of using PesaPulse.',
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onTap: onTermsOfService,
          ),

          const Divider(height: 1),

          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isCompact ? 2 : 4,
            ),
            leading: _AboutIcon(
              icon: Icons.verified_outlined,
              color: Colors.green,
              compact: isCompact,
            ),
            title: Text(
              'Application Version',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: isCompact ? 14 : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              'Current installed version',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isCompact ? 11 : null,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 9 : 11,
                vertical: isCompact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                version,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool compact;
  final double horizontalPadding;
  final VoidCallback onTap;

  const _AboutTile({
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

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 2 : 4,
      ),
      leading: _AboutIcon(icon: icon, color: color, compact: compact),
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
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _AboutIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool compact;

  const _AboutIcon({
    required this.icon,
    required this.color,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 40.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(compact ? 11 : 12),
      ),
      child: Icon(icon, color: color, size: compact ? 20 : 21),
    );
  }
}
