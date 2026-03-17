import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/tracking_providers.dart';
import '../../core/providers/ride_providers.dart';

class ActiveRideScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String driverId;

  const ActiveRideScreen({
    super.key,
    required this.rideId,
    required this.driverId,
  });

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _userLocation;
  String _etaText = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint('Error getting user location: $e');
    }
  }

  /// Calculate ETA based on distance between driver and user
  void _calculateETA(LatLng driverLocation) {
    if (_userLocation == null) {
      setState(() => _etaText = 'Calculating...');
      return;
    }

    // Calculate distance in meters using Geolocator
    final distanceInMeters = Geolocator.distanceBetween(
      driverLocation.latitude,
      driverLocation.longitude,
      _userLocation!.latitude,
      _userLocation!.longitude,
    );

    // Estimate time based on average speed (30 km/h in city)
    final distanceInKm = distanceInMeters / 1000;
    final timeInMinutes = (distanceInKm / 30 * 60).round();

    if (timeInMinutes < 1) {
      setState(() => _etaText = 'Arriving now');
    } else if (timeInMinutes == 1) {
      setState(() => _etaText = 'Arriving in 1 min');
    } else {
      setState(() => _etaText = 'Arriving in $timeInMinutes mins');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    final driverLocationAsync = ref.watch(driverLocationProvider(widget.driverId));
    final rideAsync = ref.watch(rideByIdProvider(widget.rideId));

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          driverLocationAsync.when(
            data: (location) {
              if (location != null) {
                _markers.add(
                  Marker(
                    markerId: const MarkerId('driver'),
                    position: location,
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                    infoWindow: const InfoWindow(title: 'Driver is here'),
                  ),
                );

                // Calculate ETA
                _calculateETA(location);

                // Animating camera to driver
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(location, 15),
                );
              }

              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: location ?? const LatLng(20.5937, 78.9629), // Default India
                  zoom: 15,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),

          // Top Header Overlay
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  Icons.arrow_back,
                  onTap: () => context.pop(),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.security, size: 16, color: AppColors.accentCoral),
                      SizedBox(width: 8),
                      Text(
                        'Ride Protected',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildCircleButton(
                  Icons.sos,
                  color: AppColors.accentCoral,
                  onTap: () {
                    // SOS Logic
                  },
                ),
              ],
            ),
          ),

          // Bottom Info Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      rideAsync.when(
                        data: (ride) {
                          final driver = ride?['profiles'] as Map<String, dynamic>?;
                          return CircleAvatar(
                            radius: 25,
                            backgroundColor: AppColors.accentCoral,
                            backgroundImage: driver?['avatar_url'] != null
                                ? NetworkImage(driver!['avatar_url'])
                                : null,
                            child: driver?['avatar_url'] == null
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          );
                        },
                        loading: () => const CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.accentCoral,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        error: (_, _) => const CircleAvatar(
                          radius: 25,
                          backgroundColor: AppColors.accentCoral,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Driver is on the way',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _etaText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildActionCircle(Icons.message, onTap: () {}),
                      const SizedBox(width: 12),
                      _buildActionCircle(Icons.call, onTap: () {}),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 32),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.accentCoral, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: rideAsync.when(
                          data: (ride) => Text(
                            'Meeting Point: ${ride?['origin_name'] ?? 'Loading...'}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Text(
                            'Loading meeting point...',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          error: (_, _) => const Text(
                            'Meeting point unavailable',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Cancel Logic
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Cancel Ride'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, {VoidCallback? onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, color: color != null ? Colors.white : AppColors.surfaceDark, size: 24),
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
