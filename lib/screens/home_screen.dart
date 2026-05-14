import 'package:flutter/material.dart';

import '../services/api_services.dart';

import 'dashboard_screen.dart';
import 'expense_list_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List screens = [
    const DashboardScreen(),

    const ExpenseListScreen(),

    const AnalyticsScreen(),

    const ProfileScreen(),
  ];

  final List<String> titles = ['Dashboard', 'Expenses', 'Analytics', 'Profile'];

  final List<IconData> icons = [
    Icons.dashboard,

    Icons.receipt_long,

    Icons.bar_chart,

    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,

        title: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icons[currentIndex]),

            const SizedBox(width: 10),

            Text(titles[currentIndex]),
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

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.green,

        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),

            label: 'Dashboard',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),

            label: 'Expenses',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),

            label: 'Analytics',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
