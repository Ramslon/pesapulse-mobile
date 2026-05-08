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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: updateExpense,

                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Update Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
