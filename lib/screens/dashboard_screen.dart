import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/loading_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    await Future.delayed(const Duration(seconds: 2)); // simulate API

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const LoadingWidget();
    }

    return Padding(
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

                  value: '120',

                  icon: Icons.account_balance_wallet,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: DashboardCard(
                  title: 'Budget',

                  value: 'KES 50K',

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

                  value: '8',

                  icon: Icons.category,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: DashboardCard(
                  title: 'Reports',

                  value: '12',

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
                Navigator.pushNamed(context, '/add-expense');
              },

              icon: const Icon(Icons.add),

              label: const Text('Add Expense'),
            ),
          ),
        ],
      ),
    );
  }
}
