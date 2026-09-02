import '../repositories/migration_repository.dart';
import 'api_services.dart';
import '../exceptions/auth_exception.dart';
import '../utils/migration_result.dart';

class MigrationService {
  MigrationService._();

  static final MigrationService instance = MigrationService._();

  final MigrationRepository migrationRepository = MigrationRepository.instance;

  Future<bool> hasGuestData() async {
    return await migrationRepository.hasGuestData();
  }

  Future<int> guestDataCount() async {
    return await migrationRepository.guestDataCount();
  }

  Future<MigrationResult> migrateGuestData(String userId) async {
    if (userId.trim().isEmpty) {
      throw AuthException(message: 'Invalid user account.');
    }

    final count = await migrationRepository.guestDataCount();

    if (count == 0) {
      return const MigrationResult(migrated: false, recordCount: 0);
    }

    final guestData = await migrationRepository.collectGuestData();

    final response = await ApiService.migrateGuestData(data: guestData);

    if (response['success'] != true) {
      throw AuthException(
        message:
            response['message']?.toString() ?? 'Guest data migration failed.',
      );
    }

    await migrationRepository.assignGuestDataToUser(userId);

    await migrationRepository.clearGuestSyncQueue();

    return MigrationResult(migrated: true, recordCount: count);
  }
}
