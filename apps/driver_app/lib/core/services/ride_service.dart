import 'package:supabase_flutter/supabase_flutter.dart';

class RideService {
  final SupabaseClient _client;

  RideService(this._client);

  /// Create a new ride
  Future<String> createRide({
    required String driverId,
    required String vehicleId,
    required String originName,
    required double originLat,
    required double originLng,
    required String destinationName,
    required double destinationLat,
    required double destinationLng,
    required DateTime departureTime,
    required int seatsTotal,
    required double baseFare,
    Map<String, dynamic>? preferences,
  }) async {
    final response = await _client.from('rides').insert({
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'origin_name': originName,
      'origin_lat_lng': '($originLat, $originLng)',
      'destination_name': destinationName,
      'destination_lat_lng': '($destinationLat, $destinationLng)',
      'departure_time': departureTime.toIso8601String(),
      'seats_total': seatsTotal,
      'seats_available': seatsTotal,
      'base_fare': baseFare,
      'preferences': preferences,
      'status': 'scheduled',
    }).select().single();

    return response['id'];
  }

  /// Get driver's rides
  Future<List<Map<String, dynamic>>> getDriverRides(String driverId) async {
    final response = await _client
        .from('rides')
        .select('*, bookings(*)')
        .eq('driver_id', driverId)
        .order('departure_time', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update ride status
  Future<void> updateRideStatus(String rideId, String status) async {
    await _client
        .from('rides')
        .update({'status': status})
        .eq('id', rideId);
  }
}
