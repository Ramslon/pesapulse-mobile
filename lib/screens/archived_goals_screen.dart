import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';

class ArchivedGoalsScreen extends StatefulWidget {
  const ArchivedGoalsScreen({super.key});

  @override
  State<ArchivedGoalsScreen> createState() => _ArchivedGoalsScreenState();
}

class _ArchivedGoalsScreenState extends State<ArchivedGoalsScreen> {
  bool isLoading = true;

  List archivedGoals = [];

  final currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    loadArchivedGoals();
  }

  Future<void> loadArchivedGoals() async {
    try {
      final data = await ApiService.getArchivedGoals();

      setState(() {
        archivedGoals = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (archivedGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.archive_outlined, size: 90, color: Colors.grey),

            SizedBox(height: 20),

            Text(
              "No Archived Goals",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 8),

            Text(
              "Completed goals will appear here.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadArchivedGoals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: archivedGoals.length,
        itemBuilder: (context, index) {
          final goal = archivedGoals[index];
          final target = double.tryParse(goal['target_amount'].toString()) ?? 0;

          final saved = double.tryParse(goal['saved_amount'].toString()) ?? 0;

          final extra = saved - target;

          final completed =
              (double.tryParse(goal['completed_percentage'].toString()) ?? 100)
                  .clamp(0, 100);

          final archivedDate = DateFormat(
            'dd MMM yyyy',
          ).format(DateTime.parse(goal['completed_at']));

          return Card(
            margin: const EdgeInsets.only(bottom: 16),

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 34,
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            const Text(
                              "Successfully Completed",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${currency.format(saved)} / ${currency.format(target)}",
                  ),

                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "🎉 Exceeded target by ${currency.format(extra)}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: const LinearProgressIndicator(
                            value: 1,
                            minHeight: 10,
                            color: Colors.green,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Text(
                        "100%",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Chip(
                    avatar: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    backgroundColor: Colors.green,
                    label: Text(
                      goal['achievement'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text("Completed: ${completed.toStringAsFixed(0)}%"),

                  const SizedBox(height: 4),

                  Text(
                    "Archived on: $archivedDate",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text("Restore Goal"),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Restore Goal"),
                            content: const Text(
                              "Move this goal back to your active goals?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Restore"),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        await ApiService.restoreGoal(goal['id']);

                        if (!mounted) return;

                        loadArchivedGoals();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Goal restored successfully."),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
