import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  /// Get user profile
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  /// Add a vehicle
  Future<String> addVehicle({
    required String userId,
    required Map<String, dynamic> vehicleData,
  }) async {
    final response = await _client
        .from('vehicles')
        .insert({
          ...vehicleData,
          'owner_id': userId,
        })
        .select()
        .single();
    return response['id'];
  }

  Future<List<Map<String, dynamic>>> getVehicles(String userId) async {
    final response = await _client
        .from('vehicles')
        .select()
        .eq('owner_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
}
