import 'package:flutter/material.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController titleController = TextEditingController();

  final TextEditingController amountController = TextEditingController();

  final TextEditingController categoryController = TextEditingController();

  final TextEditingController descriptionController = TextEditingController();

  final TextEditingController dateController = TextEditingController();

  bool isLoading = false;

  void addExpense() {
    String title = titleController.text.trim();
    String amount = amountController.text.trim();
    String category = categoryController.text.trim();
    String description = descriptionController.text.trim();
    String expenseDate = dateController.text.trim();

    print(title);
    print(amount);
    print(category);
    print(description);
    print(expenseDate);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Expense Added')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),

          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Expense Title',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
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
                  labelText: 'Expense Date',
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
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
                  onPressed: addExpense,

                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
