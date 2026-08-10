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

      GoalActionHelpers.showMessage(context, 'Failed to archive goal: $e');
    }
  }

  Future<void> _handleSwipeDelete(BuildContext context) async {
    final connectivity = GoalActionHelpers.getConnectivity(context);

    goalsController.removeGoal(goal.id);

    final snackBar = SnackBar(
      content: Text(
        connectivity.isOnline
            ? 'Goal deleted successfully'
            : 'Goal deleted offline. Changes will sync automatically.',
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

  Future<bool> _confirmSwipeDelete(BuildContext context) {
    return GoalActionHelpers.confirmDelete(context, goalTitle: goal.title);
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,

      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red.withOpacity(0.8),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      confirmDismiss: (_) => _confirmSwipeDelete(context),

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
    );
  }
}
