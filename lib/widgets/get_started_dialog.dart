import 'package:flutter/material.dart';

import '../screens/add_expense_screen.dart';
import '../screens/add_goals_screen.dart';
import '../screens/budget_page.dart';
import '../screens/register_screen.dart';
import '../screens/login_screen.dart';

class GetStartedDialog extends StatelessWidget {
  final bool isGuest;

  const GetStartedDialog({super.key, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                child: const Icon(Icons.receipt_long, color: Colors.green),
              ),
              title: const Text("Add Expense"),
              subtitle: const Text("Track your spending and daily costs"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
            ),
            const Divider(),

            // Goal option
            ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.shade100,
                child: const Icon(Icons.flag, color: Colors.orange),
              ),
              title: const Text("Add Goal"),
              subtitle: const Text("Save towards your financial goals"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddGoalScreen()),
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
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              enabled: !isGuest,
              onTap: isGuest
                  ? null
                  : () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetPage()),
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
                subtitle: const Text("Sync your data across devices"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.login, color: Colors.blue),
                ),
                title: const Text("Sign In"),
                subtitle: const Text("Already have an account?"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    );
  }
}
