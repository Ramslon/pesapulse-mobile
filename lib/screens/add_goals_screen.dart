import 'package:flutter/material.dart';
import '../services/api_services.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  bool isLoading = false;

  Future<void> saveGoal() async {
    try {
      if (titleController.text.trim().isEmpty) {
        throw Exception('Enter goal title');
      }

      if (amountController.text.trim().isEmpty) {
        throw Exception('Enter target amount');
      }

      final amount = double.parse(amountController.text.trim());

      setState(() {
        isLoading = true;
      });

      await ApiService.createGoal(
        title: titleController.text.trim(),
        targetAmount: amount,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Goal')),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            TextField(
              controller: titleController,

              decoration: const InputDecoration(labelText: 'Goal Title'),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: amountController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: 'Target Amount',
                prefixText: 'KES ',
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: isLoading ? null : saveGoal,

                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
