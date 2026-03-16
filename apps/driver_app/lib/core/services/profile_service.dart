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

  /// Update an existing vehicle
  Future<void> updateVehicle({
    required String vehicleId,
    required Map<String, dynamic> updates,
  }) async {
    await _client
        .from('vehicles')
        .update(updates)
        .eq('id', vehicleId);
  }

  /// Get vehicles for a user
  Future<List<Map<String, dynamic>>> getVehicles(String userId) async {
    final response = await _client
        .from('vehicles')
        .select()
        .eq('owner_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update driver document
  Future<void> updateDriverDoc({
    required String driverId,
    required String docType,
    required String filePath,
    Map<String, dynamic>? metadata,
  }) async {
    await _client.from('driver_documents').upsert({
      'driver_id': driverId,
      'doc_type': docType,
      'file_path': filePath,
      'status': 'pending',
      'metadata': metadata,
    }, onConflict: 'driver_id, doc_type');
  }

  /// Update bank details
  Future<void> updateBankDetails({
    required String userId,
    required Map<String, dynamic> bankData,
  }) async {
    await _client.from('bank_details').upsert({
      'user_id': userId,
      ...bankData,
    }, onConflict: 'user_id');
  }

  /// Update driver info
  Future<void> updateDriverInfo({
    required String driverId,
    required Map<String, dynamic> updates,
  }) async {
    await _client.from('drivers').upsert({
      'id': driverId,
      ...updates,
    }, onConflict: 'id');
  }

  /// Get driver details
  Future<Map<String, dynamic>?> getDriverDetails(String userId) async {
    final response = await _client
        .from('drivers')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Update driver location
  Future<void> updateLocation(String userId, double lat, double lng) async {
    await _client.from('profiles').update({
      'last_lat_lng': {'lat': lat, 'lng': lng},
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  /// Update online status
  Future<void> updateOnlineStatus(String driverId, bool isOnline) async {
    await _client.from('drivers').update({
      'is_online': isOnline,
      'last_online_at': isOnline ? DateTime.now().toIso8601String() : null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', driverId);
  }

  /// Get driver stats (Earnings, Rides count, Rating)
  Future<Map<String, dynamic>> getDriverStats(String userId) async {
    final driverData = await getDriverDetails(userId);
    final profileData = await getProfile(userId);
    
    // Get today's rides count
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final ridesResponse = await _client
        .from('rides')
        .select('id')
        .eq('driver_id', userId)
        .gte('departure_time', todayStart);
    
    final todayRidesCount = ridesResponse.length;

    return {
      'total_earnings': driverData?['total_earnings'] ?? 0.0,
      'today_rides': todayRidesCount,
      'rating': profileData?['trust_score'] ?? 5.0,
    };
  }
}
