import 'package:equatable/equatable.dart';

/// Vehicle Profile (FRD SEC-10: VehicleProfiles)
class VehicleProfile extends Equatable {
  final String id;
  final String vehicleName;
  final double kerbWeightKg;
  final String sprocketOrRollerNote;
  final bool isDefault;

  const VehicleProfile({
    required this.id,
    required this.vehicleName,
    required this.kerbWeightKg,
    required this.sprocketOrRollerNote,
    this.isDefault = false,
  });

  VehicleProfile copyWith({
    String? id,
    String? vehicleName,
    double? kerbWeightKg,
    String? sprocketOrRollerNote,
    bool? isDefault,
  }) {
    return VehicleProfile(
      id: id ?? this.id,
      vehicleName: vehicleName ?? this.vehicleName,
      kerbWeightKg: kerbWeightKg ?? this.kerbWeightKg,
      sprocketOrRollerNote: sprocketOrRollerNote ?? this.sprocketOrRollerNote,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleName': vehicleName,
      'kerbWeightKg': kerbWeightKg,
      'sprocketOrRollerNote': sprocketOrRollerNote,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory VehicleProfile.fromMap(Map<String, dynamic> map) {
    return VehicleProfile(
      id: map['id'] as String,
      vehicleName: map['vehicleName'] as String,
      kerbWeightKg: (map['kerbWeightKg'] as num).toDouble(),
      sprocketOrRollerNote: (map['sprocketOrRollerNote'] ?? '') as String,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleName,
        kerbWeightKg,
        sprocketOrRollerNote,
        isDefault,
      ];
}
