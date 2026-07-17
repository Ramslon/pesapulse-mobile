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
      appBar: AppBar(title: const Text(""), elevation: 0),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
        children: [
          Text(
            "Add Financial Goal",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            "Create a new savings goal and start tracking your progress.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),

          const SizedBox(height: 28),

          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.flag_rounded,
                size: 42,
                color: Colors.deepPurple,
              ),
            ),
          ),

          const SizedBox(height: 32),
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
    );
  }
}
