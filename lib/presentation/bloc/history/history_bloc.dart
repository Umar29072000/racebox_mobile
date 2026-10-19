import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/race_session_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final RaceSessionRepository sessionRepo;

  HistoryBloc({required this.sessionRepo})
      : super(HistoryLoading()) {
    on<LoadHistorySessions>(_onLoadHistorySessions);
    on<DeleteHistorySession>(_onDeleteHistorySession);
  }

  Future<void> _onLoadHistorySessions(
    LoadHistorySessions event,
    Emitter<HistoryState> emit,
  ) async {
    emit(HistoryLoading());
    try {
      final sessions = await sessionRepo.getAllSessions(
        discipline: event.filterDiscipline,
        vehicleId: event.filterVehicleId,
      );

      final bestSession = event.filterDiscipline != null
          ? await sessionRepo.getBestSession(
              event.filterDiscipline!,
              vehicleId: event.filterVehicleId,
            )
          : (sessions.isNotEmpty ? sessions.first : null);

      emit(HistoryLoaded(
        sessions: sessions,
        bestSession: bestSession,
        activeFilterDiscipline: event.filterDiscipline,
        activeFilterVehicleId: event.filterVehicleId,
      ));
    } catch (e) {
      emit(HistoryError('Failed to load history: $e'));
    }
  }

  Future<void> _onDeleteHistorySession(
    DeleteHistorySession event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      await sessionRepo.deleteSession(event.sessionId);
      if (state is HistoryLoaded) {
        final current = state as HistoryLoaded;
        add(LoadHistorySessions(
          filterDiscipline: current.activeFilterDiscipline,
          filterVehicleId: current.activeFilterVehicleId,
        ));
      }
    } catch (e) {
      emit(HistoryError('Failed to delete session: $e'));
    }
  }
}
