import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

/// Reusable loading state for PesaPulse premium features.
///
/// The widget intentionally accepts an accent color so each premium
/// feature can preserve its own established color architecture.
class PremiumLoadingState extends StatelessWidget {
  final String title;
  final String message;
  final Color accentColor;
  final IconData icon;

  const PremiumLoadingState({
    super.key,
    required this.title,
    required this.message,
    this.accentColor = const Color(0xFF6D3FD9),
    this.icon = Icons.auto_awesome_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final iconContainerSize = compact ? 64.0 : 72.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 20 : 28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 28,
            vertical: compact ? 20 : 26,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            border: Border.all(color: accentColor.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(compact ? 18 : 20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: compact ? 30 : 34,
                      height: compact ? 30 : 34,
                      child: CircularProgressIndicator(
                        strokeWidth: compact ? 3 : 3.2,
                        color: accentColor,
                      ),
                    ),
                    Icon(icon, size: compact ? 14 : 16, color: accentColor),
                  ],
                ),
              ),

              SizedBox(width: compact ? 16 : 20),

              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      message,
                      maxLines: landscape ? 1 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable full-page error state for premium features.
class PremiumErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final Color? accentColor;
  final IconData icon;
  final String retryLabel;

  const PremiumErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.accentColor,
    this.icon = Icons.cloud_off_rounded,
    this.retryLabel = 'Try Again',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = ResponsiveHelper.useCompactLayout(context);

    final errorColor = theme.colorScheme.error;
    final accent = accentColor ?? errorColor;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? 20 : 28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: EdgeInsets.all(compact ? 20 : 26),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 20 : 24),
            border: Border.all(color: errorColor.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: errorColor.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 60 : 68,
                height: compact ? 60 : 68,
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(compact ? 18 : 20),
                ),
                child: Icon(icon, size: compact ? 28 : 32, color: errorColor),
              ),

              SizedBox(height: compact ? 14 : 18),

              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),

              SizedBox(height: compact ? 18 : 22),

              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable inline error message for premium feature screens.
class PremiumInlineError extends StatelessWidget {
  final String message;
  final Color? accentColor;

  const PremiumInlineError({
    super.key,
    required this.message,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = ResponsiveHelper.useCompactLayout(context);

    final errorColor = theme.colorScheme.error;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: errorColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 30 : 32,
            height: compact ? 30 : 32,
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: errorColor,
              size: compact ? 17 : 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: errorColor,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centralized snackbar helper for premium feature errors.
class PremiumStateWidgets {
  PremiumStateWidgets._();

  static void showError(BuildContext context, String message) {
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.onError,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }
}
