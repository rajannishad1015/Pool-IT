import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'supabase_providers.dart';

/// Provider for user's current live location (Stream)
final userLocationStreamProvider = StreamProvider<Position>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getPositionStream();
});

/// Provider for driver's live location (Stream)
final driverLocationProvider = StreamProvider.family<LatLng?, String>((ref, driverId) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getDriverLocationStream(driverId).map((event) {
    if (event.isEmpty) return null;
    final profile = event.first;
    final lastLatLng = profile['last_lat_lng'] as String?;
    
    if (lastLatLng != null) {
      // Postgres point format: (latitude,longitude)
      final clean = lastLatLng.replaceAll('(', '').replaceAll(')', '');
      final coords = clean.split(',');
      if (coords.length == 2) {
        return LatLng(
          double.parse(coords[0]),
          double.parse(coords[1]),
        );
      }
    }
    return null;
  });
});

/// Background task to sync location to Supabase during a ride
final locationSyncProvider = Provider.family<void, String>((ref, userId) {
  ref.listen(userLocationStreamProvider, (previous, next) {
    final position = next.value;
    if (position != null) {
      ref.read(locationServiceProvider).updateLiveLocation(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }
  });
});
