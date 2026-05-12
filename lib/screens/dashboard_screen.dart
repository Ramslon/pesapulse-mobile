import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/screens/home_screen.dart';
import 'add_expense_screen.dart';
import 'expense_list_screen.dart';
import 'login_screen.dart';
import '../services/api_services.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PesaPulse Dashboard'),
        centerTitle: true,

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),

            onPressed: () async {
              await ApiService.logoutUser();

              Navigator.pushReplacement(
                context,

                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExpenseListScreen(),
                    ),
                  );
                },
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
