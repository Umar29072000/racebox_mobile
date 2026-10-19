import '../../domain/models/vehicle_profile.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/database/app_database.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final AppDatabase _dbProvider;

  VehicleRepositoryImpl([AppDatabase? dbProvider])
      : _dbProvider = dbProvider ?? AppDatabase();

  @override
  Future<List<VehicleProfile>> getVehicles() async {
    final db = await _dbProvider.database;
    final maps = await db.query('VehicleProfiles', orderBy: 'isDefault DESC, vehicleName ASC');
    return maps.map((m) => VehicleProfile.fromMap(m)).toList();
  }

  @override
  Future<VehicleProfile?> getDefaultVehicle() async {
    final db = await _dbProvider.database;
    final maps = await db.query(
      'VehicleProfiles',
      where: 'isDefault = 1',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return VehicleProfile.fromMap(maps.first);
    }
    // Fallback to first vehicle if none marked default
    final all = await db.query('VehicleProfiles', limit: 1);
    if (all.isNotEmpty) {
      return VehicleProfile.fromMap(all.first);
    }
    return null;
  }

  @override
  Future<void> saveVehicle(VehicleProfile vehicle) async {
    final db = await _dbProvider.database;
    await db.insert(
      'VehicleProfiles',
      vehicle.toMap(),
      conflictAlgorithm: null, // Let SQLite handle upsert or replace
    );
  }

  @override
  Future<void> setDefaultVehicle(String vehicleId) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.update('VehicleProfiles', {'isDefault': 0});
      await txn.update(
        'VehicleProfiles',
        {'isDefault': 1},
        where: 'id = ?',
        whereArgs: [vehicleId],
      );
    });
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    final db = await _dbProvider.database;
    await db.delete(
      'VehicleProfiles',
      where: 'id = ?',
      whereArgs: [vehicleId],
    );
  }
}
