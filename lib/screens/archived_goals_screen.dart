import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';
import 'package:provider/provider.dart';

import '../services/sync_events.dart';
import '../widgets/empty_state_helper.dart';
import '../providers/connectivity_provider.dart';
import '../repositories/goals_repository.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';

class ArchivedGoalsScreen extends StatefulWidget {
  const ArchivedGoalsScreen({super.key});

  @override
  State<ArchivedGoalsScreen> createState() => _ArchivedGoalsScreenState();
}

class _ArchivedGoalsScreenState extends State<ArchivedGoalsScreen> {
  bool isLoading = true;

  List archivedGoals = [];

  final GoalsRepository goalsRepository = GoalsRepository();

  late VoidCallback _archivedListener;

  bool _hasChanges = false;

  final Map<int, dynamic> _forecastCache = {};
  final Map<int, dynamic> _insightCache = {};

  static List<Map<String, dynamic>> _archivedCache = [];

  @override
  void initState() {
    super.initState();

    _archivedListener = () {
      loadArchivedGoals();
    };

    SyncEvents.instance.archivedRefresh.addListener(_archivedListener);

    if (_archivedCache.isNotEmpty) {
      archivedGoals = List.from(_archivedCache);
      isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadArchivedGoals(background: true);
      });
    } else {
      loadArchivedGoals();
    }
  }

  @override
  void dispose() {
    SyncEvents.instance.archivedRefresh.removeListener(_archivedListener);
    super.dispose();
  }

  Future<void> loadArchivedGoals({bool background = false}) async {
    if (!background) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final data = await goalsRepository.getArchivedGoals();

      if (!mounted) return;

      setState(() {
        archivedGoals = data;
        _archivedCache = List<Map<String, dynamic>>.from(data);

        if (!background) {
          isLoading = false;
        }
      });
    } catch (e) {
      if (!mounted) return;

      if (!background) {
        setState(() {
          isLoading = false;
        });
      }

      debugPrint(e.toString());
    }
  }

  String formatArchivedDate(dynamic value) {
    if (value == null) return "Unknown";

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return "Unknown";

    return DateFormat('dd MMM yyyy').format(parsed);
  }

  Future<void> restoreGoal(Map goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Restore Goal"),
        content: const Text("Move this goal back to your active goals?"),
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

    final connectivity = context.read<ConnectivityProvider>();

    try {
      if (connectivity.isOnline) {
        await goalsRepository.restoreGoalOnline(goal['id']);
      } else {
        await goalsRepository.restoreGoalOffline(goal['id']);
      }

      if (!mounted) return;

      _hasChanges = true;

      _forecastCache.remove(goal['id']);
      _insightCache.remove(goal['id']);

      setState(() {
        archivedGoals.removeWhere((g) => g["id"] == goal["id"]);

        _archivedCache = List<Map<String, dynamic>>.from(archivedGoals);
      });

      SyncEvents.instance.notifyGoalsUpdated();
      SyncEvents.instance.notifyArchivedUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connectivity.isOnline
                ? "Goal restored successfully."
                : "Goal restored offline. It will sync automatically.",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error restoring goal: $e")));
    }
  }

  Widget buildHeader() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = compact
        ? 14.0
        : landscape
        ? 24.0
        : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 20 : 30,
        horizontalPadding,
        compact ? 14 : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Archived Goals",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: compact ? 25 : 30,
            ),
          ),
          SizedBox(height: compact ? 5 : 6),
          Text(
            "Manage your archived financial goals.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: compact ? 13 : 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompletedBadge() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "Completed",
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }

  Widget buildGoalCard(Map goal) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final target = double.tryParse(goal['target_amount'].toString()) ?? 0;

    final saved = double.tryParse(goal['saved_amount'].toString()) ?? 0;

    final extra = saved - target;

    final completed =
        (double.tryParse(goal['completed_percentage'].toString()) ?? 100).clamp(
          0,
          100,
        );

    final archivedDate = formatArchivedDate(goal['completed_at']);

    final categoryColor = Colors.green;

    return Card(
      elevation: compact ? 1 : 2,
      margin: EdgeInsets.only(bottom: compact ? 16 : 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 17 : 22),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────
            // Header
            // ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: compact ? 21 : 24,
                  backgroundColor: Colors.amber.withOpacity(.12),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: compact ? 22 : 25,
                  ),
                ),

                SizedBox(width: spacing),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['title']?.toString() ?? "Untitled Goal",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 15 : 17,
                            ),
                      ),

                      SizedBox(height: compact ? 5 : 6),

                      buildCompletedBadge(),

                      SizedBox(height: compact ? 4 : 5),

                      Text(
                        "Archived on $archivedDate",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: compact ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 18 : 22),

            // ─────────────────────────────────────
            // Amount
            // ─────────────────────────────────────
            Text(
              CurrencyFormatter.format(saved),
              style: TextStyle(
                fontSize: compact ? 25 : 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: compact ? 5 : 6),

            Text(
              "Saved of ${CurrencyFormatter.format(target)} target",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: compact ? 12 : 14,
              ),
            ),

            if (extra > 0) ...[
              SizedBox(height: compact ? 5 : 6),
              Text(
                "🎉 Exceeded target by ${CurrencyFormatter.format(extra)}",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 12 : 14,
                ),
              ),
            ],

            SizedBox(height: compact ? 16 : 18),

            // ─────────────────────────────────────
            // Progress
            // ─────────────────────────────────────
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(begin: 0, end: 1),
              builder: (_, value, __) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: compact ? 8 : 10,
                    backgroundColor: Colors.grey.shade300,
                    color: categoryColor,
                  ),
                );
              },
            ),

            SizedBox(height: compact ? 8 : 10),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 14,
                  vertical: compact ? 6 : 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "100%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ),
            ),

            SizedBox(height: compact ? 15 : 18),

            // ─────────────────────────────────────
            // Achievement
            // ─────────────────────────────────────
            Container(
              margin: EdgeInsets.only(top: compact ? 12 : 20),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 13 : 16,
                vertical: compact ? 9 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(.12),
                borderRadius: BorderRadius.circular(compact ? 14 : 16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    color: Colors.amber,
                    size: compact ? 21 : 24,
                  ),

                  SizedBox(width: spacing),

                  Expanded(
                    child: Text(
                      goal['achievement']?.toString() ?? "Goal Completed",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 12 : 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: compact ? 12 : 14),

            Text(
              "Completed: ${completed.toStringAsFixed(0)}%",
              style: TextStyle(fontSize: compact ? 12 : 14),
            ),

            SizedBox(height: compact ? 4 : 5),

            Text(
              "Archived on: $archivedDate",
              style: TextStyle(color: Colors.grey, fontSize: compact ? 12 : 14),
            ),

            SizedBox(height: compact ? 17 : 20),

            // ─────────────────────────────────────
            // Restore
            // ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: compact ? 50 : 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: compact ? 12 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  ),
                ),
                icon: Icon(Icons.restore, size: compact ? 19 : 21),
                label: Text(
                  "Restore Goal",
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => restoreGoal(goal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = compact
        ? 14.0
        : landscape
        ? 24.0
        : 20.0;

    if (isLoading) {
      return AppScaffold(
        showOfflineBanner: true,
        showSyncIcon: true,
        appBar: const AdaptiveAppBar(
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.archive_rounded),
              SizedBox(width: 8),
              Text(
                "Archived Goals",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (archivedGoals.isEmpty) {
      return AppScaffold(
        showOfflineBanner: true,
        showSyncIcon: true,
        appBar: const AdaptiveAppBar(
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.archive_rounded),
              SizedBox(width: 8),
              Text(
                "Archived Goals",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: buildEmptyState(context, EmptyStateType.archivedGoals),
      );
    }

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,

      appBar: AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_rounded),
            const SizedBox(width: 8),
            Text(
              "Archived Goals",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: loadArchivedGoals,
              child: ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,

                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  compact ? 18 : 24,
                ),

                itemCount: archivedGoals.length,

                itemBuilder: (context, index) {
                  return buildGoalCard(archivedGoals[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
