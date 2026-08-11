import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../utils/responsive_helper.dart';

class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return SwitchListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 14 : 18,
              vertical: isCompact ? 2 : 4,
            ),

            secondary: Container(
              width: isCompact ? 38 : 42,
              height: isCompact ? 38 : 42,
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(.10),
                borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
              ),
              child: Icon(
                Icons.dark_mode_outlined,
                color: Colors.indigo,
                size: isCompact ? 20 : 21,
              ),
            ),

            title: Text(
              'Dark Mode',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: isCompact ? 14 : null,
                fontWeight: FontWeight.w700,
              ),
            ),

            subtitle: Padding(
              padding: EdgeInsets.only(top: isCompact ? 2 : 3),
              child: Text(
                'Switch between light and dark appearance.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: isCompact ? 11 : null,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
            ),

            value: themeProvider.isDarkMode,

            activeColor: colorScheme.primary,

            onChanged: themeProvider.toggleTheme,
          );
        },
      ),
    );
  }
}
