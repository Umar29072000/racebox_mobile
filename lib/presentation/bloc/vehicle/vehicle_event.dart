import 'package:equatable/equatable.dart';
import '../../../domain/models/vehicle_profile.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
  @override
  List<Object?> get props => [];
}

class LoadVehicles extends VehicleEvent {}

class SaveVehicleProfile extends VehicleEvent {
  final VehicleProfile vehicle;
  const SaveVehicleProfile(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

class SetDefaultVehicleEvent extends VehicleEvent {
  final String vehicleId;
  const SetDefaultVehicleEvent(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}

class DeleteVehicleProfile extends VehicleEvent {
  final String vehicleId;
  const DeleteVehicleProfile(this.vehicleId);

  @override
  List<Object?> get props => [vehicleId];
}
