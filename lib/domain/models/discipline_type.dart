enum DisciplineType {
  drag60ft,
  drag100m,
  drag201m,
  drag402m,
  sprint0To100,
}

extension DisciplineTypeExtension on DisciplineType {
  String get displayName {
    switch (this) {
      case DisciplineType.drag60ft:
        return '60 FEET (18.28m)';
      case DisciplineType.drag100m:
        return 'DRAG 100 METER';
      case DisciplineType.drag201m:
        return 'DRAG 201 METER (1/8 MILE)';
      case DisciplineType.drag402m:
        return 'DRAG 402 METER (1/4 MILE)';
      case DisciplineType.sprint0To100:
        return 'SPRINT 0 - 100 KM/JAM';
    }
  }

  String get shortCode {
    switch (this) {
      case DisciplineType.drag60ft:
        return '60FT';
      case DisciplineType.drag100m:
        return '100M';
      case DisciplineType.drag201m:
        return '201M';
      case DisciplineType.drag402m:
        return '402M';
      case DisciplineType.sprint0To100:
        return '0-100';
    }
  }

  double? get targetDistanceMeters {
    switch (this) {
      case DisciplineType.drag60ft:
        return 18.288;
      case DisciplineType.drag100m:
        return 100.0;
      case DisciplineType.drag201m:
        return 201.0;
      case DisciplineType.drag402m:
        return 402.0;
      case DisciplineType.sprint0To100:
        return null;
    }
  }

  double? get targetSpeedKmh {
    switch (this) {
      case DisciplineType.sprint0To100:
        return 100.0;
      default:
        return null;
    }
  }

  bool get isSpeedBased => targetSpeedKmh != null;
  bool get isDistanceBased => targetDistanceMeters != null;

  static DisciplineType fromString(String val) {
    return DisciplineType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => DisciplineType.drag201m,
    );
  }
}
