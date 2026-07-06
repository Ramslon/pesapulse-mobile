import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../widgets/custom_button.dart';
import '../widgets/input_icon_badge.dart';
import '../services/notification_service.dart';

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

  final _formKey = GlobalKey<FormState>();

  List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  final Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Bills': Icons.receipt_long,
    'Entertainment': Icons.movie,
    'Health': Icons.favorite,
    'Education': Icons.school,
    'Other': Icons.category,
  };

  final Map<String, Color> categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Shopping': Colors.purple,
    'Bills': Colors.red,
    'Entertainment': Colors.pink,
    'Health': Colors.green,
    'Education': Colors.indigo,
    'Other': Colors.grey,
  };

  String selectedCategory = 'Food';

  bool isLoading = false;

  void addExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    String title = titleController.text.trim();

    String amount = amountController.text.trim();

    String category = selectedCategory;

    String description = descriptionController.text.trim();

    String expenseDate = dateController.text.trim();

    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.addExpense(
        title,
        amount,
        category,
        expenseDate,
        description,
      );

      setState(() {
        isLoading = false;
      });

      if (response.containsKey('id')) {
        await NotificationService.checkBudgetAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.green.shade600,
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Expense saved successfully!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        Navigator.pop(context, response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to add expense'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> pickExpenseDate() async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: "Select Expense Date",
      cancelText: "Cancel",
      confirmText: "Select",
    );

    if (pickedDate != null) {
      dateController.text =
          "${pickedDate.year}-"
          "${pickedDate.month.toString().padLeft(2, '0')}-"
          "${pickedDate.day.toString().padLeft(2, '0')}";
    }
  }

  void clearForm() {
    titleController.clear();

    amountController.clear();

    descriptionController.clear();

    dateController.clear();

    selectedCategory = "Food";
  }

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    dateController.text =
        "${now.year}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    dateController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded),
            SizedBox(width: 10),
            Text("Add Expense", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Record a new expense",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Keep your spending up to date.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),

                  const SizedBox(height: 25),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        InputIconBadge(
                          icon: Icons.receipt_long_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Expense Details",
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextFormField(
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter an expense title";
                                }

                                if (value.trim().length < 3) {
                                  return "Title is too short";
                                }

                                return null;
                              },
                              textInputAction: TextInputAction.next,
                              controller: titleController,
                              decoration: InputDecoration(
                                labelText: "Expense Title",
                                hintText: "e.g. Grocery Shopping",
                                prefixIcon: InputIconBadge(
                                  icon: Icons.edit_note_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: amountController,
                              textInputAction: TextInputAction.next,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: "Amount",
                                hintText: "Enter amount",
                                prefixText: "KES ",
                                prefixIcon: const InputIconBadge(
                                  icon: Icons.payments_rounded,
                                  color: Colors.green,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter an amount";
                                }

                                final amount = double.tryParse(value);

                                if (amount == null) {
                                  return "Enter a valid number";
                                }

                                if (amount <= 0) {
                                  return "Amount must be greater than zero";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 12),

                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [100, 200, 500, 1000, 2000].map((
                                amount,
                              ) {
                                return ActionChip(
                                  label: Text("KES $amount"),
                                  onPressed: () {
                                    amountController.text = amount.toString();
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            DropdownButtonFormField<String>(
                              value: selectedCategory,

                              decoration: InputDecoration(
                                labelText: "Category",

                                prefixIcon: InputIconBadge(
                                  icon: categoryIcons[selectedCategory]!,
                                  color: categoryColors[selectedCategory]!,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),

                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Row(
                                    children: [
                                      InputIconBadge(
                                        icon: categoryIcons[category]!,
                                        color: categoryColors[category]!,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(category),
                                    ],
                                  ),
                                );
                              }).toList(),

                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value!;
                                });
                              },
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              textInputAction: TextInputAction.next,
                              controller: dateController,
                              readOnly: true,
                              onTap: pickExpenseDate,
                              decoration: InputDecoration(
                                labelText: "Expense Date",
                                hintText: "Select date",
                                prefixIcon: const InputIconBadge(
                                  icon: Icons.calendar_month_rounded,
                                  color: Colors.orange,
                                ),
                                suffixIcon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Select an expense date";
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const InputIconBadge(
                                    icon: Icons.sticky_note_2_rounded,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Additional Notes",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextFormField(
                              textInputAction: TextInputAction.done,
                              controller: descriptionController,
                              maxLines: 5,
                              maxLength: 250,
                              decoration: InputDecoration(
                                labelText: "Description",
                                hintText: "Optional notes...",
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(bottom: 60),
                                  child: InputIconBadge(
                                    icon: Icons.notes_rounded,
                                    color: Colors.blue,
                                  ),
                                ),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value != null && value.length > 250) {
                                  return "Maximum 250 characters";
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 36),

                            AnimatedScale(
                              duration: const Duration(milliseconds: 180),
                              scale: isLoading ? 0.97 : 1,
                              curve: Curves.easeOut,
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: CustomButton(
                                  text: "Save Expense",
                                  isLoading: isLoading,
                                  onPressed: addExpense,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
