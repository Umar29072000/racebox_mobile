import 'package:equatable/equatable.dart';
import '../../../domain/models/discipline_type.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();
  @override
  List<Object?> get props => [];
}

class LoadHistorySessions extends HistoryEvent {
  final DisciplineType? filterDiscipline;
  final String? filterVehicleId;

  const LoadHistorySessions({this.filterDiscipline, this.filterVehicleId});

  @override
  List<Object?> get props => [filterDiscipline, filterVehicleId];
}

class DeleteHistorySession extends HistoryEvent {
  final String sessionId;
  const DeleteHistorySession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
