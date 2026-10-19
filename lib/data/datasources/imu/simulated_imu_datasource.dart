import 'dart:async';
import 'dart:math';
import 'imu_datasource.dart';

class SimulatedImuDataSource implements ImuDataSource {
  StreamController<ImuReading>? _controller;
  Timer? _timer;
  final Random _random = Random();

  bool _isLaunching = false;
  int _launchTicksLeft = 0;

  @override
  Stream<ImuReading> get stream {
    _controller ??= StreamController<ImuReading>.broadcast(
      onListen: _startSimulation,
      onCancel: _stopSimulation,
    );
    return _controller!.stream;
  }

  void _startSimulation() {
    // 100Hz = 10ms
    _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      double ax = (_random.nextDouble() - 0.5) * 0.4; // engine noise ~0.04G
      double ay = (_random.nextDouble() - 0.5) * 0.4;
      double az = (_random.nextDouble() - 0.5) * 0.4;

      if (_isLaunching && _launchTicksLeft > 0) {
        // High launch G-force: ~0.85G forward acceleration
        ax += 8.3 + (_random.nextDouble() * 0.5);
        _launchTicksLeft--;
        if (_launchTicksLeft <= 0) {
          _isLaunching = false;
        }
      }

      final reading = ImuReading(
        ax: ax,
        ay: ay,
        az: az,
        timestamp: DateTime.now(),
      );

      _controller?.add(reading);
    });
  }

  /// Triggers a launch spike (exceeding 0.15G for > 40ms)
  void simulateLaunchSpike() {
    _isLaunching = true;
    _launchTicksLeft = 15; // 15 ticks * 10ms = 150ms of strong acceleration
  }

  /// Triggers an engine revving spike without moving (vibration spike)
  void simulateEngineRev() {
    _isLaunching = true;
    _launchTicksLeft = 2; // only 2 ticks = 20ms (under the 40ms threshold!)
  }

  void _stopSimulation() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopSimulation();
    _controller?.close();
    _controller = null;
  }
}
