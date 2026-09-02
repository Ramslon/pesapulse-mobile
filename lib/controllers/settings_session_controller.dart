import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';
import '../services/api_services.dart';
import '../services/session_service.dart';
import '../exceptions/rate_limit_exception.dart';

class SettingsSessionController {
  final SettingsRepository settingsRepository;

  SettingsSessionController({required this.settingsRepository});

  Future<void> logout() async {
    try {
      await ApiService.logoutUser();
    } on RateLimitException catch (e) {
      debugPrint('Server logout rate limited: ${e.message}');
    } catch (e) {
      debugPrint('Server logout failed: $e');
    }

    await SessionService.logout();
    settingsRepository.clearCache();
  }
}
