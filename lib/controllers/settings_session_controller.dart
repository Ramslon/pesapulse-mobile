import '../repositories/settings_repository.dart';
import '../services/api_services.dart';
import '../services/session_service.dart';

class SettingsSessionController {
  final SettingsRepository settingsRepository;

  SettingsSessionController({required this.settingsRepository});

  Future<void> logout() async {
    await SessionService.logout();

    settingsRepository.clearCache();

    ApiService.logoutUser().catchError((_) {});
  }
}
