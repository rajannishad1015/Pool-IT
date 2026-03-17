import 'package:flutter/foundation.dart';
// ChangeNotifierProvider is in the legacy export for flutter_riverpod v3
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/geocoding_service.dart';


/// Holds and notifies changes to map route state.
class RouteNotifier extends ChangeNotifier {
  LatLng? _origin;
  LatLng? _destination;
  String? _destinationName;
  List<LatLng> _routePoints = [];
  double _routeDistanceMeters = 0;
  double _routeDurationSeconds = 0;
  bool _isGeocoding = false;

  LatLng? get origin => _origin;
  LatLng? get destination => _destination;
  String? get destinationName => _destinationName;
  List<LatLng> get routePoints => _routePoints;
  double get routeDistanceMeters => _routeDistanceMeters;
  double get routeDurationSeconds => _routeDurationSeconds;
  bool get isGeocoding => _isGeocoding;
  bool get hasRoute => _origin != null && _destination != null;

  /// Set the current device location as origin.
  void setOrigin(LatLng origin) {
    _origin = origin;
    if (_destination != null) {
      _refreshRoutePath();
      return;
    }
    notifyListeners();
  }

  /// Geocode a destination address and update state.
  Future<void> setDestination(String destinationAddress) async {
    if (destinationAddress.trim().isEmpty) {
      clearRoute();
      return;
    }

    final previousDestination = _destination;
    final previousDestinationName = _destinationName;
    final previousRoutePoints = List<LatLng>.from(_routePoints);
    final previousDistanceMeters = _routeDistanceMeters;
    final previousDurationSeconds = _routeDurationSeconds;

    _isGeocoding = true;
    notifyListeners();

    final latLng = await GeocodingService.geocodeAddress(destinationAddress);
    _isGeocoding = false;

    if (latLng != null) {
      _destination = latLng;
      _destinationName = destinationAddress;
      await _refreshRoutePath();
      debugPrint('MapRoute: Destination set to $_destinationName @ $latLng');
    } else {
      _destination = previousDestination;
      _destinationName = previousDestinationName;
      _routePoints = previousRoutePoints;
      _routeDistanceMeters = previousDistanceMeters;
      _routeDurationSeconds = previousDurationSeconds;
      debugPrint('MapRoute: Geocoding failed for "$destinationAddress"');
    }
    notifyListeners();
  }

  /// Set destination directly using known coordinates from autocomplete.
  Future<void> setDestinationFromCoordinates({
    required String destinationName,
    required LatLng destination,
  }) async {
    _isGeocoding = true;
    notifyListeners();

    _destination = destination;
    _destinationName = destinationName;
    await _refreshRoutePath();

    _isGeocoding = false;
    notifyListeners();
  }

  Future<void> _refreshRoutePath() async {
    if (_origin == null || _destination == null) {
      _routePoints = [];
      _routeDistanceMeters = 0;
      _routeDurationSeconds = 0;
      return;
    }

    final route = await GeocodingService.getRoutePath(
      origin: _origin!,
      destination: _destination!,
    );
    if (route != null && route.points.isNotEmpty) {
      _routePoints = route.points;
      _routeDistanceMeters = route.distanceMeters;
      _routeDurationSeconds = route.durationSeconds;
    } else {
      _routePoints = [_origin!, _destination!];
      _routeDistanceMeters = 0;
      _routeDurationSeconds = 0;
    }
  }

  /// Clear the entire route.
  void clearRoute() {
    _destination = null;
    _destinationName = null;
    _routePoints = [];
    _routeDistanceMeters = 0;
    _routeDurationSeconds = 0;
    _isGeocoding = false;
    notifyListeners();
  }
}

final mapRouteProvider = ChangeNotifierProvider<RouteNotifier>((ref) {
  return RouteNotifier();
});
