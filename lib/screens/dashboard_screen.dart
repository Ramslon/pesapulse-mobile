import 'package:flutter/material.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PesaPulse Dashboard'),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to PesaPulse',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              'Manage your expenses efficiently.',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: () {},
                child: const Text('View Expenses'),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
                child: const Text('Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
