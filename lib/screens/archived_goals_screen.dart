import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency_formatter.dart';
import '../exceptions/rate_limit_exception.dart';
import '../providers/connectivity_provider.dart';
import '../repositories/goals_repository.dart';
import '../services/sync_events.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';

const Color _goalAmber = Color(0xFFF59E0B);
const Color _goalAmberDark = Color(0xFFB45309);
const Color _completedGreen = Color(0xFF16A34A);

class ArchivedGoalsScreen extends StatefulWidget {
  const ArchivedGoalsScreen({super.key});

  @override
  State<ArchivedGoalsScreen> createState() => _ArchivedGoalsScreenState();
}

class _ArchivedGoalsScreenState extends State<ArchivedGoalsScreen> {
  bool isLoading = true;

  bool _hasChanges = false;
  bool _handlingBack = false;

  String? _loadError;

  List<Map<String, dynamic>> archivedGoals = [];

  final GoalsRepository goalsRepository = GoalsRepository();

  late VoidCallback _archivedListener;

  final Map<int, dynamic> _forecastCache = {};
  final Map<int, dynamic> _insightCache = {};

  final Set<String> _restoringGoalIds = {};

  static List<Map<String, dynamic>> _archivedCache = [];

  @override
  void initState() {
    super.initState();

    _archivedListener = () {
      if (mounted) {
        loadArchivedGoals();
      }
    };

    SyncEvents.instance.archivedRefresh.addListener(_archivedListener);

    if (_archivedCache.isNotEmpty) {
      archivedGoals = List<Map<String, dynamic>>.from(_archivedCache);

      isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          loadArchivedGoals(background: true);
        }
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

  // ============================================================
  // DATA
  // ============================================================

  Future<void> loadArchivedGoals({bool background = false}) async {
    if (!mounted) return;

    if (!background) {
      setState(() {
        isLoading = true;
        _loadError = null;
      });
    }

    try {
      final data = await goalsRepository.getArchivedGoals();

      if (!mounted) return;

      final normalizedData = data
          .map<Map<String, dynamic>>((goal) => Map<String, dynamic>.from(goal))
          .toList();

      setState(() {
        archivedGoals = normalizedData;
        _archivedCache = List<Map<String, dynamic>>.from(normalizedData);
        isLoading = false;
        _loadError = null;
      });
    } on RateLimitException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;

        if (archivedGoals.isEmpty) {
          _loadError = e.message;
        }
      });

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('ArchivedGoalsScreen: failed to load archived goals: $e');

      setState(() {
        isLoading = false;

        // Retain displayed cached goals after a failed
        // background refresh.
        if (archivedGoals.isEmpty) {
          _loadError = _cleanError(e);
        }
      });
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }

    return message;
  }

  double _number(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _goalKey(Map goal) {
    return (goal['id'] ?? goal['server_id'] ?? '').toString();
  }

  String formatArchivedDate(dynamic value) {
    if (value == null) {
      return 'Unknown date';
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) {
      return 'Unknown date';
    }

    return DateFormat('dd MMM yyyy').format(parsed);
  }

  double _completionPercentage(Map goal) {
    final rawValue = goal['completed_percentage'];

    final double completion;

    if (rawValue != null) {
      completion = _number(rawValue);
    } else {
      final target = _number(goal['target_amount']);
      final saved = _number(goal['saved_amount']);

      completion = target > 0 ? (saved / target) * 100 : 100;
    }

    return completion.clamp(0.0, 100.0).toDouble();
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<void> restoreGoal(Map<String, dynamic> goal) async {
    final key = _goalKey(goal);

    if (_restoringGoalIds.contains(key)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _goalAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restore_rounded, color: _goalAmberDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Restore goal?',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            'Move "${goal['title']?.toString() ?? 'this goal'}" back to your active goals?',
            style: TextStyle(
              height: 1.45,
              color: colorScheme.onSurface.withOpacity(0.68),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _goalAmberDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.restore_rounded, size: 18),
              label: const Text('Restore Goal'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _restoringGoalIds.add(key);
    });

    try {
      final connectivity = context.read<ConnectivityProvider>();

      if (connectivity.isOnline) {
        await goalsRepository.restoreGoalOnline(goal['id'], goal['server_id']);
      } else {
        await goalsRepository.restoreGoalOffline(goal['id']);
      }

      if (!mounted) return;

      _hasChanges = true;

      final localId = goal['id'];

      if (localId is int) {
        _forecastCache.remove(localId);
        _insightCache.remove(localId);
      }

      setState(() {
        archivedGoals.removeWhere((item) => _goalKey(item) == key);

        _archivedCache = List<Map<String, dynamic>>.from(archivedGoals);

        _restoringGoalIds.remove(key);
      });

      SyncEvents.instance.notifyGoalsUpdated();
      SyncEvents.instance.notifyArchivedUpdated();

      SnackbarHelper.showSuccess(
        context,
        connectivity.isOnline
            ? 'Goal restored successfully.'
            : 'Goal restored offline. It will sync automatically.',
      );
    } on RateLimitException catch (e) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('ArchivedGoalsScreen: failed to restore goal: $e');

      SnackbarHelper.showError(
        context,
        'Unable to restore goal. Please try again.',
      );
    } finally {
      if (mounted && _restoringGoalIds.contains(key)) {
        setState(() {
          _restoringGoalIds.remove(key);
        });
      }
    }
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 17 : 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 48 : 56,
            height: compact ? 48 : 56,
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(compact ? 14 : 16),
            ),
            child: Icon(
              Icons.archive_rounded,
              size: compact ? 24 : 28,
              color: _goalAmberDark,
            ),
          ),

          SizedBox(width: compact ? 12 : 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOAL HISTORY',
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: _goalAmberDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Archived Goals',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 25 : 30,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Review completed milestones and restore goals whenever you need them.',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.60),
                    fontSize: compact ? 12 : 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ARCHIVE SUMMARY
  // ============================================================

  Widget _buildArchiveSummary(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    final totalSaved = archivedGoals.fold<double>(
      0,
      (total, goal) => total + _number(goal['saved_amount']),
    );

    final totalTarget = archivedGoals.fold<double>(
      0,
      (total, goal) => total + _number(goal['target_amount']),
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 20 : 26),
      padding: EdgeInsets.all(compact ? 15 : 19),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 19 : 23),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 40,
                height: compact ? 36 : 40,
                decoration: BoxDecoration(
                  color: _goalAmber.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: _goalAmberDark,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your goal archive',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'A record of your financial milestones',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: colorScheme.onSurface.withOpacity(0.56),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _completedGreen.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${archivedGoals.length} ${archivedGoals.length == 1 ? 'goal' : 'goals'}',
                  style: TextStyle(
                    color: _completedGreen,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final gap = compact ? 9.0 : 12.0;
              final itemWidth = (constraints.maxWidth - gap) / 2;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildSummaryMetric(
                      context,
                      label: 'TOTAL SAVED',
                      value: CurrencyFormatter.format(totalSaved),
                      icon: Icons.savings_rounded,
                      color: _completedGreen,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildSummaryMetric(
                      context,
                      label: 'COMBINED TARGET',
                      value: CurrencyFormatter.format(totalTarget),
                      icon: Icons.flag_rounded,
                      color: _goalAmberDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 11 : 13),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.38),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 31 : 35,
            height: compact ? 31 : 35,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 8.5 : 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                    color: colorScheme.onSurface.withOpacity(0.49),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GOAL CARD
  // ============================================================

  Widget _buildGoalCard(BuildContext context, Map<String, dynamic> goal) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    final title = goal['title']?.toString() ?? 'Untitled Goal';

    final target = _number(goal['target_amount']);

    final saved = _number(goal['saved_amount']);

    final extra = saved - target;

    final completed = _completionPercentage(goal);

    final progress = completed / 100;

    final archivedDate = formatArchivedDate(goal['completed_at']);

    final achievement = goal['achievement']?.toString().trim();

    final key = _goalKey(goal);

    final isRestoring = _restoringGoalIds.contains(key);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: compact ? 14 : 17),
      padding: EdgeInsets.all(compact ? 15 : 19),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 19 : 23),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal title and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 45 : 50,
                height: compact ? 45 : 50,
                decoration: BoxDecoration(
                  color: _goalAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(compact ? 13 : 15),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: _goalAmberDark,
                  size: compact ? 23 : 26,
                ),
              ),

              SizedBox(width: compact ? 11 : 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: compact ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 8),
                    _buildStatusBadge(
                      context,
                      completed >= 100 ? 'Completed' : 'Archived',
                      completed >= 100 ? _completedGreen : _goalAmberDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.archive_outlined,
                size: compact ? 18 : 20,
                color: colorScheme.onSurface.withOpacity(0.32),
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 18),

          // Archive date
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: colorScheme.onSurface.withOpacity(0.50),
                  size: compact ? 16 : 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Completed / archived on $archivedDate',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 10.5 : 11.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.62),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 17 : 20),

          // Amount saved
          Text(
            'TOTAL SAVED',
            style: TextStyle(
              fontSize: compact ? 9 : 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.85,
              color: colorScheme.onSurface.withOpacity(0.48),
            ),
          ),

          const SizedBox(height: 5),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(saved),
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 25 : 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Target: ${CurrencyFormatter.format(target)}',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.58),
            ),
          ),

          if (extra > 0) ...[
            SizedBox(height: compact ? 10 : 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 9 : 10,
              ),
              decoration: BoxDecoration(
                color: _completedGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: _completedGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Exceeded target by ${CurrencyFormatter.format(extra)}',
                      style: TextStyle(
                        color: _completedGreen,
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: compact ? 18 : 20),

          // Completion progress
          Row(
            children: [
              Expanded(
                child: Text(
                  'Goal completion',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withOpacity(0.68),
                  ),
                ),
              ),
              Text(
                '${completed.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w900,
                  color: _completedGreen,
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 8 : 9),

          TweenAnimationBuilder<double>(
            key: ValueKey('${key}_progress'),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: compact ? 7 : 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    _completedGreen,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: compact ? 15 : 17),

          // Achievement
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 11 : 13),
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _goalAmber.withOpacity(0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 33 : 37,
                  height: compact ? 33 : 37,
                  decoration: BoxDecoration(
                    color: _goalAmber.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: _goalAmberDark,
                    size: 20,
                  ),
                ),
                SizedBox(width: compact ? 9 : 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MILESTONE',
                        style: TextStyle(
                          fontSize: compact ? 8.5 : 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: _goalAmberDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        achievement != null && achievement.isNotEmpty
                            ? achievement
                            : completed >= 100
                            ? 'Goal Completed'
                            : 'Goal Archived',
                        style: TextStyle(
                          fontSize: compact ? 11.5 : 12.5,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? 16 : 19),

          // Restore action
          SizedBox(
            width: double.infinity,
            height: compact ? 48 : 52,
            child: FilledButton.icon(
              onPressed: isRestoring ? null : () => restoreGoal(goal),
              style: FilledButton.styleFrom(
                backgroundColor: _goalAmberDark,
                disabledBackgroundColor: _goalAmberDark.withOpacity(0.55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                ),
              ),
              icon: isRestoring
                  ? SizedBox(
                      width: compact ? 17 : 19,
                      height: compact ? 17 : 19,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.restore_rounded, size: compact ? 18 : 20),
              label: Text(
                isRestoring ? 'Restoring...' : 'Restore Goal',
                style: TextStyle(
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String label, Color color) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Completed'
                ? Icons.check_circle_rounded
                : Icons.archive_rounded,
            size: compact ? 12 : 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: compact ? 8.5 : 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY / ERROR / LOADING STATES
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: compact ? 4 : 8, bottom: 20),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 28,
        vertical: compact ? 27 : 34,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 19 : 23),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Container(
            width: compact ? 68 : 80,
            height: compact ? 68 : 80,
            decoration: BoxDecoration(
              color: _goalAmber.withOpacity(0.10),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: compact ? 30 : 35,
              color: _goalAmberDark,
            ),
          ),
          SizedBox(height: compact ? 15 : 18),
          Text(
            'No archived goals yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Completed or archived goals will appear here so you can review your progress and restore them when needed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              height: 1.5,
              color: colorScheme.onSurface.withOpacity(0.58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.error.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: compact ? 42 : 50,
            color: colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to load archived goals',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            _loadError ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.60),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => loadArchivedGoals(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 62 : 70,
              height: compact ? 62 : 70,
              decoration: BoxDecoration(
                color: _goalAmber.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.all(17),
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: _goalAmberDark,
                ),
              ),
            ),
            SizedBox(height: compact ? 15 : 18),
            Text(
              'Loading your archive',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'Retrieving your saved milestones...',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.55)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final isInitialLoading = isLoading && archivedGoals.isEmpty;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _handlingBack || !mounted) {
          return;
        }

        _handlingBack = true;

        Navigator.of(context).pop(_hasChanges);
      },
      child: AppScaffold(
        showOfflineBanner: true,
        showSyncIcon: true,
        appBar: const AdaptiveAppBar(
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.archive_rounded),
              SizedBox(width: 8),
              Text(
                'Archived Goals',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: isInitialLoading
            ? _buildLoadingState(context)
            : RefreshIndicator(
                color: _goalAmberDark,
                onRefresh: () => loadArchivedGoals(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 16 : 22,
                    horizontalPadding,
                    compact ? 24 : 32,
                  ),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(context),

                              if (_loadError != null &&
                                  archivedGoals.isEmpty) ...[
                                _buildErrorState(context),
                              ] else if (archivedGoals.isEmpty) ...[
                                _buildEmptyState(context),
                              ] else ...[
                                _buildArchiveSummary(context),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns = constraints.maxWidth >= 800
                                        ? 2
                                        : 1;

                                    const gap = 16.0;

                                    final cardWidth = columns == 2
                                        ? (constraints.maxWidth - gap) / 2
                                        : constraints.maxWidth;

                                    return Wrap(
                                      spacing: gap,
                                      runSpacing: 0,
                                      children: archivedGoals
                                          .map(
                                            (goal) => SizedBox(
                                              width: cardWidth,
                                              child: _buildGoalCard(
                                                context,
                                                goal,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
