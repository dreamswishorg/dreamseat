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
    // 1. Resolve the app's location permission FIRST. iOS only registers the
    //    app under Settings > Privacy > Location Services once the native
    //    permission prompt has actually been shown to the user.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Trigger native phone system prompt (iOS CoreLocation / Android)
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationStatusResult(status: 'permission_denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationStatusResult(status: 'permission_denied_forever');
    }

    // 2. Check if device-wide location service (GPS) is switched off
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationStatusResult(status: 'gps_disabled');
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
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
    } catch (_) {
      // Fallback to HTTP reverse geocoding on Web or platform plugin failure
    }

    // HTTP reverse geocoding fallback
    return await _reverseGeocodeHttp(position);
  }

  Future<String?> _reverseGeocodeHttp(Position position) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'DreamsEatsApp/1.0 (support@dreamseatapp.com)',
      }).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          List<String> parts = [];
          final road = addr['road'] ?? addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'] ?? addr['commercial'];
          if (road != null && road.toString().trim().isNotEmpty) {
            parts.add(road.toString().trim());
          }
          final city = addr['city'] ?? addr['town'] ?? addr['suburb'] ?? addr['city_district'] ?? addr['state'];
          if (city != null && city.toString().trim().isNotEmpty && !parts.contains(city.toString().trim())) {
            parts.add(city.toString().trim());
          }
          if (parts.isNotEmpty) {
            return parts.take(2).join(', ');
          }
        }
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName.split(',').map((s) => s.trim()).take(3).join(', ');
        }
      }
    } catch (_) {}
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
    } catch (_) {}

    // Fallback to Nominatim search
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1&countrycodes=gh',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'DreamsEatsApp/1.0 (support@dreamseatapp.com)',
      }).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
          final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            return Position(
              latitude: lat,
              longitude: lon,
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
        }
      }
    } catch (_) {}

    return null;
  }

  Future<List<PredictedAddress>> searchPredictiveAddresses(String query) async {
    if (query.trim().length < 3) return [];
    try {
      // Prioritize Ghana delivery addresses via &countrycodes=gh
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=6&addressdetails=1&countrycodes=gh',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'DreamsEatsApp/1.0 (support@dreamseatapp.com)',
      }).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          final rawDisplay = item['display_name'] as String? ?? '';
          final segments = rawDisplay.split(',').map((s) => s.trim()).toList();
          final primary = segments.isNotEmpty ? segments.first : query;
          final secondary = segments.length > 1 ? segments.sublist(1).take(3).join(', ') : 'Ghana';

          return PredictedAddress(
            displayName: rawDisplay,
            primaryText: primary,
            secondaryText: secondary,
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
              primaryText: query,
              secondaryText: 'Ghana',
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
  final String? primaryText;
  final String? secondaryText;
  final double latitude;
  final double longitude;

  PredictedAddress({
    required this.displayName,
    this.primaryText,
    this.secondaryText,
    required this.latitude,
    required this.longitude,
  });

  String get shortDisplay {
    if (primaryText != null && primaryText!.isNotEmpty) {
      if (secondaryText != null && secondaryText!.isNotEmpty) {
        return '$primaryText, $secondaryText';
      }
      return primaryText!;
    }
    return displayName.split(',').take(2).join(', ');
  }

  Position toPosition() => Position(
        latitude: latitude,
        longitude: longitude,
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
