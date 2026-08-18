import '../repositories/migration_repository.dart';
import 'api_services.dart';

class MigrationService {
  MigrationService._();

  static final MigrationService instance = MigrationService._();

  final MigrationRepository migrationRepository = MigrationRepository.instance;

  // Checks whether the device currently has guest data.
  Future<bool> hasGuestData() async {
    return await migrationRepository.hasGuestData();
  }

  // Returns the number of local guest records.
  Future<int> guestDataCount() async {
    return await migrationRepository.guestDataCount();
  }

  // Migrates the current guest data to the authenticated account.

  Future<void> migrateGuestData(String userId) async {
    if (userId.trim().isEmpty) {
      throw Exception('Invalid user account.');
    }

    final hasData = await migrationRepository.hasGuestData();

    if (!hasData) {
      return;
    }

    // ------------------------------------------------------------
    // STEP 1: Collect guest data from SQLite.
    // ------------------------------------------------------------

    final guestData = await migrationRepository.collectGuestData();

    // ------------------------------------------------------------
    // STEP 2: Send guest data to the authenticated Laravel account.
    //
    // ApiService uses the authentication token stored in
    // SharedPreferences.
    // ------------------------------------------------------------

    final response = await ApiService.migrateGuestData(
      ownerId: userId,
      data: guestData,
    );

    // ------------------------------------------------------------
    // STEP 3: Verify that the backend actually accepted the
    // migration before modifying local SQLite ownership.
    // ------------------------------------------------------------

    final success = response['success'] == true;

    if (!success) {
      throw Exception(response['message'] ?? 'Guest data migration failed.');
    }

    // ------------------------------------------------------------
    // STEP 4: Server migration succeeded.
    //
    // Now it is safe to associate the local records with the
    // authenticated user.
    // ------------------------------------------------------------

    await migrationRepository.assignGuestDataToUser(userId);

    // ------------------------------------------------------------
    // STEP 5: The old guest sync queue must NOT be replayed.
    //
    // The server already received the actual guest records during
    // migration. Replaying the old queue could create duplicates.
    // ------------------------------------------------------------

    await migrationRepository.clearGuestSyncQueue();
  }
}
