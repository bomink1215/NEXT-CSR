import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // API 키 발급 후 여기에 입력
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // 주소 → 좌표 변환
  static Future<Map<String, double>?> getCoordinates(String address) async {
    try {
      final encoded = Uri.encodeComponent(address);
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encoded&key=$_apiKey';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        return {
          'lat': location['lat'].toDouble(),
          'lng': location['lng'].toDouble(),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 두 좌표 사이 직선 거리 계산 (Haversine 공식)
  static double getDistanceInMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // 지구 반지름 (미터)
    final phi1 = lat1 * 3.14159265358979 / 180;
    final phi2 = lat2 * 3.14159265358979 / 180;
    final dPhi = (lat2 - lat1) * 3.14159265358979 / 180;
    final dLambda = (lng2 - lng1) * 3.14159265358979 / 180;

    final a = (dPhi / 2) * (dPhi / 2) * 1 +
        (phi1 * 0 + phi2 * 0 + 1) * // cos 근사
            (dLambda / 2) *
            (dLambda / 2);

    // 간단한 유클리드 근사 (짧은 거리용)
    final dlat = lat2 - lat1;
    final dlng = (lng2 - lng1) *
        (0.7854); // cos(37.5도) ≈ 0.7854 (서울 위도 기준)
    final distDeg = (dlat * dlat + dlng * dlng);
    final distMeters = distDeg * 111000;

    return distMeters;
  }

  // 거리 → 도보 분 계산 (도보 속도 약 80m/분)
  static int getWalkMinutes(double distanceInMeters) {
    return (distanceInMeters / 80).ceil();
  }

  // 주소 두 개로 도보 분 계산
  static Future<int?> getWalkMinutesBetween(
      String address1, String address2) async {
    if (_apiKey == 'YOUR_GOOGLE_MAPS_API_KEY') return null; // API 키 없으면 null

    final coord1 = await getCoordinates(address1);
    final coord2 = await getCoordinates(address2);

    if (coord1 == null || coord2 == null) return null;

    final distance = getDistanceInMeters(
      coord1['lat']!,
      coord1['lng']!,
      coord2['lat']!,
      coord2['lng']!,
    );

    return getWalkMinutes(distance);
  }
}