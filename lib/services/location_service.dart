import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Future<Position?> getCurrentPosition() async {
    final result = await getPositionWithStatus();
    return result.position;
  }

  Future<LocationStatusResult> getPositionWithStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStatusResult(status: 'gps_disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationStatusResult(status: 'permission_denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationStatusResult(status: 'permission_denied_forever');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      return LocationStatusResult(status: 'success', position: pos);
    } catch (e) {
      return LocationStatusResult(status: 'error');
    }
  }

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  Future<String?> getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> parts = [];

        // Extract precise street or building name if available and meaningful
        if (place.street != null &&
            place.street!.trim().isNotEmpty &&
            place.street != place.locality &&
            !place.street!.contains('+')) {
          parts.add(place.street!.trim());
        }

        // Add subLocality (neighborhood/district e.g. Osu, East Legon)
        if (place.subLocality != null &&
            place.subLocality!.trim().isNotEmpty &&
            !parts.contains(place.subLocality!.trim())) {
          parts.add(place.subLocality!.trim());
        }

        // Add locality (city/town e.g. Accra, Kumasi)
        if (place.locality != null &&
            place.locality!.trim().isNotEmpty &&
            !parts.contains(place.locality!.trim())) {
          parts.add(place.locality!.trim());
        }

        // Fallback to administrative area if everything else was empty
        if (parts.isEmpty &&
            place.administrativeArea != null &&
            place.administrativeArea!.trim().isNotEmpty) {
          parts.add(place.administrativeArea!.trim());
        }

        if (parts.isNotEmpty) {
          // Take up to 2 most precise address components for clean formatting
          return parts.take(2).join(", ");
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Position?> getLatLngFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        return Position(
          longitude: loc.longitude,
          latitude: loc.latitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<List<PredictedAddress>> searchPredictiveAddresses(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'DreamseatApp/1.0 (contact@dreamseat.com)',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return PredictedAddress(
            displayName: item['display_name'] as String? ?? '',
            latitude: double.tryParse(item['lat']?.toString() ?? '') ?? 5.6037,
            longitude: double.tryParse(item['lon']?.toString() ?? '') ?? -0.1870,
          );
        }).toList();
      }
    } catch (e) {
      try {
        final locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          return locations.take(3).map((loc) {
            return PredictedAddress(
              displayName: query,
              latitude: loc.latitude,
              longitude: loc.longitude,
            );
          }).toList();
        }
      } catch (_) {}
    }
    return [];
  }
}

class LocationStatusResult {
  final String status; // 'success', 'gps_disabled', 'permission_denied', 'permission_denied_forever', 'error'
  final Position? position;

  LocationStatusResult({required this.status, this.position});
}

class PredictedAddress {
  final String displayName;
  final double latitude;
  final double longitude;

  PredictedAddress({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}
