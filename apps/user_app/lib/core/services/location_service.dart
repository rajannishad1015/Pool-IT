import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final SupabaseClient _client;

  LocationService(this._client);

  /// Request location permissions
  Future<bool> requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
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

  /// Get current position
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition();
  }

  /// Stream position updates
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Update user's live location in database
  Future<void> updateLiveLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _client.from('profiles').update({
        'last_lat_lng': '($latitude,$longitude)',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      // Handle or log error
    }
  }

  /// Get driver's live location stream
  Stream<List<Map<String, dynamic>>> getDriverLocationStream(String driverId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', driverId)
        .limit(1);
  }

  /// Get all online drivers with their locations
  Future<List<Map<String, dynamic>>> getOnlineDrivers() async {
    try {
      final response = await _client
          .from('drivers')
          .select('id, is_online, profiles:id(full_name, last_lat_lng)')
          .eq('is_online', true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Stream online drivers for real-time updates
  Stream<List<Map<String, dynamic>>> getOnlineDriversStream() {
    return _client
        .from('drivers')
        .stream(primaryKey: ['id'])
        .eq('is_online', true);
  }
}
