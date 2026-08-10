import 'package:flutter/material.dart';

import '../../controllers/goals_controller.dart';
import '../../services/notification_service.dart';
import '../../services/sync_events.dart';
import '../../providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

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
    return AlertDialog(
      title: const Text('Add Savings'),

      content: TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: !_isSaving,
        decoration: const InputDecoration(
          labelText: 'Amount',
          prefixText: 'KES ',
        ),
      ),

      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: _isSaving ? null : _save,
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
