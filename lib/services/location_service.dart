import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// GPS로 현재 위치를 가져와 동네명(행정동)을 반환
  static Future<String> getCurrentDistrict() async {
    // 1. 위치 서비스 활성화 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('위치 서비스가 꺼져 있어요. 설정에서 위치를 켜주세요.');
    }

    // 2. 권한 확인 및 요청
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부됐어요.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부됐어요. 설정에서 직접 허용해주세요.');
    }

    // 3. 현재 위치 가져오기
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    // 4. 위도/경도 → 주소 변환
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty) {
      throw Exception('주소를 찾을 수 없어요.');
    }

    final placemark = placemarks.first;

    // 행정동 > 법정동 > 구 순서로 반환
    final district = placemark.subLocality?.isNotEmpty == true
        ? placemark.subLocality!
        : placemark.locality?.isNotEmpty == true
            ? placemark.locality!
            : placemark.administrativeArea ?? '알 수 없음';

    return district;
  }
}
