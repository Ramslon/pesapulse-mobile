import 'api_services.dart';

class PreferencesService {
  static Future<Map<String, dynamic>> load() async {
    return await ApiService.getPreferences();
  }
}
