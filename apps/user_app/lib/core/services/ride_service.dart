import 'package:flutter/foundation.dart';
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
    }).select().single();

    return response['id'];
  }

  /// Get available rides
  Future<List<Map<String, dynamic>>> getAvailableRides({
    String? originQuery,
    String? destQuery,
  }) async {
    debugPrint('RideService: Fetching available rides with filters: origin=$originQuery, dest=$destQuery');
    try {
      // Simplified query without joins to test performance/hang
      var query = _client
          .from('rides')
          .select() // Removed joins
          .eq('status', 'scheduled')
          .gt('seats_available', 0)
          .gt('departure_time', DateTime.now().toIso8601String());

      if (originQuery != null && originQuery.isNotEmpty) {
        query = query.ilike('origin_name', '%$originQuery%');
      }
      if (destQuery != null && destQuery.isNotEmpty) {
        query = query.ilike('destination_name', '%$destQuery%');
      }

      final startTime = DateTime.now();
      // Add a timeout to ensure it doesn't hang forever
      final response = await query.order('departure_time').timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('RideService: Query timed out after 10s');
          throw 'Query timeout';
        },
      );
      
      final duration = DateTime.now().difference(startTime);
      debugPrint('RideService: Query completed in ${duration.inMilliseconds}ms, found ${response.length} rides');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stack) {
      debugPrint('RideService ERROR: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Book a ride
  Future<void> bookRide({
    required String rideId,
    required String passengerId,
    required int seats,
    required double fare,
  }) async {
    await _client.from('bookings').insert({
      'ride_id': rideId,
      'passenger_id': passengerId,
      'seats_booked': seats,
      'fare_paid': fare,
      'status': 'pending',
    });
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
}
