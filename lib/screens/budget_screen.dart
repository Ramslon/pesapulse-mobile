import 'package:flutter/material.dart';
import '../services/api_services.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool isLoading = true;

  double budget = 0;
  double spent = 0;
  double remaining = 0;

  double get percentageUsed {
    if (budget <= 0) return 0;

    return (spent / budget) * 100;
  }

  @override
  void initState() {
    super.initState();
    loadBudget();
  }

  Future<void> loadBudget() async {
    try {
      final data = await ApiService.getBudgetSummary();

      setState(() {
        budget = double.tryParse(data['budget'].toString()) ?? 0;

        spent = double.tryParse(data['spent'].toString()) ?? 0;

        remaining = double.tryParse(data['remaining'].toString()) ?? 0;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Monthly Budget',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 30),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),

                    title: const Text('Budget'),

                    trailing: Text('KES ${budget.toStringAsFixed(0)}'),
                  ),

                  ListTile(
                    leading: const Icon(Icons.money_off),

                    title: const Text('Spent'),

                    trailing: Text('KES ${spent.toStringAsFixed(0)}'),
                  ),

                  ListTile(
                    leading: const Icon(Icons.savings),

                    title: const Text('Remaining'),

                    trailing: Text('KES ${remaining.toStringAsFixed(0)}'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          Text(
            '${budget > 0 ? ((spent / budget) * 100).toStringAsFixed(0) : 0}% Used',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: budget > 0 ? spent / budget : 0,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),

          if (percentageUsed >= 80)
            Container(
              margin: const EdgeInsets.only(top: 20),

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),

              child: const Row(
                children: [
                  Icon(Icons.warning),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'You have used over 80% of your monthly budget.',
                    ),
                  ),
                ],
              ),
            ),

          if (spent > budget && budget > 0)
            Container(
              margin: const EdgeInsets.only(top: 20),

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),

              child: const Row(
                children: [
                  Icon(Icons.error),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text('Budget exceeded! Consider reducing expenses.'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
