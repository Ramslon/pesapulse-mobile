import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsAccountCard extends StatelessWidget {
  final bool isGuest;
  final String userName;
  final String userEmail;
  final VoidCallback onEditProfile;
  final VoidCallback onCreateAccount;
  final VoidCallback onSignIn;

  const SettingsAccountCard({
    super.key,
    required this.isGuest,
    required this.userName,
    required this.userEmail,
    required this.onEditProfile,
    required this.onCreateAccount,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final spacing = ResponsiveHelper.spacing(context);

    // ─────────────────────────────────────────────
    // Responsive dimensions
    // ─────────────────────────────────────────────
    final double cardPadding;

    if (isCompact) {
      cardPadding = 16;
    } else if (isLandscape) {
      cardPadding = 18;
    } else {
      cardPadding = 20;
    }

    final double avatarRadius;

    if (isCompact) {
      avatarRadius = 38;
    } else if (isLandscape) {
      avatarRadius = 44;
    } else {
      avatarRadius = 50;
    }

    final double avatarIconSize;

    if (isCompact) {
      avatarIconSize = 46;
    } else if (isLandscape) {
      avatarIconSize = 54;
    } else {
      avatarIconSize = 60;
    }

    final double verticalGap = isCompact ? 10 : 15;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            // ─────────────────────────────────────────────
            // Profile avatar
            // ─────────────────────────────────────────────
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: colorScheme.primary.withOpacity(.10),
              child: Icon(
                Icons.account_circle,
                size: avatarIconSize,
                color: colorScheme.primary,
              ),
            ),

            SizedBox(height: verticalGap),

            // ─────────────────────────────────────────────
            // Welcome text
            // ─────────────────────────────────────────────
            Text(
              isGuest ? 'Guest Mode' : 'Welcome back!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 2),

            // ─────────────────────────────────────────────
            // User name
            // ─────────────────────────────────────────────
            Text(
              isGuest ? 'Guest User' : (userName.isEmpty ? 'User' : userName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: isCompact
                    ? 21
                    : isLandscape
                    ? 23
                    : null,
                fontWeight: FontWeight.bold,
                letterSpacing: .2,
              ),
            ),

            const SizedBox(height: 5),

            // ─────────────────────────────────────────────
            // Email / guest information
            // ─────────────────────────────────────────────
            Text(
              isGuest ? 'Your data is stored only on this device.' : userEmail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isCompact ? 12 : null,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),

            // ─────────────────────────────────────────────
            // Guest information banner
            // ─────────────────────────────────────────────
            if (isGuest) ...[
              SizedBox(height: spacing),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isCompact ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(.08),
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                  border: Border.all(color: Colors.orange.withOpacity(.20)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isCompact ? 32 : 34,
                      height: isCompact ? 32 : 34,
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: isCompact ? 18 : 19,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Text(
                        "You're using PesaPulse as a guest. "
                        "Create an account to enable cloud sync, "
                        "backups and multi-device access.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: isCompact ? 11.5 : null,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: isCompact ? 14 : 18),

            const Divider(height: 1),

            // ─────────────────────────────────────────────
            // Account actions
            // ─────────────────────────────────────────────
            if (!isGuest)
              _AccountActionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                color: colorScheme.primary,
                onTap: onEditProfile,
                compact: isCompact,
              )
            else
              _AccountActionTile(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Create Account',
                subtitle: 'Sync your data across devices',
                color: Colors.orange,
                onTap: onCreateAccount,
                compact: isCompact,
              ),

            const Divider(height: 1),

            _AccountActionTile(
              icon: Icons.login_outlined,
              title: 'Sign In',
              subtitle: 'Already have an account?',
              color: Colors.blue,
              onTap: onSignIn,
              compact: isCompact,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _AccountActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: compact,
      visualDensity: compact
          ? const VisualDensity(horizontal: 0, vertical: -2)
          : VisualDensity.standard,
      minLeadingWidth: 0,

      leading: Container(
        width: compact ? 36 : 40,
        height: compact ? 36 : 40,
        decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
        ),
        child: Icon(icon, color: color, size: compact ? 18 : 20),
      ),

      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: compact ? 13 : null,
          fontWeight: FontWeight.w700,
        ),
      ),

      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 11 : null,
              ),
            ),

      trailing: Icon(Icons.chevron_right, size: compact ? 19 : 21),

      onTap: onTap,
    );
  }
}
