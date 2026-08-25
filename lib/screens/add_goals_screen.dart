import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/sync_events.dart';
import '../providers/connectivity_provider.dart';
import '../repositories/goals_repository.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();

  DateTime? selectedTargetDate;

  bool isLoading = false;

  final GoalsRepository goalsRepository = GoalsRepository();

  Future<void> saveGoal() async {
    if (titleController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, "Please enter a goal title.");
      return;
    }

    if (amountController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, "Please enter a target amount.");
      return;
    }

    final amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      SnackbarHelper.showError(
        context,
        "Target amount must be greater than zero.",
      );
      return;
    }

    if (isLoading) return;

    try {
      setState(() => isLoading = true);

      final connectivity = context.read<ConnectivityProvider>();

      await goalsRepository.createGoal(
        title: titleController.text.trim(),
        targetAmount: amount,
        targetDate: selectedTargetDate?.toIso8601String(),
        isOnline: connectivity.isOnline,
      );

      SyncEvents.instance.notifyGoalsUpdated();

      if (!mounted) return;

      SnackbarHelper.showSuccess(
        context,
        connectivity.isOnline
            ? "Goal created successfully!"
            : "Goal saved offline. It will sync automatically.",
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      SnackbarHelper.showError(context, "Failed to save goal: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> selectTargetDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedTargetDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      helpText: "Choose your target date",
      cancelText: "Cancel",
      confirmText: "Select",
    );

    if (pickedDate == null) return;

    setState(() {
      selectedTargetDate = pickedDate;
    });
  }

  void clearTargetDate() {
    setState(() {
      selectedTargetDate = null;
    });
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String formatAmount(double amount) {
    if (amount <= 0) return "0";

    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }

  @override
  void initState() {
    super.initState();

    titleController.addListener(_onFormChanged);
    amountController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();

    super.dispose();
  }

  Widget buildSectionTitle({required String title, String? subtitle}) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 16 : 18,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(.65),
              fontSize: compact ? 11.5 : 13,
            ),
          ),
        ],
      ],
    );
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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: label == "Goal Title"
          ? TextCapitalization.sentences
          : TextCapitalization.none,
      onSubmitted: (_) {
        onSubmitted?.call();
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: label == "Goal Title" ? "e.g. Emergency Fund" : "e.g. 50,000",
        prefixText: prefixText,
        prefixIcon: Icon(icon, size: compact ? 20 : 22),
        prefixIconColor: primary.withOpacity(.75),
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 17),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 17),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(.55)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 15 : 17),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        floatingLabelStyle: TextStyle(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 15 : 17,
        ),
      ),
    );
  }

  Widget buildTargetDateField() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final hasDate = selectedTargetDate != null;

    return InkWell(
      onTap: isLoading ? null : selectTargetDate,
      borderRadius: BorderRadius.circular(compact ? 15 : 17),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Target Date",
          hintText: "Optional",
          prefixIcon: Icon(
            Icons.calendar_month_rounded,
            size: compact ? 20 : 22,
          ),
          prefixIconColor: hasDate
              ? primary
              : theme.colorScheme.onSurface.withOpacity(.65),
          suffixIcon: hasDate
              ? IconButton(
                  tooltip: "Clear date",
                  onPressed: isLoading ? null : clearTargetDate,
                  icon: const Icon(Icons.close_rounded),
                )
              : const Icon(Icons.chevron_right_rounded),
          filled: true,
          fillColor: theme.colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(compact ? 15 : 17),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(compact ? 15 : 17),
            borderSide: BorderSide(color: theme.dividerColor.withOpacity(.55)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(compact ? 15 : 17),
            borderSide: BorderSide(color: primary, width: 1.5),
          ),
          floatingLabelStyle: TextStyle(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 15 : 17,
          ),
        ),
        child: Text(
          hasDate ? formatDate(selectedTargetDate!) : "No deadline set",
          style: TextStyle(
            color: hasDate
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface.withOpacity(.55),
            fontSize: compact ? 14 : 15,
            fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget buildHero() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary.withOpacity(.12), primary.withOpacity(.045)],
        ),
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: primary.withOpacity(.10)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 58 : 68,
            height: compact ? 58 : 68,
            decoration: BoxDecoration(
              color: primary.withOpacity(.13),
              borderRadius: BorderRadius.circular(compact ? 17 : 20),
            ),
            child: Icon(
              Icons.flag_rounded,
              color: primary,
              size: compact ? 29 : 34,
            ),
          ),

          SizedBox(width: compact ? 14 : 17),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Build toward something meaningful",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 15 : 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Set a target, choose a deadline, and track your progress.",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(.68),
                    fontSize: compact ? 11.5 : 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGoalPreview() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final goalTitle = titleController.text.trim().isEmpty
        ? "Your Goal"
        : titleController.text.trim();

    final amount = double.tryParse(amountController.text) ?? 0;

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: theme.dividerColor.withOpacity(.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: compact ? 18 : 20,
                color: primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Goal Preview",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 14 : 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "0% complete",
                  style: TextStyle(
                    color: primary,
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 18 : 21),

          Text(
            goalTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 20 : 24,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "KES ${formatAmount(amount)}",
            style: theme.textTheme.headlineSmall?.copyWith(
              color: primary,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 23 : 28,
            ),
          ),

          if (selectedTargetDate != null) ...[
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  size: compact ? 16 : 18,
                  color: theme.colorScheme.onSurface.withOpacity(.60),
                ),
                const SizedBox(width: 7),
                Text(
                  "Target date: ${formatDate(selectedTargetDate!)}",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(.68),
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: compact ? 16 : 19),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: 0,
              minHeight: compact ? 7 : 8,
              backgroundColor: primary.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation<Color>(primary),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Start saving to track your progress",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(.55),
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormCard() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: theme.dividerColor.withOpacity(.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildSectionTitle(
            title: "Goal Details",
            subtitle: "Enter the details for your savings goal.",
          ),

          SizedBox(height: compact ? 16 : 19),

          buildInputField(
            controller: titleController,
            label: "Goal Title",
            icon: Icons.flag_outlined,
            textInputAction: TextInputAction.next,
          ),

          SizedBox(height: compact ? 11 : 14),

          buildInputField(
            controller: amountController,
            label: "Target Amount",
            icon: Icons.account_balance_wallet_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixText: "KES ",
            textInputAction: TextInputAction.next,
          ),

          SizedBox(height: compact ? 11 : 14),

          buildTargetDateField(),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "A target date is optional. You can add one to receive deadline reminders.",
              style: TextStyle(
                color: theme.textTheme.bodySmall?.color?.withOpacity(.58),
                fontSize: compact ? 10.5 : 11.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTipCard() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.07),
        borderRadius: BorderRadius.circular(compact ? 16 : 19),
        border: Border.all(color: Colors.blue.withOpacity(.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 34 : 38,
            height: compact ? 34 : 38,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.blue,
              size: compact ? 18 : 20,
            ),
          ),

          SizedBox(width: compact ? 10 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Savings tip",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Set a realistic target and update your progress regularly to stay motivated.",
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(.62),
                    fontSize: compact ? 11 : 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCreateButton() {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final theme = Theme.of(context);

    final hasRequiredFields =
        titleController.text.trim().isNotEmpty &&
        amountController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: compact ? 54 : 58,
      child: ElevatedButton(
        onPressed: isLoading || !hasRequiredFields ? null : saveGoal,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(.28),
          disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? Row(
                  key: const ValueKey("loading"),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: compact ? 20 : 22,
                      height: compact ? 20 : 22,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Creating Goal...",
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey("create"),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_task_rounded, size: 21),
                    const SizedBox(width: 9),
                    Text(
                      "Create Goal",
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
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
        ? 28.0
        : 20.0;

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

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
              compact ? 16 : 24,
              horizontalPadding,
              compact ? 24 : 30,
            ),

            children: [
              Text(
                "Create a Goal",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 25 : 30,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Turn your plans into measurable savings targets.",
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withOpacity(.62),
                  fontSize: compact ? 13 : 15,
                  height: 1.4,
                ),
              ),

              SizedBox(height: compact ? 18 : sectionSpacing),

              buildHero(),

              SizedBox(height: compact ? 18 : sectionSpacing),

              buildGoalPreview(),

              SizedBox(height: compact ? 18 : sectionSpacing),

              buildFormCard(),

              SizedBox(height: compact ? 16 : sectionSpacing),

              buildTipCard(),

              SizedBox(height: compact ? 18 : 22),

              buildCreateButton(),

              SizedBox(height: compact ? 10 : 16),
            ],
          ),
        ),
      ),
    );
  }
}
