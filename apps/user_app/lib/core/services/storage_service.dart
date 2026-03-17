import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  /// Upload an avatar image
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final extension = imageFile.path.split('.').last;
    final path = '$userId/avatar.$extension';
    
    await _client.storage.from('avatars').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Upload a vehicle photo
  Future<String> uploadVehiclePhoto({
    required String userId,
    required String vehicleId,
    required File imageFile,
  }) async {
    final extension = imageFile.path.split('.').last;
    final path = '$userId/$vehicleId.$extension';
    
    await _client.storage.from('vehicle_photos').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from('vehicle_photos').getPublicUrl(path);
  }

  /// Upload an ID Document
  Future<String> uploadDocument({
    required String userId,
    required String docType,
    required File imageFile,
  }) async {
    final extension = imageFile.path.split('.').last;
    final path = '$userId/${docType}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    
    await _client.storage.from('documents').upload(
      path,
      imageFile,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from('documents').getPublicUrl(path);
  }
}

