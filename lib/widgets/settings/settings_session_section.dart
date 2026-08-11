import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsSessionSection extends StatelessWidget {
  final bool isGuest;
  final VoidCallback onSignOut;
  final VoidCallback onDeleteAccount;

  const SettingsSessionSection({
    super.key,
    required this.isGuest,
    required this.onSignOut,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final double padding = isCompact
        ? 14
        : isLandscape
        ? 16
        : 18;

    final double cardRadius = isCompact ? 16 : 18;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shadowColor: colorScheme.shadow.withOpacity(.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────
            // Sign out header
            // ─────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isCompact ? 40 : 42,
                  height: isCompact ? 40 : 42,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(.10),
                    borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: colorScheme.error,
                    size: isCompact ? 20 : 21,
                  ),
                ),

                SizedBox(width: isCompact ? 10 : 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign Out',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Securely sign out from your account.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isCompact ? 11 : null,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: isCompact ? 16 : 20),

            // ─────────────────────────────────────────
            // Sign out button
            // ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSignOut,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  elevation: 0,
                  minimumSize: Size.fromHeight(isCompact ? 46 : 50),
                  padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isCompact ? 13 : 16),
                  ),
                ),
                icon: Icon(Icons.logout_rounded, size: isCompact ? 19 : 21),
                label: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // ─────────────────────────────────────────
            // Delete account
            // ─────────────────────────────────────────
            if (!isGuest) ...[
              SizedBox(height: isCompact ? 14 : 18),

              Divider(height: 1, color: colorScheme.outline.withOpacity(.12)),

              SizedBox(height: isCompact ? 4 : 8),

              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 0 : 2,
                  vertical: isCompact ? 2 : 4,
                ),
                leading: Container(
                  width: isCompact ? 38 : 40,
                  height: isCompact ? 38 : 40,
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(.10),
                    borderRadius: BorderRadius.circular(isCompact ? 11 : 12),
                  ),
                  child: Icon(
                    Icons.delete_forever_outlined,
                    color: colorScheme.error,
                    size: isCompact ? 20 : 21,
                  ),
                ),
                title: Text(
                  'Delete Account',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: isCompact ? 14 : null,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: Text(
                  'Permanently delete your account and all data.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: isCompact ? 11 : null,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: isCompact ? 20 : 22,
                ),
                onTap: onDeleteAccount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
