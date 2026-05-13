import 'package:flutter/material.dart';

import 'login_screen.dart';

import '../services/api_services.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,

        title: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(Icons.account_balance_wallet),

            const SizedBox(width: 10),

            const Text('PesaPulse'),
          ],
        ),

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
                  child: dashboardCard(
                    title: 'Expenses',

                    value: '120',

                    icon: Icons.account_balance_wallet,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: dashboardCard(
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
                  child: dashboardCard(
                    title: 'Categories',

                    value: '8',

                    icon: Icons.category,
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: dashboardCard(
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
      ),
    );
  }

  Widget dashboardCard({
    required String title,

    required String value,

    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),

            blurRadius: 10,

            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 35, color: Colors.green),

          const SizedBox(height: 20),

          Text(
            value,

            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
