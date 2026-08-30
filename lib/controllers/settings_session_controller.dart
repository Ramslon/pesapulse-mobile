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
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Server logout failed: $e');

      // Continue with local logout even if the API is unavailable.
    }

    await SessionService.logout();
    settingsRepository.clearCache();
  }
}
