import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/profile_service.dart';
import '../services/ride_service.dart';
import '../services/location_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.client.auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session ?? SupabaseService.client.auth.currentSession;
});

final currentUserProvider = Provider<User?>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  return authStateAsync.value?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(supabaseClientProvider));
});

final rideServiceProvider = Provider<RideService>((ref) {
  return RideService(ref.watch(supabaseClientProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

class OnlineStatusNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Initial state is false, but we should sync it in HomeScreen
    return false;
  }

  void set(bool value) {
    state = value;
  }

  Future<void> syncFromDb(String userId) async {
    try {
      final driver = await ref.read(profileServiceProvider).getDriverDetails(userId);
      if (driver != null) {
        state = driver['is_online'] ?? false;
      }
    } catch (_) {
      // Fail silently, keep local state
    }
  }

  void toggle(bool value) {
    state = value;
  }
}

final onlineStatusProvider = NotifierProvider<OnlineStatusNotifier, bool>(() {
  return OnlineStatusNotifier();
});

final driverDetailsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  return ref.read(profileServiceProvider).getDriverDetails(userId);
});

final profileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  return ref.read(profileServiceProvider).getProfile(userId);
});

final driverStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ref.read(profileServiceProvider).getDriverStats(userId);
});

final driverRidesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return ref.read(rideServiceProvider).getDriverRides(userId);
});

final driverVehiclesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  return ref.read(profileServiceProvider).getVehicles(userId);
});
