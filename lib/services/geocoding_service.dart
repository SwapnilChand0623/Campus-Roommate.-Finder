import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'CampusRoommateFinder/1.0';

  /// Geocode a US zip code to latitude and longitude
  /// Returns null if the zip code is invalid or not found
  Future<GeoLocation?> geocodeZipCode(String zipCode) async {
    try {
      // Validate zip code format (5 digits)
      if (!RegExp(r'^\d{5}$').hasMatch(zipCode)) {
        return null;
      }

      final url = Uri.parse(
        '$_baseUrl/search?postalcode=$zipCode&country=US&format=json&limit=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': _userAgent},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final List<dynamic> results = jsonDecode(response.body);
      if (results.isEmpty) {
        return null;
      }

      final data = results.first;
      return GeoLocation(
        latitude: double.parse(data['lat'] as String),
        longitude: double.parse(data['lon'] as String),
        displayName: data['display_name'] as String?,
      );
    } catch (e) {
      print('Geocoding error: $e');
      return null;
    }
  }

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in miles
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMiles = 3958.8;
    const pi = 3.141592653589793;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(lat1)) *
            _cos(_toRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadiusMiles * c;
  }

  static double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }

  static double _sin(double x) {
    return _taylorSin(x);
  }

  static double _cos(double x) {
    return _taylorCos(x);
  }

  static double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 3.141592653589793 / 2;
    if (x == 0 && y < 0) return -3.141592653589793 / 2;
    return 0; // undefined
  }

  static double _atan(double x) {
    return _taylorAtan(x);
  }

  // Taylor series approximations
  static double _taylorSin(double x) {
    double term = x;
    double sum = term;
    for (int n = 1; n < 10; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      sum += term;
    }
    return sum;
  }

  static double _taylorCos(double x) {
    double term = 1.0;
    double sum = term;
    for (int n = 1; n < 10; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      sum += term;
    }
    return sum;
  }

  static double _taylorAtan(double x) {
    if (x > 1) return 3.141592653589793 / 2 - _taylorAtan(1 / x);
    if (x < -1) return -3.141592653589793 / 2 - _taylorAtan(1 / x);
    double term = x;
    double sum = term;
    for (int n = 1; n < 20; n++) {
      term *= -x * x * (2 * n - 1) / (2 * n + 1);
      sum += term;
    }
    return sum;
  }
}

class GeoLocation {
  const GeoLocation({
    required this.latitude,
    required this.longitude,
    this.displayName,
  });

  final double latitude;
  final double longitude;
  final String? displayName;

  String? get city {
    if (displayName == null) return null;
    // Extract city from display name (format: "City, County, State, Country")
    final parts = displayName!.split(',');
    return parts.isNotEmpty ? parts.first.trim() : null;
  }
}
