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

  /// Get Verification Status
  Future<String> getVerificationStatus(String userId) async {
    try {
      final response = await _client
          .from('driver_documents')
          .select('status')
          .eq('driver_id', userId)
          .inFilter('doc_type', ['aadhaar_front', 'dl_front', 'pancard_front'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (response == null) return 'unverified';
      return response['status'] as String;
    } catch (e) {
      return 'unverified';
    }
  }

  /// Submit ID Document for Verification
  Future<void> submitIdVerification({
    required String userId,
    required String docType,
    required String fileUrl,
  }) async {
    // Map user friendly docType to DB enum
    String dbDocType = 'aadhaar_front';
    if (docType == 'Driving Licence') dbDocType = 'dl_front';

    await _client.from('driver_documents').insert({
      'driver_id': userId,
      'doc_type': dbDocType,
      'file_path': fileUrl,
      'status': 'pending',
    });
  }
}

