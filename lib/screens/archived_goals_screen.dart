import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/sync_events.dart';
import '../widgets/goal_empty_state.dart';

import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../repositories/goals_repository.dart';

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

  final GoalsRepository goalsRepository = GoalsRepository();

  late VoidCallback _goalRefreshListener;

  bool _hasChanges = false;

  final Map<int, dynamic> _forecastCache = {};

  final Map<int, dynamic> _insightCache = {};

  @override
  void initState() {
    super.initState();

    loadArchivedGoals();
    _goalRefreshListener = () {
      if (mounted) {
        loadArchivedGoals();
      }
    };

    SyncEvents.instance.goalsRefresh.addListener(_goalRefreshListener);
  }

  @override
  void dispose() {
    SyncEvents.instance.goalsRefresh.removeListener(_goalRefreshListener);
    super.dispose();
  }

  Future<void> loadArchivedGoals() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await goalsRepository.getArchivedGoals();

      if (!mounted) return;

      setState(() {
        archivedGoals = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (archivedGoals.isEmpty) {
      return const GoalEmptyState(
        icon: Icons.archive_outlined,
        title: "No Archived Goals",
        message:
            "Completed goals that you archive will appear here for future reference.",
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const SizedBox.shrink(),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _hasChanges);
          },
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 30,
              bottom: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Archived Goals",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Manage your archived financial goals.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadArchivedGoals,

              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: archivedGoals.length,
                itemBuilder: (context, index) {
                  final goal = archivedGoals[index];
                  final target =
                      double.tryParse(goal['target_amount'].toString()) ?? 0;

                  final saved =
                      double.tryParse(goal['saved_amount'].toString()) ?? 0;

                  final extra = saved - target;

                  final completed =
                      (double.tryParse(
                                goal['completed_percentage'].toString(),
                              ) ??
                              100)
                          .clamp(0, 100);

                  final archivedDate = goal['completed_at'] != null
                      ? DateFormat(
                          'dd MMM yyyy',
                        ).format(DateTime.parse(goal['completed_at']))
                      : "Unknown";

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(16),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.amber.withOpacity(.12),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      goal['title'],
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),

                                    const SizedBox(height: 6),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "Completed",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "Archived on $archivedDate",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          Text(
                            currency.format(saved),
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "Saved of ${currency.format(target)} target",
                            style: TextStyle(color: Colors.grey.shade600),
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

                          const SizedBox(height: 18),

                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 900),
                            tween: Tween(begin: 0, end: 1),
                            builder: (_, value, __) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade300,
                                  color: Colors.green,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "100%",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium,
                                  color: Colors.amber,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Text(
                                    goal['achievement'] ?? "Goal Completed",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text("Restore"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm != true) return;

                                final connectivity = context
                                    .read<ConnectivityProvider>();

                                if (connectivity.isOnline) {
                                  await goalsRepository.restoreGoalOnline(
                                    goal['id'],
                                  );
                                } else {
                                  await goalsRepository.restoreGoalOffline(
                                    goal['id'],
                                  );
                                }

                                if (!mounted) return;

                                _hasChanges = true;
                                _forecastCache.remove(goal['id']);
                                _insightCache.remove(goal['id']);
                                SyncEvents.instance.notifyGoalsUpdated();
                                await loadArchivedGoals();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      connectivity.isOnline
                                          ? "Goal restored successfully."
                                          : "Goal restored offline. It will sync automatically.",
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }
}
