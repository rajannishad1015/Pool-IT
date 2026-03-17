import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RoutePathResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RoutePathResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class PlaceSuggestion {
  final String label;
  final LatLng location;

  const PlaceSuggestion({
    required this.label,
    required this.location,
  });
}

class GeocodingService {
  // Use the same API key already configured in index.html / AndroidManifest.xml
  static const String _apiKey = 'AIzaSyCWG1kkWE0EGyosBi7G7QIDn2gVjTn4EwY';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _nominatimBaseUrl =
      'https://nominatim.openstreetmap.org';
  static const double _mumbaiMinLat = 18.88;
  static const double _mumbaiMaxLat = 19.38;
  static const double _mumbaiMinLng = 72.74;
  static const double _mumbaiMaxLng = 73.05;

  /// Returns location suggestions for autocomplete search.
  static Future<List<PlaceSuggestion>> searchPlaceSuggestions(String query) async {
    final searchText = query.trim();
    if (searchText.length < 2) {
      return [];
    }

    final nominatimResults = <PlaceSuggestion>[];
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl/search?format=jsonv2&limit=8&addressdetails=1&countrycodes=in&bounded=1&viewbox=$_mumbaiMinLng,$_mumbaiMaxLat,$_mumbaiMaxLng,$_mumbaiMinLat&q=${Uri.encodeComponent(searchText)}',
      );
      final response = await http.get(uri, headers: _osmHeaders()).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) {
        return _googleSuggestionFallback(searchText);
      }

      final raw = json.decode(response.body) as List<dynamic>;
      for (final item in raw) {
        final map = item as Map<String, dynamic>;
        final lat = double.tryParse((map['lat'] ?? '').toString());
        final lon = double.tryParse((map['lon'] ?? '').toString());
        if (lat == null || lon == null) {
          continue;
        }

        final location = LatLng(lat, lon);
        if (!isWithinMumbai(location)) {
          continue;
        }

        final displayName = (map['display_name'] ?? '').toString();
        if (displayName.isEmpty) {
          continue;
        }

        nominatimResults.add(
          PlaceSuggestion(
            label: _compactSuggestionLabel(displayName),
            location: location,
          ),
        );
      }

      if (nominatimResults.isNotEmpty) {
        return nominatimResults;
      }

      return _googleSuggestionFallback(searchText);
    } catch (_) {
      return _googleSuggestionFallback(searchText);
    }
  }

  static Future<List<PlaceSuggestion>> _googleSuggestionFallback(
    String searchText,
  ) async {
      try {
        final uri = Uri.parse(
          '$_baseUrl?address=${Uri.encodeComponent(searchText)}&key=$_apiKey&region=in&bounds=$_mumbaiMinLat,$_mumbaiMinLng|$_mumbaiMaxLat,$_mumbaiMaxLng',
        );
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          return [];
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status != 'OK') {
          return [];
        }

        final rawResults = (data['results'] as List<dynamic>? ?? const []);
        final suggestions = <PlaceSuggestion>[];
        for (final item in rawResults.take(6)) {
          final map = item as Map<String, dynamic>;
          final geometry = map['geometry'] as Map<String, dynamic>? ?? const {};
          final location = geometry['location'] as Map<String, dynamic>? ?? const {};
          final lat = (location['lat'] as num?)?.toDouble();
          final lng = (location['lng'] as num?)?.toDouble();
          final formattedAddress = (map['formatted_address'] ?? '').toString();
          if (lat == null || lng == null || formattedAddress.isEmpty) {
            continue;
          }

          final suggestionLocation = LatLng(lat, lng);
          if (!isWithinMumbai(suggestionLocation)) {
            continue;
          }

          suggestions.add(
            PlaceSuggestion(
              label: _compactSuggestionLabel(formattedAddress),
              location: suggestionLocation,
            ),
          );
        }

        return suggestions;
      } catch (_) {
        return [];
      }
    }

  /// Convert a place name / address string to a LatLng coordinate.
  /// Returns null if geocoding fails.
  static Future<LatLng?> geocodeAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final uri = Uri.parse(
        '$_baseUrl?address=${Uri.encodeComponent(address)}&key=$_apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final status = data['status'] as String;

        if (status == 'OK') {
          final results = data['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            final location =
                results[0]['geometry']['location'] as Map<String, dynamic>;
            final lat = (location['lat'] as num).toDouble();
            final lng = (location['lng'] as num).toDouble();
            final result = LatLng(lat, lng);
            if (!isWithinMumbai(result)) {
              debugPrint('GeocodingService: Non-Mumbai location rejected.');
              return null;
            }
            debugPrint('GeocodingService: "$address" -> ($lat, $lng)');
            return result;
          }
        } else {
          debugPrint('GeocodingService: Geocoding failed. Status: $status');
        }
      }
    } catch (e) {
      debugPrint('GeocodingService ERROR: $e');
    }

    // Fallback when Google Geocoding API is denied or unavailable.
    return _fallbackGeocodeAddress(address);
  }

  /// Convert coordinates to a readable place label.
  /// Prefers locality/sub-locality and falls back to formatted address.
  static Future<String?> reverseGeocodeLatLng(LatLng coordinates) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?latlng=${coordinates.latitude},${coordinates.longitude}&key=$_apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') {
        debugPrint('GeocodingService: Reverse geocoding failed. Status: $status');
        return _fallbackReverseGeocodeLatLng(coordinates);
      }

      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) {
        return null;
      }

      final firstResult = results.first as Map<String, dynamic>;
      final components =
          (firstResult['address_components'] as List<dynamic>? ?? const []);

      String? sublocality;
      String? locality;
      String? adminArea;

      for (final entry in components) {
        final component = entry as Map<String, dynamic>;
        final types = (component['types'] as List<dynamic>? ?? const []);
        final longName = component['long_name'] as String?;
        if (longName == null || longName.isEmpty) {
          continue;
        }

        if (types.contains('sublocality') ||
            types.contains('sublocality_level_1')) {
          sublocality ??= longName;
        }
        if (types.contains('locality')) {
          locality ??= longName;
        }
        if (types.contains('administrative_area_level_1')) {
          adminArea ??= longName;
        }
      }

      if (sublocality != null && locality != null) {
        return '$sublocality, $locality';
      }
      if (locality != null) {
        return locality;
      }
      if (adminArea != null) {
        return adminArea;
      }

      final formattedAddress = firstResult['formatted_address'] as String?;
      return formattedAddress;
    } catch (e) {
      debugPrint('GeocodingService reverse ERROR: $e');
      return _fallbackReverseGeocodeLatLng(coordinates);
    }
  }

  /// Fetches driving route path and summary from origin to destination.
  static Future<RoutePathResult?> getRoutePath({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_apiKey',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return _fallbackRoutePath(origin: origin, destination: destination);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK') {
        debugPrint('GeocodingService: Directions failed. Status: $status');
        return _fallbackRoutePath(origin: origin, destination: destination);
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        return _fallbackRoutePath(origin: origin, destination: destination);
      }

      final overview = routes.first as Map<String, dynamic>;
      final polylineData = overview['overview_polyline'] as Map<String, dynamic>?;
      final encoded = polylineData?['points'] as String?;
      if (encoded == null || encoded.isEmpty) {
        return _fallbackRoutePath(origin: origin, destination: destination);
      }

      final legs = overview['legs'] as List<dynamic>? ?? const [];
      double distanceMeters = 0;
      double durationSeconds = 0;
      if (legs.isNotEmpty) {
        final firstLeg = legs.first as Map<String, dynamic>;
        final distance = firstLeg['distance'] as Map<String, dynamic>?;
        final duration = firstLeg['duration'] as Map<String, dynamic>?;
        distanceMeters = (distance?['value'] as num?)?.toDouble() ?? 0;
        durationSeconds = (duration?['value'] as num?)?.toDouble() ?? 0;
      }

      return RoutePathResult(
        points: _decodePolyline(encoded),
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );
    } catch (e) {
      debugPrint('GeocodingService directions ERROR: $e');
      return _fallbackRoutePath(origin: origin, destination: destination);
    }
  }

  static Future<LatLng?> _fallbackGeocodeAddress(String address) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl/search?format=jsonv2&limit=1&countrycodes=in&bounded=1&viewbox=$_mumbaiMinLng,$_mumbaiMaxLat,$_mumbaiMaxLng,$_mumbaiMinLat&q=${Uri.encodeComponent(address)}',
      );
      final response = await http.get(uri, headers: _osmHeaders()).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) {
        return null;
      }

      final list = json.decode(response.body) as List<dynamic>;
      if (list.isEmpty) {
        return null;
      }

      final first = list.first as Map<String, dynamic>;
      final lat = double.tryParse((first['lat'] ?? '').toString());
      final lon = double.tryParse((first['lon'] ?? '').toString());
      if (lat == null || lon == null) {
        return null;
      }

      final result = LatLng(lat, lon);
      if (!isWithinMumbai(result)) {
        return null;
      }

      debugPrint('GeocodingService fallback: "$address" -> ($lat, $lon)');
      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _fallbackReverseGeocodeLatLng(LatLng coordinates) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl/reverse?format=jsonv2&lat=${coordinates.latitude}&lon=${coordinates.longitude}',
      );
      final response = await http.get(uri, headers: _osmHeaders()).timeout(
            const Duration(seconds: 10),
          );
      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? const {};

      final sub = (address['suburb'] ?? address['neighbourhood'] ?? '').toString();
      final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              '')
          .toString();

      if (sub.isNotEmpty && city.isNotEmpty) {
        return '$sub, $city';
      }
      if (city.isNotEmpty) {
        return city;
      }

      final displayName = (data['display_name'] ?? '').toString();
      return displayName.isEmpty ? null : displayName;
    } catch (_) {
      return null;
    }
  }

  static Future<RoutePathResult?> _fallbackRoutePath({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>? ?? const [];
      if (routes.isEmpty) {
        return null;
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>? ?? const {};
      final coords = geometry['coordinates'] as List<dynamic>? ?? const [];
      if (coords.isEmpty) {
        return null;
      }

      final points = <LatLng>[];
      for (final item in coords) {
        final c = item as List<dynamic>;
        if (c.length < 2) {
          continue;
        }
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        points.add(LatLng(lat, lon));
      }

      return RoutePathResult(
        points: points,
        distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _osmHeaders() {
    return const {
      'User-Agent': 'PoolIT-UserApp/1.0 (contact: support@poolit.local)',
      'Accept': 'application/json',
    };
  }

  static String _compactSuggestionLabel(String displayName) {
    final parts = displayName
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0]}, ${parts[1]}';
    }
    return displayName;
  }

  static bool isWithinMumbai(LatLng location) {
    return location.latitude >= _mumbaiMinLat &&
        location.latitude <= _mumbaiMaxLat &&
        location.longitude >= _mumbaiMinLng &&
        location.longitude <= _mumbaiMaxLng;
  }

  static List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> polylineCoordinates = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      polylineCoordinates.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return polylineCoordinates;
  }
}
