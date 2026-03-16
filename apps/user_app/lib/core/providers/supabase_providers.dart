import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/profile_service.dart';
import '../services/wallet_service.dart';
import '../services/location_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return SupabaseService.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseService.client.auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  return SupabaseService.client.auth.currentSession;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseService.client.auth.currentUser;
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

final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService(ref.watch(supabaseClientProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref.watch(supabaseClientProvider));
});
