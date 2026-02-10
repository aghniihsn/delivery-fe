import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:praktikum_1/core/services/api_services.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final ApiService _apiService = ApiService();
  Timer? _locationTimer;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  /// Check & request location permissions
  Future<bool> ensurePermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Geolocator error: $e');
      return false;
    }
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await ensurePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Fallback: try last known position
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          debugPrint(
            'Using last known position: ${last.latitude}, ${last.longitude}',
          );
          return last;
        }
      } catch (_) {}
      return null;
    }
  }

  /// Start sending location to backend every [intervalSeconds]
  void startTracking({int intervalSeconds = 10}) {
    if (_isTracking) return;
    _isTracking = true;

    // Send immediately
    _sendLocation();

    // Then periodically
    _locationTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => _sendLocation(),
    );
    debugPrint('Location tracking started (interval: ${intervalSeconds}s)');
  }

  /// Stop sending location
  void stopTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isTracking = false;
    debugPrint('Location tracking stopped');
  }

  Future<void> _sendLocation() async {
    try {
      final position = await getCurrentPosition();
      if (position != null) {
        await _apiService.updateMyLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        debugPrint(
          'Location sent: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      debugPrint('Failed to send location: $e');
    }
  }
}