import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_providers.dart';
import '../services/ride_service.dart';

final rideServiceProvider = Provider<RideService>((ref) {
  return RideService(ref.watch(supabaseClientProvider));
});

final availableRidesProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, String?>>((ref, params) async {
  final rideService = ref.watch(rideServiceProvider);
  return await rideService.getAvailableRides(
    originQuery: params['origin'],
    destQuery: params['destination'],
  );
});

final userRidesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final rideService = ref.watch(rideServiceProvider);
  return await rideService.getDriverRides(user.id);
});
