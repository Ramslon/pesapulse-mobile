import 'package:flutter/material.dart';

import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../../models/goal.dart';
import '../../controllers/goals_controller.dart';
import '../../services/sync_events.dart';
import '../../utils/responsive_helper.dart';
import '../../exceptions/rate_limit_exception.dart';
import '../../utils/snackbar_helper.dart';
import 'goal_action_helpers.dart';
import 'goal_card.dart';
import 'add_savings_dialog.dart';

class GoalListItem extends StatelessWidget {
  final Goal goal;
  final GoalsController goalsController;
  final String Function(num) currency;

  const GoalListItem({
    super.key,
    required this.goal,
    required this.goalsController,
    required this.currency,
  });

  Future<void> _deleteGoal(BuildContext context) async {
    final confirmed = await GoalActionHelpers.confirmDelete(
      context,
      goalTitle: goal.title,
    );

    if (!confirmed) return;

    final connectivity = GoalActionHelpers.getConnectivity(context);

    try {
      await goalsController.deleteGoal(
        goal: goal,
        isOnline: connectivity.isOnline,
      );

      if (!context.mounted) return;

      GoalActionHelpers.showMessage(
        context,
        connectivity.isOnline
            ? 'Goal deleted successfully'
            : 'Goal deleted offline. Changes will sync automatically.',
      );
    } on RateLimitException catch (e) {
      if (!context.mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!context.mounted) return;

      debugPrint('Failed to delete goal: $e');

      GoalActionHelpers.showMessage(context, 'Failed to delete goal');
    }
  }

  Future<void> _archiveGoal(BuildContext context) async {
    final confirmed = await GoalActionHelpers.confirmArchive(
      context,
      goalTitle: goal.title,
    );

    if (!confirmed) return;

    final connectivity = GoalActionHelpers.getConnectivity(context);

    try {
      await goalsController.archiveGoal(
        goal: goal,
        isOnline: connectivity.isOnline,
      );

      SyncEvents.instance.notifyGoalsUpdated();

      if (!context.mounted) return;

      GoalActionHelpers.showMessage(
        context,
        connectivity.isOnline
            ? 'Goal archived successfully.'
            : 'Goal archived offline. It will sync automatically.',
      );
    } on RateLimitException catch (e) {
      if (!context.mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!context.mounted) return;

      GoalActionHelpers.showMessage(
        context,
        'Failed to archive goal. Please try again.',
      );
    }
  }

  Future<void> _handleSwipeDelete(BuildContext context) async {
    final connectivity = GoalActionHelpers.getConnectivity(context);

    // Optimistically remove the goal from the visible list.
    goalsController.removeGoal(goal.id);

    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final horizontalMargin = isCompact ? 12.0 : 16.0;
    final bottomMargin = isCompact ? 12.0 : 16.0;

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        horizontalMargin,
        0,
        horizontalMargin,
        bottomMargin,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
      ),
      content: Row(
        children: [
          Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: isCompact ? 20 : 22,
          ),
          SizedBox(width: isCompact ? 8 : 10),
          Expanded(
            child: Text(
              connectivity.isOnline
                  ? 'Goal deleted successfully'
                  : 'Goal deleted offline. Changes will sync automatically.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          try {
            await goalsController.restoreGoal(
              goal: goal,
              isOnline: connectivity.isOnline,
            );

            if (!context.mounted) return;

            GoalActionHelpers.showMessage(context, 'Goal restored');
          } catch (e) {
            if (!context.mounted) return;

            GoalActionHelpers.showMessage(
              context,
              'Failed to restore goal: $e',
            );
          }
        },
      ),
    );

    final reason = await ScaffoldMessenger.of(
      context,
    ).showSnackBar(snackBar).closed;

    if (reason == SnackBarClosedReason.action) {
      return;
    }

    try {
      await goalsController.deleteGoal(
        goal: goal,
        isOnline: connectivity.isOnline,
      );
    } catch (e) {
      if (!context.mounted) return;

      GoalActionHelpers.showMessage(context, 'Failed to delete goal: $e');

      await goalsController.restoreGoal(
        goal: goal,
        isOnline: connectivity.isOnline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final cardRadius = isCompact ? 18.0 : 22.0;
    final swipeHorizontalPadding = isCompact
        ? 16.0
        : isLandscape
        ? 20.0
        : 22.0;

    final swipeIconSize = isCompact ? 44.0 : 48.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 1 : 2),
      child: Dismissible(
        key: ValueKey(goal.id),
        direction: DismissDirection.endToStart,

        // ─────────────────────────────────────────────
        // Swipe delete background
        // ─────────────────────────────────────────────
        background: Container(
          margin: EdgeInsets.only(bottom: isCompact ? 18 : 24),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: swipeHorizontalPadding),
          decoration: BoxDecoration(
            color: colorScheme.error.withOpacity(.10),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(color: colorScheme.error.withOpacity(.18)),
          ),
          child: Container(
            width: swipeIconSize,
            height: swipeIconSize,
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline,
              color: colorScheme.error,
              size: isCompact ? 22 : 24,
            ),
          ),
        ),

        confirmDismiss: (_) {
          return GoalActionHelpers.confirmDelete(
            context,
            goalTitle: goal.title,
          );
        },

        onDismissed: (_) => _handleSwipeDelete(context),

        // ─────────────────────────────────────────────
        // Goal content
        // ─────────────────────────────────────────────
        child: GoalCard(
          goal: goal,
          target: goal.targetAmount,
          saved: goal.savedAmount,
          percentage: goal.percentage,
          currency: CurrencyFormatter.format,

          insight: goalsController.insights[goal.id] as Map<String, dynamic>?,

          forecast: goalsController.forecasts[goal.id] as Map<String, dynamic>?,

          onDelete: () => _deleteGoal(context),

          onAddSavings: () {
            showDialog(
              context: context,
              builder: (_) => AddSavingsDialog(
                goalId: goal.id,
                goalsController: goalsController,
              ),
            );
          },

          onArchive: () => _archiveGoal(context),
        ),
      ),
    );
  }
}
