import 'package:flutter/material.dart';

import '../services/api_services.dart';

class EditExpenseScreen extends StatefulWidget {
  final Map expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  late TextEditingController titleController;

  late TextEditingController amountController;

  late TextEditingController categoryController;

  late TextEditingController dateController;

  late TextEditingController descriptionController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.expense['title']);

    amountController = TextEditingController(
      text: widget.expense['amount'].toString(),
    );

    categoryController = TextEditingController(
      text: widget.expense['category'],
    );

    dateController = TextEditingController(
      text: widget.expense['expense_date'],
    );

    descriptionController = TextEditingController(
      text: widget.expense['description'] ?? '',
    );

    titleController.addListener(() => setState(() {}));

    amountController.addListener(() => setState(() {}));

    categoryController.addListener(() {
      setState(() {});
    });

    dateController.addListener(() {
      setState(() {});
    });

    descriptionController.addListener(() {
      setState(() {});
    });
  }

  void updateExpense() async {
    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.updateExpense(
        widget.expense['id'],

        titleController.text.trim(),

        amountController.text.trim(),

        categoryController.text.trim(),

        dateController.text.trim(),

        descriptionController.text.trim(),
      );

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense updated successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget buildExpensePreview() {
    final title = titleController.text.isEmpty
        ? "Expense Title"
        : titleController.text;

    final amount = double.tryParse(amountController.text) ?? 0;

    final category = categoryController.text.isEmpty
        ? "Category"
        : categoryController.text;

    final date = dateController.text.isEmpty ? "No Date" : dateController.text;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(.12),
                  child: const Icon(Icons.receipt_long, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Text(
                  "Expense Preview",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "KES ${amount.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  avatar: const Icon(Icons.category, size: 18),
                  label: Text(category),
                ),
                Chip(
                  avatar: const Icon(Icons.calendar_today, size: 18),
                  label: Text(date),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(""), elevation: 0),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),

        children: [
          Text(
            "Edit Expense",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            "Update your expense details and keep your spending records accurate.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),

          const SizedBox(height: 28),

          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                size: 42,
                color: Colors.orange,
              ),
            ),
          ),

          const SizedBox(height: 30),

          Card(
            elevation: 0,
            color: Colors.orange.withOpacity(.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Keep your expense information accurate for better spending insights and reports.",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          buildExpensePreview(),

          const SizedBox(height: 24),
          buildInputField(
            controller: titleController,
            label: "Expense Title",
            icon: Icons.receipt_long_outlined,
          ),

          const SizedBox(height: 20),

          buildInputField(
            controller: amountController,
            label: "Amount",
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            prefixText: "KES ",
          ),

          const SizedBox(height: 20),

          buildInputField(
            controller: categoryController,
            label: "Category",
            icon: Icons.category_outlined,
          ),

          const SizedBox(height: 20),

          buildInputField(
            controller: dateController,
            label: "Date",
            icon: Icons.calendar_today_outlined,
          ),

          const SizedBox(height: 20),

          buildInputField(
            controller: descriptionController,
            label: "Description",
            icon: Icons.notes_outlined,
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : updateExpense,

              icon: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),

              label: Text(isLoading ? "Updating..." : "Update Expense"),

              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
