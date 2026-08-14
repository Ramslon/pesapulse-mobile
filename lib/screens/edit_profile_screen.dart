import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';
import '../services/guest_dialog_service.dart';
import '../widgets/auth_message_helper.dart';
import '../../utils/responsive_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final SettingsRepository _settingsRepository = SettingsRepository();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = await _settingsRepository.getProfile();

      if (!mounted) return;

      setState(() {
        nameController.text = user['name'] ?? '';
        emailController.text = user['email'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      AuthMessageHelper.showOffline(context);
    }
  }

  Future<void> updateProfile() async {
    if (await GuestDialogService.isGuest()) {
      if (!mounted) return;
      await GuestDialogService.show(context);
      return;
    }

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await _settingsRepository.updateProfile(
        nameController.text.trim(),
        emailController.text.trim(),
      );

      if (!mounted) return;

      AuthMessageHelper.showSuccess(context, 'Profile updated successfully');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      AuthMessageHelper.showOffline(context);
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact
                ? 18
                : desktop
                ? 22
                : 20,
          ),
        ),
        elevation: 0,
      ),

      body: SafeArea(
        child: isLoading
            ? _buildLoadingState(
                context,
                horizontalPadding: horizontalPadding,
                contentMaxWidth: contentMaxWidth,
                compact: compact,
                landscape: landscape,
              )
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: landscape ? 12 : 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(
                            context,
                            compact: compact,
                            landscape: landscape,
                            tablet: tablet,
                            desktop: desktop,
                          ),

                          SizedBox(height: sectionSpacing),

                          _buildSectionTitle(
                            context,
                            icon: Icons.person_outline_rounded,
                            title: 'Personal Information',
                            compact: compact,
                          ),

                          SizedBox(height: spacing),

                          _buildNameField(
                            context,
                            compact: compact,
                            landscape: landscape,
                          ),

                          SizedBox(height: spacing),

                          _buildEmailField(
                            context,
                            compact: compact,
                            landscape: landscape,
                          ),

                          SizedBox(height: sectionSpacing),

                          _buildSaveButton(
                            context,
                            compact: compact,
                            landscape: landscape,
                            desktop: desktop,
                            colorScheme: colorScheme,
                          ),

                          SizedBox(height: landscape ? 16 : 30),

                          _buildSecurityHint(context, compact: compact),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final avatarSize = compact
        ? 34.0
        : desktop
        ? 58.0
        : tablet
        ? 52.0
        : 46.0;

    final iconSize = compact
        ? 24.0
        : desktop
        ? 38.0
        : tablet
        ? 34.0
        : 30.0;

    final padding = landscape
        ? 16.0
        : compact
        ? 18.0
        : desktop
        ? 28.0
        : 22.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(.82)],
        ),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),

          SizedBox(width: compact ? 12 : 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Information',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact
                        ? 15
                        : desktop
                        ? 19
                        : 17,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Keep your personal information up to date.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(.78),
                    height: 1.3,
                    fontSize: compact ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: compact ? 34 : 38,
          height: compact ? 34 : 38,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: compact ? 18 : 20,
            color: colorScheme.primary,
          ),
        ),

        SizedBox(width: compact ? 9 : 12),

        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 15 : 17,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(
    BuildContext context, {
    required bool compact,
    required bool landscape,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: nameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      style: TextStyle(fontSize: compact ? 13 : 15),
      decoration: InputDecoration(
        labelText: 'Full Name',
        hintText: 'Enter your full name',
        prefixIcon: const Icon(Icons.person_outline_rounded),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: landscape
              ? 10
              : compact
              ? 12
              : 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
      validator: (value) {
        final name = value?.trim() ?? '';

        if (name.isEmpty) {
          return 'Name is required';
        }

        if (name.length < 2) {
          return 'Name must be at least 2 characters';
        }

        return null;
      },
    );
  }

  Widget _buildEmailField(
    BuildContext context, {
    required bool compact,
    required bool landscape,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      style: TextStyle(fontSize: compact ? 13 : 15),
      decoration: InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email address',
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: landscape
              ? 10
              : compact
              ? 12
              : 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 15),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
      validator: (value) {
        final email = value?.trim() ?? '';

        if (email.isEmpty) {
          return 'Email is required';
        }

        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

        if (!emailRegex.hasMatch(email)) {
          return 'Enter a valid email address';
        }

        return null;
      },
    );
  }

  Widget _buildSaveButton(
    BuildContext context, {
    required bool compact,
    required bool landscape,
    required bool desktop,
    required ColorScheme colorScheme,
  }) {
    final height = landscape
        ? 46.0
        : compact
        ? 48.0
        : desktop
        ? 56.0
        : 52.0;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : updateProfile,
        icon: isSaving
            ? SizedBox(
                width: compact ? 16 : 19,
                height: compact ? 16 : 19,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.save_rounded, size: compact ? 18 : 21),
        label: Text(
          isSaving ? 'Saving...' : 'Save Changes',
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 13 : 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityHint(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.35),
        borderRadius: BorderRadius.circular(compact ? 12 : 15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: compact ? 18 : 20,
            color: theme.colorScheme.primary,
          ),

          SizedBox(width: compact ? 9 : 11),

          Expanded(
            child: Text(
              'Your profile information is used to personalize your PesaPulse experience.',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: compact ? 11 : 12,
                height: 1.4,
                color: theme.textTheme.bodySmall?.color?.withOpacity(.72),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(
    BuildContext context, {
    required double horizontalPadding,
    required double contentMaxWidth,
    required bool compact,
    required bool landscape,
  }) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: landscape ? 12 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            children: [
              Container(
                height: compact ? 90 : 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    .55,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 18 : 22),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                height: compact ? 54 : 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    .55,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 12 : 15),
                ),
              ),

              const SizedBox(height: 14),

              Container(
                height: compact ? 54 : 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    .55,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 12 : 15),
                ),
              ),

              const SizedBox(height: 24),

              Container(
                height: compact ? 48 : 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    .55,
                  ),
                  borderRadius: BorderRadius.circular(compact ? 13 : 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
