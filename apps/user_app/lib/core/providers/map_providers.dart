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
  bool _isGeocoding = false;

  LatLng? get origin => _origin;
  LatLng? get destination => _destination;
  String? get destinationName => _destinationName;
  bool get isGeocoding => _isGeocoding;
  bool get hasRoute => _origin != null && _destination != null;

  /// Set the current device location as origin.
  void setOrigin(LatLng origin) {
    _origin = origin;
    notifyListeners();
  }

  /// Geocode a destination address and update state.
  Future<void> setDestination(String destinationAddress) async {
    if (destinationAddress.trim().isEmpty) {
      clearRoute();
      return;
    }

    _isGeocoding = true;
    notifyListeners();

    final latLng = await GeocodingService.geocodeAddress(destinationAddress);
    _isGeocoding = false;

    if (latLng != null) {
      _destination = latLng;
      _destinationName = destinationAddress;
      debugPrint('MapRoute: Destination set to $_destinationName @ $latLng');
    } else {
      debugPrint('MapRoute: Geocoding failed for "$destinationAddress"');
    }
    notifyListeners();
  }

  /// Clear the entire route.
  void clearRoute() {
    _destination = null;
    _destinationName = null;
    _isGeocoding = false;
    notifyListeners();
  }
}

final mapRouteProvider = ChangeNotifierProvider<RouteNotifier>((ref) {
  return RouteNotifier();
});
