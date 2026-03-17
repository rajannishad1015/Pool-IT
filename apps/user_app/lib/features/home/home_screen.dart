import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/profile_providers.dart';
import '../../core/providers/map_providers.dart';
import '../../core/providers/tracking_providers.dart';
import '../../core/services/geocoding_service.dart';
import 'widgets/home_bottom_panel.dart';

/// Returns greeting based on current time
String getTimeBasedGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good morning,';
  } else if (hour < 17) {
    return 'Good afternoon,';
  } else {
    return 'Good evening,';
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? mapController;
  final LatLng _defaultCenter = const LatLng(19.0760, 72.8777); // Mumbai
  LatLng? _deviceLocation;
  String _currentLocationLabel = 'Detecting current location...';
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _isFetchingLocation = false;
  String _lastRouteSignature = '';

  String _routeSignature(RouteNotifier route) {
    final origin = route.origin;
    final destination = route.destination;
    return [
      origin?.latitude.toStringAsFixed(6) ?? 'none',
      origin?.longitude.toStringAsFixed(6) ?? 'none',
      destination?.latitude.toStringAsFixed(6) ?? 'none',
      destination?.longitude.toStringAsFixed(6) ?? 'none',
      route.routePoints.length.toString(),
    ].join('|');
  }

  @override
  void initState() {
    super.initState();
    _fetchDeviceLocation();
  }

  Future<void> _fetchDeviceLocation() async {
    if (_isFetchingLocation) return; // Prevent multiple calls

    setState(() => _isFetchingLocation = true);

    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied. Please enable it in settings.')),
          );
        }
        return;
      }
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required.')),
          );
        }
        return;
      }

      // Get current position with timeout
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      debugPrint('Location: Got position ${pos.latitude}, ${pos.longitude}');

      if (mounted) {
        setState(() {
          _deviceLocation = latLng;
          _currentLocationLabel = 'Fetching location name...';
        });
        // Animate map to real location
        mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15.0),
          ),
        );
        // Set origin in route provider
        ref.read(mapRouteProvider).setOrigin(latLng);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final placeLabel = await GeocodingService.reverseGeocodeLatLng(latLng);
      if (mounted) {
        setState(() {
          _currentLocationLabel =
              (placeLabel == null || placeLabel.trim().isEmpty)
                  ? 'Current Location'
                  : placeLabel;
        });
      }
    } catch (e) {
      debugPrint('Location ERROR: $e');
      if (mounted) {
        if (_deviceLocation != null) {
          setState(() => _currentLocationLabel = 'Current Location');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: ${e.toString().split(':').last}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
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
    _loadOnlineDrivers();
  }

  /// Fetch and display real online drivers from database
  Future<void> _loadOnlineDrivers() async {
    final driversAsync = await ref.read(onlineDriversProvider.future);
    if (driversAsync.isEmpty) {
      // No online drivers - show empty state
      setState(() => _markers = {});
      return;
    }

    final markers = <Marker>{};
    for (int i = 0; i < driversAsync.length; i++) {
      final driver = driversAsync[i];
      final profile = driver['profiles'] as Map<String, dynamic>?;
      final lastLatLng = profile?['last_lat_lng'] as String?;
      final driverName = profile?['full_name'] ?? 'Driver';

      final location = parseLatLng(lastLatLng);
      if (location != null) {
        markers.add(Marker(
          markerId: MarkerId('driver_${driver['id']}'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: driverName),
        ));
      }
    }

    if (mounted) {
      setState(() => _markers = markers);
    }
  }

  /// Called when route notifier changes — builds markers & polyline.
  void _buildRoute(RouteNotifier route) {
    if (!route.hasRoute) {
      // No route — show online drivers
      _loadOnlineDrivers();
      setState(() => _polylines = {});
      return;
    }

    final origin = route.origin!;
    final dest = route.destination!;
    final pathPoints =
      route.routePoints.isNotEmpty ? route.routePoints : <LatLng>[origin, dest];

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
          points: pathPoints,
          color: AppColors.accentCoral,
          width: 5,
        ),
      };
    });

    // Fit camera to show both pins with padding
    double minLat = pathPoints.first.latitude;
    double maxLat = pathPoints.first.latitude;
    double minLng = pathPoints.first.longitude;
    double maxLng = pathPoints.first.longitude;

    for (final point in pathPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
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

    final routeState = ref.watch(mapRouteProvider);
    final routeSignature = _routeSignature(routeState);

    if (_lastRouteSignature != routeSignature) {
      _lastRouteSignature = routeSignature;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _buildRoute(routeState);
      });
    }

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

          // Atmospheric top fade for depth and readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryNavy.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
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
                                Text(
                                  getTimeBasedGreeting(),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 14,
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
                // Location button with loading state
                _isFetchingLocation
                    ? Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accentCoral,
                            ),
                          ),
                        ),
                      )
                    : _buildMapControl(
                        Icons.my_location_rounded,
                        () => _fetchDeviceLocation(),
                      ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: HomeBottomPanel(
              currentLocationLabel: _currentLocationLabel,
              isRefreshingLocation: _isFetchingLocation,
              onRefreshLocation: _fetchDeviceLocation,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8FC),
            border: Border(
              top: BorderSide(color: Color(0xFFE7EDF6)),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF7F9FD).withValues(alpha: 0.98),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E9F3)),
            ),
            child: Row(
              children: [
                _buildNavItem(
                  label: 'Home',
                  icon: Icons.home_rounded,
                  isActive: true,
                  onTap: () => context.go('/home'),
                ),
                _buildNavItem(
                  label: 'My Rides',
                  icon: Icons.directions_car_rounded,
                  onTap: () => context.push('/rides?mode=ride'),
                ),
                _buildNavItem(
                  label: 'Pool',
                  icon: Icons.people_alt_rounded,
                  onTap: () => context.push('/rides?mode=pool'),
                ),
                _buildNavItem(
                  label: 'Wallet',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => context.push('/wallet'),
                ),
                _buildNavItem(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 36,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.accentCoral.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isActive
                        ? AppColors.accentCoral.withValues(alpha: 0.22)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.accentCoral : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? AppColors.accentCoral : Colors.grey[500],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(top: 3),
                width: isActive ? 14 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.accentCoral,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
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
