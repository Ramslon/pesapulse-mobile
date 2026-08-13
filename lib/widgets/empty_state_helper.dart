import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';
import 'empty_state.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_goals_screen.dart';
import '../screens/login_screen.dart';
import '../screens/budget_page.dart';
import '../screens/register_screen.dart';
import '../widgets/get_started_dialog.dart';

enum EmptyStateType {
  expenses,
  goals,
  budget,
  categories,
  analyticsGuest,
  analyticsNoData,
  analyticsInProgress,
  archivedGoals,
  generic,
}

Widget buildEmptyState(
  BuildContext context,
  EmptyStateType type, {
  bool isOnline = true,
  bool isGuest = false,
  VoidCallback? refreshBudgetData,
  VoidCallback? showCreateBudgetDialog,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  // Centralized responsive values.
  final compact = ResponsiveHelper.useCompactLayout(context);
  final spacing = ResponsiveHelper.spacing(context);

  final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

  // ─────────────────────────────────────────────
  // Reusable navigation helpers
  // ─────────────────────────────────────────────

  void openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  void openAddGoal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );
  }

  void openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ─────────────────────────────────────────────
  // Reusable action button
  // ─────────────────────────────────────────────

  Widget actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: compact ? 11 : 13,
    );

    if (outlined) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(.45)),
          padding: buttonPadding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        onPressed: onPressed,
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onPressed: onPressed,
    );
  }

  // ─────────────────────────────────────────────
  // Guest actions
  // ─────────────────────────────────────────────

  Widget guestActions({required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        actionButton(
          icon: Icons.person_add_alt_1,
          label: "Register",
          color: color,
          onPressed: openRegister,
        ),
        SizedBox(height: spacing),
        actionButton(
          icon: Icons.login,
          label: "Sign In",
          color: color,
          onPressed: openLogin,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Analytics dialog
  // ─────────────────────────────────────────────

  void showAnalyticsDetails() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Analytics Details",
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return Center(child: GetStartedDialog(isGuest: false));
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Empty states
  // ─────────────────────────────────────────────

  switch (type) {
    // ─────────────────────────────────────────────
    // Expenses
    // ─────────────────────────────────────────────

    case EmptyStateType.expenses:
      final color = colorScheme.primary;

      return EmptyState(
        icon: Icons.receipt_long,
        title: "No Expenses Yet",
        message: "Add your first expense to start tracking.",
        iconColor: color,
        action: actionButton(
          icon: Icons.receipt_long,
          label: "Add Expense",
          color: color,
          onPressed: openAddExpense,
        ),
      );

    // ─────────────────────────────────────────────
    // Goals
    // ─────────────────────────────────────────────

    case EmptyStateType.goals:
      final color = colorScheme.secondary;

      return EmptyState(
        icon: Icons.flag,
        title: "No Goals Yet",
        message: "Start by setting a financial goal.",
        iconColor: color,
        action: actionButton(
          icon: Icons.flag,
          label: "Add Goal",
          color: color,
          onPressed: openAddGoal,
        ),
      );

    // ─────────────────────────────────────────────
    // Budget
    // ─────────────────────────────────────────────

    case EmptyStateType.budget:
      final color = colorScheme.primary;
      const icon = Icons.account_balance_wallet_outlined;

      if (isGuest) {
        return EmptyState(
          icon: icon,
          title: "Guest Mode",
          message: "Register or sign in to create and manage budgets.",
          iconColor: color,
          action: guestActions(color: color),
        );
      }

      return EmptyState(
        icon: icon,
        title: isOnline ? "No Budget Yet" : "No Cached Budget",
        message: isOnline
            ? "Create your monthly budget to start tracking spending."
            : "You're offline and no budget has been cached yet.\n"
                  "Connect to the internet once to download or create your budget.",
        iconColor: color,
        action: isOnline
            ? actionButton(
                icon: Icons.account_balance_wallet,
                label: "Create Budget",
                color: color,
                onPressed:
                    showCreateBudgetDialog ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetPage()),
                      );
                    },
              )
            : actionButton(
                icon: Icons.refresh,
                label: "Retry",
                color: color,
                onPressed:
                    refreshBudgetData ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("You're offline. Please connect."),
                        ),
                      );
                    },
              ),
      );

    // ─────────────────────────────────────────────
    // Categories
    // ─────────────────────────────────────────────

    case EmptyStateType.categories:
      final color = colorScheme.secondary;

      return EmptyState(
        icon: Icons.pie_chart_outline,
        title: "No Spending Data",
        message: "Add some expenses to view category analysis.",
        iconColor: color,
        action: actionButton(
          icon: Icons.receipt_long,
          label: "Add Expense",
          color: color,
          onPressed: openAddExpense,
        ),
      );

    // ─────────────────────────────────────────────
    // Analytics — Guest
    // ─────────────────────────────────────────────

    case EmptyStateType.analyticsGuest:
      final color = colorScheme.secondary;

      return EmptyState(
        icon: Icons.analytics_outlined,
        title: "Guest Mode",
        message: "Register or sign in to unlock full analytics and reports.",
        iconColor: color,
        action: guestActions(color: color),
      );

    // ─────────────────────────────────────────────
    // Analytics — No Data
    // ─────────────────────────────────────────────

    case EmptyStateType.analyticsNoData:
      final color = colorScheme.secondary;

      return EmptyState(
        icon: Icons.analytics_outlined,
        title: "No Analytics Yet",
        message:
            "Your analytics will appear once you add expenses, goals, or budgets.",
        iconColor: color,
        action: actionButton(
          icon: Icons.analytics_outlined,
          label: "Get Started",
          color: color,
          onPressed: showAnalyticsDetails,
        ),
      );

    // ─────────────────────────────────────────────
    // Analytics — In Progress
    // ─────────────────────────────────────────────

    case EmptyStateType.analyticsInProgress:
      final color = colorScheme.secondary;

      return Card(
        elevation: 0,
        color: color.withOpacity(.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
        ),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: color,
                  size: compact ? 19 : 22,
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Analytics In Progress",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    SizedBox(height: compact ? 4 : 6),
                    Text(
                      "Add more data (expenses, goals, budgets) "
                      "to unlock full analytics.",
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: showAnalyticsDetails,
                        style: TextButton.styleFrom(
                          foregroundColor: color,
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 4 : 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

    // ─────────────────────────────────────────────
    // Archived Goals
    // ─────────────────────────────────────────────

    case EmptyStateType.archivedGoals:
      final color = colorScheme.onSurfaceVariant;

      return EmptyState(
        icon: Icons.archive_outlined,
        title: "No Archived Goals",
        message:
            "Completed goals that you archive will appear here "
            "for future reference.",
        iconColor: color,
        action: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            side: BorderSide(color: colorScheme.outline.withOpacity(.5)),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: compact ? 11 : 13,
            ),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.flag_outlined),
          label: const Text(
            "Create Goal",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: openAddGoal,
        ),
      );

    // ─────────────────────────────────────────────
    // Generic
    // ─────────────────────────────────────────────

    case EmptyStateType.generic:
      final color = colorScheme.onSurfaceVariant;

      return EmptyState(
        icon: Icons.info_outline,
        title: "No Data Yet",
        message: "There’s nothing to show here right now.",
        iconColor: color,
        action: actionButton(
          icon: Icons.refresh,
          label: "Retry",
          color: color,
          outlined: true,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Refreshing...")));
          },
        ),
      );
  }
}
