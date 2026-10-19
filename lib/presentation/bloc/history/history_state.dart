import 'package:equatable/equatable.dart';
import '../../../domain/models/discipline_type.dart';
import '../../../domain/models/race_session.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<RaceSession> sessions;
  final RaceSession? bestSession;
  final DisciplineType? activeFilterDiscipline;
  final String? activeFilterVehicleId;

  const HistoryLoaded({
    required this.sessions,
    this.bestSession,
    this.activeFilterDiscipline,
    this.activeFilterVehicleId,
  });

  @override
  List<Object?> get props => [
        sessions,
        bestSession,
        activeFilterDiscipline,
        activeFilterVehicleId,
      ];
}

class HistoryError extends HistoryState {
  final String message;
  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
