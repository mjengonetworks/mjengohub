// lib/projects/services/location_search_service.dart
//
// Location search autocomplete for the project submit/edit map picker —
// calls Nominatim's public OpenStreetMap search API directly from the app.
// No backend route needed: no geocoding dependency exists server-side
// (verified against requirements.txt/config.py), and Nominatim's usage
// policy allows direct client calls at low volume with a proper
// User-Agent, which this is.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationSearchResult {
  final String displayName;
  final LatLng point;
  const LocationSearchResult({required this.displayName, required this.point});
}

class LocationSearchService {
  static const _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<LocationSearchResult>> search(String query) async {
    if (query.trim().length < 3) return [];
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'q': query.trim(),
          'format': 'json',
          'limit': '5',
          'addressdetails': '0',
        },
      );
      final res = await http.get(
        uri,
        headers: {
          // Nominatim's usage policy requires an identifying User-Agent.
          'User-Agent': 'MjengoHubApp/1.0 (mjengohub.co.ke)',
        },
      );
      if (res.statusCode != 200) return [];
      // Decode explicitly as UTF-8 rather than trusting `res.body`'s
      // encoding auto-detection, which falls back to Latin-1 when the
      // response's Content-Type omits a charset — silently mangling
      // non-ASCII place names (accents, Arabic/Amharic script, etc.).
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is! List) return [];
      return data
          .whereType<Map<String, dynamic>>()
          .map((j) {
            final lat = double.tryParse(j['lat']?.toString() ?? '');
            final lon = double.tryParse(j['lon']?.toString() ?? '');
            if (lat == null || lon == null) return null;
            return LocationSearchResult(
              displayName: (j['display_name'] as String?) ?? '',
              point: LatLng(lat, lon),
            );
          })
          .whereType<LocationSearchResult>()
          .toList();
    } catch (e) {
      print('LocationSearchService.search error: $e');
      return [];
    }
  }
}
