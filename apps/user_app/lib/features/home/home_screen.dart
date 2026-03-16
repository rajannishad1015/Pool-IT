import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_providers.dart';
import '../../core/providers/map_providers.dart';
import 'widgets/home_bottom_panel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? mapController;
  final LatLng _defaultCenter = const LatLng(19.0760, 72.8777); // Mumbai
  LatLng? _deviceLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _fetchDeviceLocation();
  }

  Future<void> _fetchDeviceLocation() async {
    try {
      // On web, checkPermission() returns 'denied' until requestPermission() is called
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        debugPrint('Location: permission denied');
        return;
      }

      // Use simple getCurrentPosition without LocationSettings for web compatibility
      final pos = await Geolocator.getCurrentPosition();
      final latLng = LatLng(pos.latitude, pos.longitude);
      debugPrint('Location: Got position ${pos.latitude}, ${pos.longitude}');

      if (mounted) {
        setState(() => _deviceLocation = latLng);
        // Animate map to real location
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 14.0),
          ),
        );
        // Set origin in route provider
        ref.read(mapRouteProvider).setOrigin(latLng);
      }
    } catch (e) {
      debugPrint('Location ERROR: $e');
    }
  }

  final String _mapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#f5f5f5" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#616161" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#f5f5f5" } ] },
  { "featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [ { "color": "#bdbdbd" } ] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [ { "color": "#eeeeee" } ] },
  { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#757575" } ] },
  { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#ffffff" } ] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#dadada" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#c9c9c9" } ] }
]
''';

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    final profileAsync = ref.read(userProfileProvider);
    if (profileAsync.hasValue && profileAsync.value != null) {
      final profile = profileAsync.value!;
      if (profile['latitude'] != null && profile['longitude'] != null) {
        final loc = LatLng(
          (profile['latitude'] as num).toDouble(),
          (profile['longitude'] as num).toDouble(),
        );
        mapController?.animateCamera(CameraUpdate.newLatLng(loc));
        return;
      }
    }
    _generateNearbyDrivers(_deviceLocation ?? _defaultCenter);
  }

  void _generateNearbyDrivers(LatLng center) {
    setState(() {
      _markers = List.generate(5, (index) {
        return Marker(
          markerId: MarkerId('driver_$index'),
          position: LatLng(
            center.latitude + (0.002 * (index - 2)),
            center.longitude + (0.002 * (index % 2 == 0 ? 1 : -1)),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Nearby Driver'),
        );
      }).toSet();
    });
  }

  /// Called when route notifier changes — builds markers & polyline.
  void _buildRoute(RouteNotifier route) {
    if (!route.hasRoute) {
      // No route — show nearby driver pins
      _generateNearbyDrivers(_deviceLocation ?? _defaultCenter);
      setState(() => _polylines = {});
      return;
    }

    final origin = route.origin!;
    final dest = route.destination!;

    setState(() {
      _markers = {
        // Origin marker (green)
        Marker(
          markerId: const MarkerId('origin'),
          position: origin,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Your Location'),
          zIndexInt: 2,
        ),
        // Destination marker (red)
        Marker(
          markerId: const MarkerId('destination'),
          position: dest,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: route.destinationName ?? 'Destination'),
          zIndexInt: 2,
        ),
      };

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: [origin, dest],
          color: AppColors.accentCoral,
          width: 4,
          patterns: [PatternItem.dash(30), PatternItem.gap(15)],
        ),
      };
    });

    // Fit camera to show both pins with padding
    final bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < dest.latitude ? origin.latitude : dest.latitude,
        origin.longitude < dest.longitude ? origin.longitude : dest.longitude,
      ),
      northeast: LatLng(
        origin.latitude > dest.latitude ? origin.latitude : dest.latitude,
        origin.longitude > dest.longitude ? origin.longitude : dest.longitude,
      ),
    );
    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to profile location changes
    ref.listen<AsyncValue<Map<String, dynamic>?>>(userProfileProvider,
        (previous, next) {
      final profile = next.value;
      final prevProfile = previous?.value;
      final hasLocation =
          profile?['latitude'] != null && profile?['longitude'] != null;
      final prevHasLocation =
          prevProfile?['latitude'] != null && prevProfile?['longitude'] != null;

      if (hasLocation &&
          (prevProfile == null ||
              !prevHasLocation ||
              prevProfile['latitude'] != profile?['latitude'] ||
              prevProfile['longitude'] != profile?['longitude'])) {
        final loc = LatLng(
          (profile!['latitude'] as num).toDouble(),
          (profile['longitude'] as num).toDouble(),
        );
        mapController?.animateCamera(CameraUpdate.newLatLng(loc));
      }
    });

    // React to route state changes
    ref.listen<RouteNotifier>(mapRouteProvider, (_, next) {
      _buildRoute(next);
    });

    final routeState = ref.watch(mapRouteProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map (Full background)
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _deviceLocation ?? _defaultCenter,
                zoom: 13.0,
              ),
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: _markers,
              polylines: _polylines,
              style: _mapStyle,
            ),
          ),

          // 2. Top Navigation Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final profile = ref.watch(userProfileProvider).value;
                        final name = profile?['full_name'] ?? 'User';
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: profile?['avatar_url'] != null
                                  ? NetworkImage(profile!['avatar_url'])
                                  : null,
                              backgroundColor: Colors.orange[100],
                              child: profile?['avatar_url'] == null
                                  ? const Icon(Icons.person, color: Colors.orange)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Good morning,',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Icon(Icons.notifications, color: AppColors.primaryNavy),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Geocoding loading indicator
          if (routeState.isGeocoding)
            Positioned(
              top: 110,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentCoral,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Finding location...', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Map Controls (Zoom & Location)
          Positioned(
            right: 16,
            bottom: 270,
            child: Column(
              children: [
                _buildMapControl(
                  Icons.my_location_rounded,
                  () => _fetchDeviceLocation(),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMapControl(
                        Icons.add_rounded,
                        () => mapController?.animateCamera(CameraUpdate.zoomIn()),
                        isGrouped: true,
                        isTop: true,
                      ),
                      Container(width: 24, height: 1, color: Colors.grey[200]),
                      _buildMapControl(
                        Icons.remove_rounded,
                        () => mapController?.animateCamera(CameraUpdate.zoomOut()),
                        isGrouped: true,
                        isBottom: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Panel
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: HomeBottomPanel(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.accentCoral,
          unselectedItemColor: Colors.grey[400],
          currentIndex: 0,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (index) {
            if (index == 3) context.push('/wallet');
            if (index == 4) context.push('/profile');
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.directions_car), label: 'My Rides'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pool'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: 'Wallet'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControl(
    IconData icon,
    VoidCallback onTap, {
    bool isGrouped = false,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isGrouped
              ? BorderRadius.vertical(
                  top: isTop ? const Radius.circular(12) : Radius.zero,
                  bottom: isBottom ? const Radius.circular(12) : Radius.zero,
                )
              : BorderRadius.circular(12),
          boxShadow: isGrouped && !isTop
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Icon(icon, color: AppColors.primaryNavy, size: 20),
      ),
    );
  }
}
