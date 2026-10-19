import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Local Database for Offline-First Storage (FRD SEC-10)
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'racebox_telemetry.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Table 1: VehicleProfiles
        await db.execute('''
          CREATE TABLE VehicleProfiles (
            id TEXT PRIMARY KEY,
            vehicleName TEXT NOT NULL,
            kerbWeightKg REAL NOT NULL,
            sprocketOrRollerNote TEXT,
            isDefault INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Table 2: RaceSessions
        await db.execute('''
          CREATE TABLE RaceSessions (
            sessionId TEXT PRIMARY KEY,
            vehicleId TEXT,
            vehicleName TEXT NOT NULL,
            disciplineType TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            finalTimeSec REAL NOT NULL,
            trapSpeedKmh REAL NOT NULL,
            peakGForce REAL NOT NULL,
            slopePercent REAL NOT NULL,
            isValidSlope INTEGER NOT NULL,
            split60ftSec REAL,
            split100mSec REAL,
            split201mSec REAL,
            split402mSec REAL,
            split0To100Sec REAL,
            oneFootRolloutSec REAL,
            isRolloutApplied INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (vehicleId) REFERENCES VehicleProfiles(id) ON DELETE SET NULL
          )
        ''');

        // Table 3: TelemetrySamples
        await db.execute('''
          CREATE TABLE TelemetrySamples (
            sampleId INTEGER PRIMARY KEY AUTOINCREMENT,
            sessionId TEXT NOT NULL,
            elapsedMs INTEGER NOT NULL,
            speedKmh REAL NOT NULL,
            distanceMeters REAL NOT NULL,
            linearAccelG REAL NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            altitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY (sessionId) REFERENCES RaceSessions(sessionId) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_telemetry_session ON TelemetrySamples(sessionId);
        ''');

        // Seed default profile from FRD SEC-10
        await db.insert('VehicleProfiles', {
          'id': 'default-vario-160',
          'vehicleName': 'Vario 160 Bore-Up',
          'kerbWeightKg': 118.0,
          'sprocketOrRollerNote': 'Roller 12gr, Per CVT 1500 RPM, Throttle Body 32mm',
          'isDefault': 1,
        });
      },
    );
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
