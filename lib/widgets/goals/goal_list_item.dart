import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/goal.dart';
import '../../controllers/goals_controller.dart';
import '../../services/sync_events.dart';
import 'goal_action_helpers.dart';
import 'goal_card.dart';
import 'add_savings_dialog.dart';

class GoalListItem extends StatelessWidget {
  final Goal goal;
  final GoalsController goalsController;
  final NumberFormat currency;

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

      await goalsController.loadGoals(forceRefresh: true);

      if (!context.mounted) return;

      GoalActionHelpers.showMessage(
        context,
        connectivity.isOnline
            ? 'Goal deleted successfully'
            : 'Goal deleted offline. Changes will sync automatically.',
      );
    } catch (e) {
      if (!context.mounted) return;

      GoalActionHelpers.showMessage(context, 'Failed to delete goal: $e');
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
    } catch (e) {
      if (!context.mounted) return;

      GoalActionHelpers.showMessage(context, 'Failed to delete goal: $e');
    }
  }

  Future<void> _handleSwipeDelete(BuildContext context) async {
    final connectivity = GoalActionHelpers.getConnectivity(context);

    // Optimistically remove the goal from the visible list.
    goalsController.removeGoal(goal.id);

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          const Icon(Icons.delete_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              connectivity.isOnline
                  ? 'Goal deleted successfully'
                  : 'Goal deleted offline. Changes will sync automatically.',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Dismissible(
        key: ValueKey(goal.id),
        direction: DismissDirection.endToStart,

        background: Container(
          margin: const EdgeInsets.only(bottom: 24),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: colorScheme.error.withOpacity(.10),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.error.withOpacity(.18)),
          ),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_outline,
              color: colorScheme.error,
              size: 24,
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

        child: GoalCard(
          goal: goal,
          target: goal.targetAmount,
          saved: goal.savedAmount,
          percentage: goal.percentage,
          currency: currency,

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
