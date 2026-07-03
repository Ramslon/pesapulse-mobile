import 'package:flutter/material.dart';

import 'expense_list_content.dart';

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: ExpenseListContent()));
  }
}
