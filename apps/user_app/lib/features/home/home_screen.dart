import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/providers/profile_providers.dart';
import '../../core/providers/map_providers.dart';
import '../../core/providers/tracking_providers.dart';
import '../../core/services/geocoding_service.dart';
import 'widgets/home_bottom_panel.dart';

String getTimeBasedGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Good evening,';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  final LatLng _defaultCenter = const LatLng(19.0760, 72.8777);
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
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
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

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _deviceLocation = latLng;
          _currentLocationLabel = 'Fetching location name...';
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15.0),
          ),
        );
        ref.read(mapRouteProvider).setOrigin(latLng);
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  final String _mapStyle = '''
[
  { "elementType": "geometry", "stylers": [ { "color": "#111111" } ] },
  { "elementType": "labels.icon", "stylers": [ { "visibility": "off" } ] },
  { "elementType": "labels.text.fill", "stylers": [ { "color": "#9a9a9a" } ] },
  { "elementType": "labels.text.stroke", "stylers": [ { "color": "#111111" } ] },
  { "featureType": "poi", "elementType": "geometry", "stylers": [ { "color": "#1a1a1a" } ] },
  { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#212121" } ] },
  { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#2c2c2c" } ] },
  { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#090909" } ] }
]
''';

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _loadOnlineDrivers();
  }

  Future<void> _loadOnlineDrivers() async {
    final drivers = await ref.read(onlineDriversProvider.future);
    final markers = <Marker>{};

    for (final driver in drivers) {
      final profile = driver['profiles'] as Map<String, dynamic>?;
      final driverName = profile?['full_name'] ?? 'Driver';
      final location = parseLatLng(profile?['last_lat_lng'] as String?);
      if (location != null) {
        markers.add(
          Marker(
            markerId: MarkerId('driver_${driver['id']}'),
            position: location,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(title: driverName),
          ),
        );
      }
    }

    if (mounted) setState(() => _markers = markers);
  }

  void _buildRoute(RouteNotifier route) {
    if (!route.hasRoute) {
      _loadOnlineDrivers();
      if (mounted) setState(() => _polylines = {});
      return;
    }

    final origin = route.origin!;
    final destination = route.destination!;
    final pathPoints = route.routePoints.isNotEmpty
        ? route.routePoints
        : <LatLng>[origin, destination];

    if (mounted) {
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('origin'),
            position: origin,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: destination,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: route.destinationName ?? 'Destination',
            ),
          ),
        };

        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: pathPoints,
            color: const Color(0xFF2196F3),
            width: 5,
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0xFF0A0A0A),
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _deviceLocation ?? _defaultCenter,
                  zoom: 13,
                ),
                zoomControlsEnabled: false,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: _markers,
                polylines: _polylines,
                style: _mapStyle,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
                              backgroundColor: const Color(0xFF2A2A2A),
                              child: profile?['avatar_url'] == null
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFB5B5B5),
                                  ),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
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
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF4A4A4A)),
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 270,
            child: Column(
              children: [
                _isFetchingLocation
                    ? _buildLoadingControl()
                    : _buildMapControl(
                        Icons.my_location_rounded,
                        _fetchDeviceLocation,
                      ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF4A4A4A)),
                  ),
                  child: Column(
                    children: [
                      _buildMapControl(
                        Icons.add_rounded,
                        () => _mapController?.animateCamera(
                          CameraUpdate.zoomIn(),
                        ),
                        isGrouped: true,
                        isTop: true,
                      ),
                      const Divider(height: 1, color: Color(0xFF3A3A3A)),
                      _buildMapControl(
                        Icons.remove_rounded,
                        () => _mapController?.animateCamera(
                          CameraUpdate.zoomOut(),
                        ),
                        isGrouped: true,
                        isBottom: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
          decoration: const BoxDecoration(
            color: Color(0xFF090909),
            border: Border(top: BorderSide(color: Color(0xFF2B2B2B))),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF2E2E2E)),
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

  Widget _buildLoadingControl() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4A4A4A)),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.grey[500],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? Colors.white : Colors.grey[500],
                  ),
                ),
              ],
            ),
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
    final radius = isGrouped
        ? BorderRadius.vertical(
            top: isTop ? const Radius.circular(12) : Radius.zero,
            bottom: isBottom ? const Radius.circular(12) : Radius.zero,
          )
        : BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: radius,
            border: Border.all(color: const Color(0xFF464646)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
