import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  /// Upload an avatar image
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = '$userId/$fileName';
    
    await _client.storage.from('avatars').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from('avatars').getPublicUrl(path);
  }

  /// Upload a vehicle photo
  Future<String> uploadVehiclePhoto({
    required String userId,
    required String vehicleId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = '$userId/$vehicleId/$fileName';
    
    await _client.storage.from('vehicle_photos').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from('vehicle_photos').getPublicUrl(path);
  }

  /// Upload a document (Aadhaar, DL, RC, etc.)
  Future<String> uploadDocument({
    required String userId,
    required String docType,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final extension = fileName.split('.').last;
    final uniqueFileName = '${docType}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '$userId/$uniqueFileName';
    
    await _client.storage.from('documents').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from('documents').getPublicUrl(path);
  }
}
