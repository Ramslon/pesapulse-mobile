import 'package:flutter/material.dart';
import 'empty_state.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_goals_screen.dart';
import '../screens/login_screen.dart';
import '../screens/budget_page.dart';
import '../screens/register_screen.dart';

enum EmptyStateType {
  expenses,
  goals,
  budget,
  categories,
  analytics,
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
  Color themedColor;
  IconData themedIcon;

  switch (type) {
    case EmptyStateType.expenses:
      themedColor = Colors.green;
      themedIcon = Icons.receipt_long;
      return EmptyState(
        icon: themedIcon,
        title: "No Expenses Yet",
        message: "Add your first expense to start tracking.",
        iconColor: themedColor,
        action: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: themedColor),
          icon: Icon(themedIcon, color: Colors.white),
          label: const Text(
            "Add Expense",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            );
          },
        ),
      );

    case EmptyStateType.goals:
      themedColor = Colors.orange;
      themedIcon = Icons.flag;
      return EmptyState(
        icon: themedIcon,
        title: "No Goals Yet",
        message: "Start by setting a financial goal.",
        iconColor: themedColor,
        action: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: themedColor),
          icon: Icon(themedIcon, color: Colors.white),
          label: const Text("Add Goal", style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddGoalScreen()),
            );
          },
        ),
      );

    case EmptyStateType.budget:
      themedColor = Colors.blue;
      themedIcon = Icons.account_balance_wallet_outlined;
      if (isGuest) {
        return EmptyState(
          icon: themedIcon,
          title: "Guest Mode",
          message: "Register or sign in to create and manage budgets.",
          iconColor: themedColor,
          action: Column(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: themedColor),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  "Register",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: themedColor),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  "Sign In",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        );
      }
      return EmptyState(
        icon: themedIcon,
        title: isOnline ? "No Budget Yet" : "No Cached Budget",
        message: isOnline
            ? "Create your monthly budget to start tracking spending."
            : "You're offline and no budget has been cached yet.\nConnect to the internet once to download or create your budget.",
        iconColor: themedColor,
        action: isOnline
            ? ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: themedColor),
                icon: Icon(Icons.account_balance_wallet, color: Colors.white),
                label: const Text(
                  "Create Budget",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed:
                    showCreateBudgetDialog ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetPage()),
                      );
                    },
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: themedColor),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "Retry",
                  style: TextStyle(color: Colors.white),
                ),
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

    case EmptyStateType.categories:
      themedColor = Colors.orange;
      themedIcon = Icons.pie_chart_outline;
      return EmptyState(
        icon: themedIcon,
        title: "No Spending Data",
        message: "Add some expenses to view category analysis.",
        iconColor: themedColor,
        action: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: themedColor),
          icon: Icon(Icons.receipt_long, color: Colors.white),
          label: const Text(
            "Add Expense",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            );
          },
        ),
      );

    case EmptyStateType.analytics:
      themedColor = Colors.purple;
      themedIcon = Icons.analytics_outlined;
      if (isGuest) {
        return EmptyState(
          icon: themedIcon,
          title: "Guest Mode",
          message: "Register or sign in to unlock full analytics and reports.",
          iconColor: themedColor,
          action: Column(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: themedColor),
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  "Register",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: themedColor),
                icon: const Icon(Icons.login, color: Colors.white),
                label: const Text(
                  "Sign In",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        );
      }
      return EmptyState(
        icon: themedIcon,
        title: "No Analytics Yet",
        message:
            "Your analytics will appear once you add expenses, goals, or budgets.",
        iconColor: themedColor,
        action: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: themedColor),
          icon: Icon(themedIcon, color: Colors.white),
          label: const Text(
            "Get Started",
            style: TextStyle(color: Colors.white),
          ),
          onPressed: () {
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: "Get Started",
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (context, animation, secondaryAnimation) {
                return Center(
                  child: AlertDialog(
                    title: const Text("Get Started"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Expense option
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.green,
                              ),
                            ),
                            title: const Text("Add Expense"),
                            subtitle: const Text(
                              "Track your spending and daily costs",
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddExpenseScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),

                          // Goal option
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.orange.shade100,
                              child: const Icon(
                                Icons.flag,
                                color: Colors.orange,
                              ),
                            ),
                            title: const Text("Add Goal"),
                            subtitle: const Text(
                              "Save towards your financial goals",
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddGoalScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(),

                          // Budget option
                          ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.blue,
                              ),
                            ),
                            title: const Text("Add Budget"),
                            subtitle: Text(
                              isGuest
                                  ? "Create an account to manage budgets"
                                  : "Plan and manage your monthly budget",
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            enabled: !isGuest,
                            onTap: isGuest
                                ? null
                                : () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const BudgetPage(),
                                      ),
                                    );
                                  },
                          ),

                          // Guest account options
                          if (isGuest) ...[
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Account Options",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            const Divider(),

                            ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.orange.shade500,
                                child: const Icon(
                                  Icons.person_add_alt_1,
                                  color: Colors.white,
                                ),
                              ),
                              title: const Text("Create Account"),
                              subtitle: const Text(
                                "Sync your data across devices",
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.login,
                                  color: Colors.blue,
                                ),
                              ),
                              title: const Text("Sign In"),
                              subtitle: const Text("Already have an account?"),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 18,
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                );
              },
              transitionBuilder:
                  (context, animation, secondaryAnimation, child) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2), // slide up from bottom
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
            );
          },
        ),
      );

    case EmptyStateType.archivedGoals:
      return EmptyState(
        icon: Icons.archive_outlined,
        title: "No Archived Goals",
        message:
            "Completed goals that you archive will appear here for future reference.",
        iconColor: Colors.grey.shade300,
        action: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.grey.shade700, // darker grey for better contrast
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          icon: const Icon(Icons.flag_outlined, color: Colors.white),
          label: const Text(
            "Create Goal",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddGoalScreen()),
            );
          },
        ),
      );

    case EmptyStateType.generic:
      themedColor = Colors.grey;
      themedIcon = Icons.info_outline;
      return EmptyState(
        icon: themedIcon,
        title: "No Data Yet",
        message: "There’s nothing to show here right now.",
        iconColor: themedColor,
        action: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: themedColor),
          icon: const Icon(Icons.refresh, color: Colors.white),
          label: const Text("Retry", style: TextStyle(color: Colors.white)),
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Refreshing...")));
          },
        ),
      );
  }
}
