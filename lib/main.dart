import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request();

  await NotificationService.init();

  SyncService.instance.startListening();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'PesaPulse',

      themeMode: themeProvider.themeMode,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      builder: (context, child) {
        final media = MediaQuery.of(context);

        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              media.textScaler.scale(1).clamp(0.9, 1.2),
            ),
          ),
          child: child!,
        );
      },

      home: const SplashScreen(),
    );
  }
}
