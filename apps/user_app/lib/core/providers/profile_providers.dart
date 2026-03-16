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
