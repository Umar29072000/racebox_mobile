import '../../domain/models/discipline_type.dart';
import '../../domain/models/race_session.dart';
import '../../domain/models/telemetry_point.dart';
import '../../domain/repositories/race_session_repository.dart';
import '../datasources/database/app_database.dart';

class RaceSessionRepositoryImpl implements RaceSessionRepository {
  final AppDatabase _dbProvider;

  RaceSessionRepositoryImpl([AppDatabase? dbProvider])
      : _dbProvider = dbProvider ?? AppDatabase();

  @override
  Future<void> saveRaceSession(RaceSession session) async {
    final db = await _dbProvider.database;

    await db.transaction((txn) async {
      await txn.insert(
        'RaceSessions',
        session.toMap(),
      );

      final batch = txn.batch();
      for (final sample in session.telemetrySamples) {
        batch.insert('TelemetrySamples', sample.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<List<RaceSession>> getAllSessions({
    DisciplineType? discipline,
    String? vehicleId,
  }) async {
    final db = await _dbProvider.database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (discipline != null && vehicleId != null) {
      whereClause = 'disciplineType = ? AND vehicleId = ?';
      whereArgs = [discipline.name, vehicleId];
    } else if (discipline != null) {
      whereClause = 'disciplineType = ?';
      whereArgs = [discipline.name];
    } else if (vehicleId != null) {
      whereClause = 'vehicleId = ?';
      whereArgs = [vehicleId];
    }

    final maps = await db.query(
      'RaceSessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'createdAt DESC',
    );

    return maps.map((m) => RaceSession.fromMap(m)).toList();
  }

  @override
  Future<RaceSession?> getSessionById(String sessionId) async {
    final db = await _dbProvider.database;

    final maps = await db.query(
      'RaceSessions',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (maps.isEmpty) return null;

    final samples = await getTelemetryPoints(sessionId);
    return RaceSession.fromMap(maps.first, samples: samples);
  }

  @override
  Future<List<TelemetryPoint>> getTelemetryPoints(String sessionId) async {
    final db = await _dbProvider.database;

    final maps = await db.query(
      'TelemetrySamples',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'elapsedMs ASC',
    );

    return maps.map((m) => TelemetryPoint.fromMap(m)).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final db = await _dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete(
        'TelemetrySamples',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
      await txn.delete(
        'RaceSessions',
        where: 'sessionId = ?',
        whereArgs: [sessionId],
      );
    });
  }

  @override
  Future<RaceSession?> getBestSession(
    DisciplineType discipline, {
    String? vehicleId,
  }) async {
    final db = await _dbProvider.database;

    String whereClause = 'disciplineType = ? AND isValidSlope = 1';
    List<dynamic> whereArgs = [discipline.name];

    if (vehicleId != null) {
      whereClause += ' AND vehicleId = ?';
      whereArgs.add(vehicleId);
    }

    final maps = await db.query(
      'RaceSessions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'finalTimeSec ASC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return RaceSession.fromMap(maps.first);
  }

  @override
  Future<String> exportSessionToCsv(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('Elapsed_ms,Time_sec,Speed_kmh,Distance_m,LinearAccel_G,Latitude,Longitude,Altitude_m,Timestamp');

    for (final s in session.telemetrySamples) {
      buffer.writeln(
        '${s.elapsedMs},'
        '${(s.elapsedMs / 1000.0).toStringAsFixed(3)},'
        '${s.speedKmh.toStringAsFixed(2)},'
        '${s.distanceMeters.toStringAsFixed(2)},'
        '${s.linearAccelG.toStringAsFixed(3)},'
        '${s.latitude.toStringAsFixed(7)},'
        '${s.longitude.toStringAsFixed(7)},'
        '${s.altitude.toStringAsFixed(2)},'
        '${s.timestamp.toIso8601String()}',
      );
    }

    return buffer.toString();
  }
}
