import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/vehicle_repository.dart';
import 'vehicle_event.dart';
import 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository vehicleRepo;

  VehicleBloc({required this.vehicleRepo})
      : super(VehicleLoading()) {
    on<LoadVehicles>(_onLoadVehicles);
    on<SaveVehicleProfile>(_onSaveVehicle);
    on<SetDefaultVehicleEvent>(_onSetDefaultVehicle);
    on<DeleteVehicleProfile>(_onDeleteVehicle);
  }

  Future<void> _onLoadVehicles(
    LoadVehicles event,
    Emitter<VehicleState> emit,
  ) async {
    emit(VehicleLoading());
    try {
      final vehicles = await vehicleRepo.getVehicles();
      final active = await vehicleRepo.getDefaultVehicle();
      emit(VehicleLoaded(vehicles: vehicles, activeVehicle: active));
    } catch (e) {
      emit(VehicleError('Failed to load vehicles: $e'));
    }
  }

  Future<void> _onSaveVehicle(
    SaveVehicleProfile event,
    Emitter<VehicleState> emit,
  ) async {
    try {
      await vehicleRepo.saveVehicle(event.vehicle);
      add(LoadVehicles());
    } catch (e) {
      emit(VehicleError('Failed to save vehicle: $e'));
    }
  }

  Future<void> _onSetDefaultVehicle(
    SetDefaultVehicleEvent event,
    Emitter<VehicleState> emit,
  ) async {
    try {
      await vehicleRepo.setDefaultVehicle(event.vehicleId);
      add(LoadVehicles());
    } catch (e) {
      emit(VehicleError('Failed to set default vehicle: $e'));
    }
  }

  Future<void> _onDeleteVehicle(
    DeleteVehicleProfile event,
    Emitter<VehicleState> emit,
  ) async {
    try {
      await vehicleRepo.deleteVehicle(event.vehicleId);
      add(LoadVehicles());
    } catch (e) {
      emit(VehicleError('Failed to delete vehicle: $e'));
    }
  }
}
