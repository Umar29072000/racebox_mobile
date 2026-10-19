import '../models/race_session.dart';
import '../models/telemetry_point.dart';
import '../models/discipline_type.dart';

abstract class RaceSessionRepository {
  Future<void> saveRaceSession(RaceSession session);
  Future<List<RaceSession>> getAllSessions({DisciplineType? discipline, String? vehicleId});
  Future<RaceSession?> getSessionById(String sessionId);
  Future<List<TelemetryPoint>> getTelemetryPoints(String sessionId);
  Future<void> deleteSession(String sessionId);
  Future<RaceSession?> getBestSession(DisciplineType discipline, {String? vehicleId});
  Future<String> exportSessionToCsv(String sessionId);
}
