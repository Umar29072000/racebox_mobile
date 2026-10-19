import '../models/vehicle_profile.dart';

abstract class VehicleRepository {
  Future<List<VehicleProfile>> getVehicles();
  Future<VehicleProfile?> getDefaultVehicle();
  Future<void> saveVehicle(VehicleProfile vehicle);
  Future<void> setDefaultVehicle(String vehicleId);
  Future<void> deleteVehicle(String vehicleId);
}
