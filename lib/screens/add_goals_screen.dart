import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sync_events.dart';
import '../providers/connectivity_provider.dart';
import '../repositories/goals_repository.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  bool isLoading = false;

  final GoalsRepository goalsRepository = GoalsRepository();

  Future<void> saveGoal() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a goal title.")),
      );
      return;
    }

    if (amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a target amount.")),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Target amount must be greater than zero."),
        ),
      );
      return;
    }

    if (isLoading) return;

    try {
      setState(() {
        isLoading = true;
      });

      final connectivity = context.read<ConnectivityProvider>();

      await goalsRepository.createGoal(
        title: titleController.text.trim(),
        targetAmount: amount,
        isOnline: connectivity.isOnline,
      );

      SyncEvents.instance.notifyGoalsUpdated();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connectivity.isOnline
                ? "Goal created successfully!"
                : "Goal saved offline. It will sync automatically.",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

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
  void initState() {
    super.initState();

    titleController.addListener(() {
      setState(() {});
    });

    amountController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();

    super.dispose();
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: (_) {
        onSubmitted?.call();
      },
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(icon, size: compact ? 20 : 22),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 18),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: compact ? 1.5 : 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 14 : 17,
        ),
      ),
    );
  }

  Widget buildGoalPreview() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final goalTitle = titleController.text.trim().isEmpty
        ? "Your Goal"
        : titleController.text.trim();

    final amount = double.tryParse(amountController.text) ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: compact ? 20 : 22,
                  backgroundColor: Colors.deepPurple.withOpacity(.12),
                  child: Icon(
                    Icons.flag_rounded,
                    color: Colors.deepPurple,
                    size: compact ? 21 : 24,
                  ),
                ),

                SizedBox(width: ResponsiveHelper.spacing(context)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Goal Preview",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: compact ? 15 : 17,
                            ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        "Live preview of your goal",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: compact ? 11 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 16 : 20),

            Text(
              goalTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: compact ? 7 : 10),

            Text(
              "Target: KES ${amount.toStringAsFixed(0)}",
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            SizedBox(height: compact ? 14 : 18),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: 0,
                minHeight: compact ? 7 : 8,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "0% Complete",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: compact ? 11 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTipCard() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 15 : 18),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.blue,
              size: compact ? 21 : 24,
            ),

            SizedBox(width: ResponsiveHelper.spacing(context)),

            Expanded(
              child: Text(
                "Set realistic savings goals and update your progress regularly to stay on track.",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: compact ? 12 : 14,
                  height: 1.4,
                ),
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

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final headingSize = compact ? 25.0 : 30.0;

    final subtitleSize = compact ? 13.0 : 15.0;

    final iconContainerSize = compact ? 72.0 : 88.0;

    final iconSize = compact ? 34.0 : 42.0;

    final buttonHeight = compact ? 52.0 : 56.0;

    final hasRequiredFields =
        titleController.text.trim().isNotEmpty &&
        amountController.text.trim().isNotEmpty;

    return AppScaffold(
      showOfflineBanner: true,
      showSyncIcon: true,

      appBar: const AdaptiveAppBar(
        titleWidget: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_rounded),
            SizedBox(width: 8),
            Text("Add Goal", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),

        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,

            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              compact ? 20 : 28,
              horizontalPadding,
              compact ? 20 : 24,
            ),

            children: [
              Text(
                "Add Financial Goal",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: headingSize,
                ),
              ),

              SizedBox(height: compact ? 6 : 8),

              Text(
                "Create a new savings goal and start tracking your progress.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: subtitleSize,
                  height: 1.4,
                ),
              ),

              SizedBox(height: compact ? 20 : sectionSpacing),

              Center(
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(.12),
                    borderRadius: BorderRadius.circular(compact ? 20 : 24),
                  ),
                  child: Icon(
                    Icons.flag_rounded,
                    size: iconSize,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              SizedBox(height: compact ? 20 : sectionSpacing),

              buildGoalPreview(),

              SizedBox(height: compact ? 20 : sectionSpacing),

              buildTipCard(),

              SizedBox(height: compact ? 20 : 24),

              buildInputField(
                controller: titleController,
                label: "Goal Title",
                icon: Icons.flag_outlined,
                textInputAction: TextInputAction.next,
              ),

              SizedBox(height: compact ? 10 : 14),

              buildInputField(
                controller: amountController,
                label: "Target Amount",
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixText: "KES ",
                textInputAction: TextInputAction.done,
                onSubmitted: saveGoal,
              ),

              SizedBox(height: compact ? 10 : 14),

              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: isLoading || !hasRequiredFields ? null : saveGoal,

                  icon: isLoading
                      ? SizedBox(
                          width: compact ? 20 : 22,
                          height: compact ? 20 : 22,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.check_circle_outline,
                          size: compact ? 20 : 22,
                        ),

                  label: Text(
                    isLoading ? "Saving..." : "Create Goal",
                    style: TextStyle(
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(compact ? 15 : 18),
                    ),
                  ),
                ),
              ),

              SizedBox(height: compact ? 12 : 20),
            ],
          ),
        ),
      ),
    );
  }
}
