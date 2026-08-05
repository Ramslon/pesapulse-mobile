import 'package:flutter/material.dart';

class DeleteBudgetDialog extends StatelessWidget {
  const DeleteBudgetDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      title: const Text("Delete Budget?"),

      content: const Text(
        "Deleting your monthly budget will remove your spending target for this month.\n\n"
        "This action cannot be undone.",
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.delete_outline),
          label: const Text("Delete"),
        ),
      ],
    );
  }
}
