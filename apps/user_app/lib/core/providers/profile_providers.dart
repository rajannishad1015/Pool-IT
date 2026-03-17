import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_providers.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final profileService = ref.watch(profileServiceProvider);
  return await profileService.getProfile(user.id);
});

final userVehiclesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final profileService = ref.watch(profileServiceProvider);
  return await profileService.getVehicles(user.id);
});

/// User stats provider - fetches ride count, calculates CO2 saved, money saved
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return {'rides': 0, 'co2Saved': 0.0, 'moneySaved': 0.0};
  }

  final supabase = ref.watch(supabaseClientProvider);

  // Count user's bookings (completed rides as passenger)
  final bookingsResponse = await supabase
      .from('bookings')
      .select('id, fare')
      .eq('passenger_id', user.id)
      .eq('status', 'confirmed');

  final bookings = List<Map<String, dynamic>>.from(bookingsResponse);
  final rideCount = bookings.length;

  // Calculate total fare spent on rides
  double totalFare = 0;
  for (final booking in bookings) {
    totalFare += (booking['fare'] as num?)?.toDouble() ?? 0;
  }

  // Estimate CO2 saved: average 2.3kg CO2 per ride (10km avg, 230g/km for car)
  // Carpooling typically saves ~50% CO2 vs solo driving
  final co2Saved = rideCount * 1.15; // kg

  // Estimate money saved: average taxi fare ~150 INR vs carpool ~60 INR
  final moneySaved = rideCount * 90.0; // INR saved per ride

  return {
    'rides': rideCount,
    'co2Saved': co2Saved,
    'moneySaved': moneySaved,
    'totalSpent': totalFare,
  };
});
