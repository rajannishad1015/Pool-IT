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

final mockAvailableRidesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return [
    {
      'id': 'mock-1',
      'origin_name': 'Mock Origin',
      'destination_name': 'Mock Destination',
      'departure_time': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
      'seats_available': 3,
      'base_fare': 100.0,
      'profiles': {'full_name': 'Mock Driver', 'trust_score': 4.8},
    }
  ];
});
