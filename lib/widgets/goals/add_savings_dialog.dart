import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/goals_controller.dart';
import '../../services/notification_service.dart';
import '../../services/sync_events.dart';
import '../../providers/connectivity_provider.dart';
import '../../utils/responsive_helper.dart';

class AddSavingsDialog extends StatefulWidget {
  final int goalId;
  final GoalsController goalsController;

  const AddSavingsDialog({
    super.key,
    required this.goalId,
    required this.goalsController,
  });

  @override
  State<AddSavingsDialog> createState() => _AddSavingsDialogState();
}

class _AddSavingsDialogState extends State<AddSavingsDialog> {
  final TextEditingController _amountController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid savings amount.')),
      );
      return;
    }

    final connectivity = context.read<ConnectivityProvider>();

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await widget.goalsController.addSavings(
        goalId: widget.goalId,
        amount: amount,
        isOnline: connectivity.isOnline,
      );

      SyncEvents.instance.notifyGoalsUpdated();

      if (!mounted) return;

      Navigator.pop(context);

      if (!connectivity.isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Savings added offline. Changes will sync automatically.',
            ),
          ),
        );
      }

      final milestone = response?['milestone'];

      if (milestone != null) {
        await NotificationService.showNotification(
          title: milestone['percentage'] == 100
              ? '🏆 Goal Completed'
              : '🎯 Goal Milestone',
          body: milestone['message'],
        );

        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(
              milestone['percentage'] == 100
                  ? '🏆 Goal Completed'
                  : '🎉 Milestone Reached',
            ),
            content: Text(milestone['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Awesome'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add savings: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = isCompact
        ? 18.0
        : isLandscape
        ? 22.0
        : 24.0;

    final verticalPadding = isCompact ? 18.0 : 22.0;

    final titleFontSize = isCompact ? 19.0 : 20.0;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 18 : 24,
        vertical: isLandscape ? 16 : 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        horizontalPadding,
        8,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        4,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        horizontalPadding,
        8,
        horizontalPadding,
        isCompact ? 14 : 18,
      ),
      title: Row(
        children: [
          Container(
            width: isCompact ? 38 : 42,
            height: isCompact ? 38 : 42,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
            ),
            child: Icon(
              Icons.savings_outlined,
              color: colorScheme.primary,
              size: isCompact ? 20 : 22,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              'Add Savings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: isCompact
            ? 280
            : isLandscape
            ? 360
            : 320,
        child: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_isSaving,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isSaving) {
              _save();
            }
          },
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter savings amount',
            prefixText: 'KES ',
            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withOpacity(.35),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 15),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 15),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(.10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isCompact ? 13 : 15),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            minimumSize: Size(isCompact ? 82 : 90, isCompact ? 42 : 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isCompact ? 12 : 13),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
