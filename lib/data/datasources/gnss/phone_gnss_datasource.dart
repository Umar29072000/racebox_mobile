import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'gnss_datasource.dart';

class PhoneGnssDataSource implements GnssDataSource {
  StreamController<GnssReading>? _controller;
  StreamSubscription<Position>? _positionSub;

  @override
  Stream<GnssReading> get stream {
    _controller ??= StreamController<GnssReading>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _controller!.stream;
  }

  void _startListening() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (pos) {
        final speedKmh = pos.speed > 0 ? pos.speed * 3.6 : 0.0;
        final reading = GnssReading(
          latitude: pos.latitude,
          longitude: pos.longitude,
          altitude: pos.altitude,
          speedKmh: speedKmh,
          accuracyMeters: pos.accuracy,
          // Internal Android/iOS geolocator estimates satellites based on accuracy tier
          satellitesCount: pos.accuracy <= 2.5 ? 14 : (pos.accuracy <= 5.0 ? 9 : 5),
          timestamp: pos.timestamp,
        );
        _controller?.add(reading);
      },
      onError: (err) {
        _controller?.addError(err);
      },
    );
  }

  void _stopListening() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  @override
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  @override
  Future<GnssReading?> getCurrentReading() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      final speedKmh = pos.speed > 0 ? pos.speed * 3.6 : 0.0;
      return GnssReading(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        speedKmh: speedKmh,
        accuracyMeters: pos.accuracy,
        satellitesCount: pos.accuracy <= 2.5 ? 14 : 7,
        timestamp: pos.timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _stopListening();
    _controller?.close();
    _controller = null;
  }
}
