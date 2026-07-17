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
          buildInputField(
            controller: titleController,
            label: "Goal Title",
            icon: Icons.flag_outlined,
          ),

          const SizedBox(height: 22),

          buildInputField(
            controller: amountController,
            label: "Target Amount",
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: TextInputType.number,
            prefixText: "KES ",
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : saveGoal,
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
              label: Text(isLoading ? "Saving..." : "Create Goal"),
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
