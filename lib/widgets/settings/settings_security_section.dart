import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsSecuritySection extends StatelessWidget {
  final bool isGuest;
  final VoidCallback onChangePassword;

  const SettingsSecuritySection({
    super.key,
    required this.isGuest,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final double cardRadius = isCompact ? 16 : 18;

    final double horizontalPadding = isCompact
        ? 14
        : isLandscape
        ? 16
        : 18;

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
          // Change Password
          if (!isGuest) ...[
            ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isCompact ? 2 : 4,
              ),
              leading: _SecurityIcon(
                icon: Icons.lock_outline,
                color: Colors.orange,
                compact: isCompact,
              ),
              title: Text(
                'Change Password',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: isCompact ? 14 : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Update your account password securely.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isCompact ? 11 : null,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onChangePassword,
            ),

            const Divider(height: 1),
          ],

          // Security status
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isCompact ? 2 : 4,
            ),
            leading: _SecurityIcon(
              icon: Icons.verified_user_outlined,
              color: Colors.green,
              compact: isCompact,
            ),
            title: Text(
              'Security Status',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: isCompact ? 14 : null,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              isGuest
                  ? 'Your local data is protected on this device.'
                  : 'Your account is protected.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: isCompact ? 11 : null,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool compact;

  const _SecurityIcon({
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
