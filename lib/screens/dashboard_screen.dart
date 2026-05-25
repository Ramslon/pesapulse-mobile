import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/loading_widget.dart';
import '../services/api_services.dart';
import '../screens/add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;

  int totalExpenses = 0;
  int totalCount = 0;
  int totalCategories = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      final data = await ApiService.getDashboardSummary();

      setState(() {
        totalExpenses =
            double.tryParse(data['total_expenses'].toString())?.toInt() ?? 0;

        totalCount = int.tryParse(data['total_count'].toString()) ?? 0;

        totalCategories = int.tryParse(data['categories'].toString()) ?? 0;

        isLoading = false;
      });
    } catch (e) {
      print(e);

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingWidget();
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Welcome Back 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Manage your expenses easily',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Expenses',
                    value: totalCount.toString(),
                    icon: Icons.account_balance_wallet,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: DashboardCard(
                    title: 'Budget',
                    value: 'KES $totalExpenses',
                    icon: Icons.savings,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: DashboardCard(
                    title: 'Categories',
                    value: totalCategories.toString(),
                    icon: Icons.category,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: DashboardCard(
                    title: 'Reports',
                    value: totalCount.toString(),
                    icon: Icons.bar_chart,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
