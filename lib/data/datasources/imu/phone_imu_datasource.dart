import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'imu_datasource.dart';

class PhoneImuDataSource implements ImuDataSource {
  StreamController<ImuReading>? _controller;
  StreamSubscription<UserAccelerometerEvent>? _sub;

  @override
  Stream<ImuReading> get stream {
    _controller ??= StreamController<ImuReading>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _controller!.stream;
  }

  void _startListening() {
    _sub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.fastestInterval,
    ).listen(
      (event) {
        final reading = ImuReading(
          ax: event.x,
          ay: event.y,
          az: event.z,
          timestamp: DateTime.now(),
        );
        _controller?.add(reading);
      },
      onError: (err) {
        _controller?.addError(err);
      },
    );
  }

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _stopListening();
    _controller?.close();
    _controller = null;
  }
}
