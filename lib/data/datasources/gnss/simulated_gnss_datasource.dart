import 'dart:async';
import 'gnss_datasource.dart';

class SimulatedGnssDataSource implements GnssDataSource {
  StreamController<GnssReading>? _controller;
  Timer? _timer;

  double _currentSpeedKmh = 0.0;
  double _distanceMeters = 0.0;
  double _latitude = -6.291245; // Sentul International Circuit / Dragway coords
  double _longitude = 106.852418;
  double _altitude = 125.0;
  bool _isMoving = false;

  @override
  Stream<GnssReading> get stream {
    _controller ??= StreamController<GnssReading>.broadcast(
      onListen: _startSimulation,
      onCancel: _stopSimulation,
    );
    return _controller!.stream;
  }

  void _startSimulation() {
    // 5Hz GNSS tick (every 200ms)
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isMoving) {
        // Accelerate up to ~118 km/h then decelerate to 0 after 220m
        if (_distanceMeters < 210.0) {
          _currentSpeedKmh = (_currentSpeedKmh + 5.2).clamp(0.0, 120.0);
        } else {
          // Braking
          _currentSpeedKmh = (_currentSpeedKmh - 12.0).clamp(0.0, 120.0);
          if (_currentSpeedKmh <= 0.0) {
            _isMoving = false;
          }
        }

        // Distance delta: speed (m/s) * 0.2s
        final speedMps = _currentSpeedKmh / 3.6;
        final deltaDistance = speedMps * 0.2;
        _distanceMeters += deltaDistance;

        // Move coordinates northwards (1 degree lat ≈ 111,000m)
        _latitude += (deltaDistance / 111000.0);
        // Slight slope: -0.3%
        _altitude -= (deltaDistance * 0.003);
      }

      final reading = GnssReading(
        latitude: _latitude,
        longitude: _longitude,
        altitude: _altitude,
        speedKmh: _currentSpeedKmh,
        accuracyMeters: 1.2, // High precision <= 2.5m
        satellitesCount: 14, // Satellites >= 8
        timestamp: DateTime.now(),
      );

      _controller?.add(reading);
    });
  }

  /// Triggers a launch in the simulator
  void simulateLaunch() {
    _isMoving = true;
    _currentSpeedKmh = 1.5;
  }

  /// Triggers false start (movement under 3 km/h then stop)
  void simulateFalseStart() {
    _isMoving = true;
    _currentSpeedKmh = 1.2;
    Timer(const Duration(milliseconds: 800), () {
      _currentSpeedKmh = 0.0;
      _isMoving = false;
    });
  }

  void resetPosition() {
    _currentSpeedKmh = 0.0;
    _distanceMeters = 0.0;
    _isMoving = false;
    _latitude = -6.291245;
    _longitude = 106.852418;
    _altitude = 125.0;
  }

  void _stopSimulation() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<GnssReading?> getCurrentReading() async {
    return GnssReading(
      latitude: _latitude,
      longitude: _longitude,
      altitude: _altitude,
      speedKmh: _currentSpeedKmh,
      accuracyMeters: 1.2,
      satellitesCount: 14,
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _stopSimulation();
    _controller?.close();
    _controller = null;
  }
}
