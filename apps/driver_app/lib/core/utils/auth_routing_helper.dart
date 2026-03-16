import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_providers.dart';

class AuthRoutingHelper {
  static Future<String> getNextRoute(WidgetRef ref, {User? user}) async {
    final currentUser = user ?? ref.read(currentUserProvider);
    if (currentUser == null) return '/welcome';

    final profileService = ref.read(profileServiceProvider);
    
    // 1. Check Profile
    final profile = await profileService.getProfile(currentUser.id);
    if (profile == null || profile['full_name'] == null) {
      return '/profile-setup';
    }

    // 2. Check Driver Details
    final driver = await profileService.getDriverDetails(currentUser.id);
    if (driver == null) {
      // If profile exists but no driver entry, they probably haven't started onboarding
      return '/aadhaar-verification';
    }

    // 3. Check Verification Status
    final status = driver['verification_status'];
    
    if (status == 'verified') {
      return '/main';
    } else if (status == 'pending') {
      return '/verification-pending';
    } else {
      // unverified or rejected -> send to onboarding starting point
      // (The screens could be improved to resume, but for now this is a safe restart)
      return '/aadhaar-verification';
    }
  }
}
