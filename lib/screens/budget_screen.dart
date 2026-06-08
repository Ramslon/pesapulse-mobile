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
        ],
      ),
    );
  }
}
