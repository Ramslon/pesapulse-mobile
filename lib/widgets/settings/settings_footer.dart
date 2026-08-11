import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsFooter extends StatelessWidget {
  final String appName;
  final String tagline;
  final String version;
  final int year;

  const SettingsFooter({
    super.key,
    this.appName = 'PesaPulse',
    this.tagline = 'Personal Finance Manager',
    this.version = '1.0.0',
    this.year = 2026,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final double topSpacing = isCompact
        ? 20
        : isLandscape
        ? 24
        : 30;

    final double bottomSpacing = isCompact
        ? 22
        : isLandscape
        ? 26
        : 30;

    final double logoRadius = isCompact ? 24 : 28;
    final double logoIconSize = isCompact ? 26 : 30;

    return Column(
      children: [
        SizedBox(height: topSpacing),

        Divider(color: colorScheme.outline.withOpacity(.18), height: 1),

        SizedBox(height: isCompact ? 20 : 25),

        // ─────────────────────────────────────────
        // App logo
        // ─────────────────────────────────────────
        Container(
          width: logoRadius * 2,
          height: logoRadius * 2,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: colorScheme.primary,
            size: logoIconSize,
          ),
        ),

        SizedBox(height: isCompact ? 12 : 15),

        // ─────────────────────────────────────────
        // App name
        // ─────────────────────────────────────────
        Text(
          appName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: isCompact ? 20 : null,
            fontWeight: FontWeight.w800,
            letterSpacing: -.3,
          ),
        ),

        const SizedBox(height: 5),

        // ─────────────────────────────────────────
        // Tagline
        // ─────────────────────────────────────────
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: isCompact ? 12 : null,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: isCompact ? 10 : 12),

        // ─────────────────────────────────────────
        // Version badge
        // ─────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 12,
            vertical: isCompact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary.withOpacity(.12)),
          ),
          child: Text(
            'Version $version',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        SizedBox(height: isCompact ? 14 : 16),

        // ─────────────────────────────────────────
        // Copyright
        // ─────────────────────────────────────────
        Text(
          '© $year $appName\nAll rights reserved.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: isCompact ? 10 : 12,
            color: colorScheme.onSurfaceVariant.withOpacity(.75),
            height: 1.4,
          ),
        ),

        SizedBox(height: bottomSpacing),
      ],
    );
  }
}
