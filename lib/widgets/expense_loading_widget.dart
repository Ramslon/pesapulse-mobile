import 'package:flutter/material.dart';

class ExpenseLoadingWidget extends StatelessWidget {
  const ExpenseLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (_, __) {
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        );
      },
    );
  }
}
