import 'package:flutter/material.dart';

class BudgetDialog extends StatelessWidget {
  final TextEditingController controller;
  final bool hasBudget;
  final bool isSyncing;

  final VoidCallback onSave;
  final VoidCallback onDelete;

  const BudgetDialog({
    super.key,
    required this.controller,
    required this.hasBudget,
    required this.isSyncing,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Create Monthly Budget"),

      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          prefixText: "KES ",
          labelText: "Budget Amount",
        ),
      ),

      actions: [
        if (hasBudget)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text("Delete"),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),

        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),

        ElevatedButton.icon(
          onPressed: isSyncing
              ? null
              : () {
                  Navigator.pop(context);
                  onSave();
                },

          icon: isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(hasBudget ? Icons.edit : Icons.save),

          label: Text(
            isSyncing
                ? "Saving..."
                : hasBudget
                ? "Update"
                : "Save",
          ),
        ),
      ],
    );
  }
}
