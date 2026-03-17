import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_providers.dart';
import '../services/ride_service.dart';

final rideServiceProvider = Provider<RideService>((ref) {
  return RideService(ref.watch(supabaseClientProvider));
});

int _callCount = 0;
final availableRidesProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, destination) async {
  _callCount++;
  debugPrint('availableRidesProvider: Call #$_callCount for destination: $destination');

  final rideService = ref.watch(rideServiceProvider);
  return await rideService.getAvailableRides(
    destQuery: destination,
  );
});

final userRidesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final rideService = ref.watch(rideServiceProvider);
  return await rideService.getDriverRides(user.id);
});

/// Provider to fetch a single ride by its ID with driver and vehicle details
final rideByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, rideId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('rides')
      .select('''
        *,
        profiles:driver_id (
          full_name,
          avatar_url,
          trust_score,
          phone_number,
          last_lat_lng
        ),
        vehicles:vehicle_id (
          make,
          model,
          plate_number
        )
      ''')
      .eq('id', rideId)
      .maybeSingle();

  return response;
});

/// Provider to fetch a single ride request by its ID with driver details
final rideRequestByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, requestId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('ride_requests')
      .select('''
        *,
        profiles:driver_id (
          full_name,
          avatar_url,
          trust_score,
          phone_number,
          last_lat_lng
        )
      ''')
      .eq('id', requestId)
      .maybeSingle();

  return response;
});
