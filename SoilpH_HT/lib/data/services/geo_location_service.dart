import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/geo_location_data.dart';

class GeoLocationService {
  GeoLocationData _currentLocation = GeoLocationData.defaultFallback();
  GeoLocationData get currentLocation => _currentLocation;

  final _locationController = StreamController<GeoLocationData>.broadcast();
  Stream<GeoLocationData> get locationStream => _locationController.stream;

  StreamSubscription<Position>? _positionSubscription;
  bool _isServiceEnabled = false;
  bool get isServiceEnabled => _isServiceEnabled;

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  GeoLocationService() {
    initLocationTracking();
  }

  /// Initialize and start continuous GPS location tracking
  Future<void> initLocationTracking() async {
    try {
      _isServiceEnabled = await Geolocator.isLocationServiceEnabled();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[GeoLocationService] Location permission denied. Using baseline coordinates.');
        _emitLocation(GeoLocationData.defaultFallback());
        return;
      }

      // Initial fast location acquisition
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _updateFromPosition(lastKnown);
        }

        final current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        _updateFromPosition(current);
      } catch (e) {
        debugPrint('[GeoLocationService] Fast position acquisition error: $e');
      }

      // Continuous high-precision GPS stream (distance filter: 1 meter)
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );

      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _updateFromPosition(position);
        },
        onError: (e) {
          debugPrint('[GeoLocationService] Position stream error: $e');
        },
      );

      _isTracking = true;
    } catch (e) {
      debugPrint('[GeoLocationService] GPS initialization error: $e');
      _emitLocation(GeoLocationData.defaultFallback());
    }
  }

  void _updateFromPosition(Position pos) {
    final location = GeoLocationData(
      latitude: pos.latitude,
      longitude: pos.longitude,
      altitude: pos.altitude,
      accuracy: pos.accuracy,
      timestamp: pos.timestamp,
      isFallback: false,
    );
    _emitLocation(location);
  }

  void _emitLocation(GeoLocationData loc) {
    _currentLocation = loc;
    if (!_locationController.isClosed) {
      _locationController.add(loc);
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}
