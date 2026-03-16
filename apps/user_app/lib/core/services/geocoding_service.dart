import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  // Use the same API key already configured in index.html / AndroidManifest.xml
  static const String _apiKey = 'AIzaSyCWG1kkWE0EGyosBi7G7QIDn2gVjTn4EwY';
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

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
            debugPrint('GeocodingService: "$address" -> ($lat, $lng)');
            return LatLng(lat, lng);
          }
        } else {
          debugPrint('GeocodingService: Geocoding failed. Status: $status');
        }
      }
    } catch (e) {
      debugPrint('GeocodingService ERROR: $e');
    }
    return null;
  }
}
