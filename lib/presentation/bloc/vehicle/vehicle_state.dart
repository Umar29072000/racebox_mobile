import 'package:equatable/equatable.dart';
import '../../../domain/models/vehicle_profile.dart';

abstract class VehicleState extends Equatable {
  const VehicleState();
  @override
  List<Object?> get props => [];
}

class VehicleLoading extends VehicleState {}

class VehicleLoaded extends VehicleState {
  final List<VehicleProfile> vehicles;
  final VehicleProfile? activeVehicle;

  const VehicleLoaded({
    required this.vehicles,
    this.activeVehicle,
  });

  @override
  List<Object?> get props => [vehicles, activeVehicle];
}

class VehicleError extends VehicleState {
  final String message;
  const VehicleError(this.message);

  @override
  List<Object?> get props => [message];
}
