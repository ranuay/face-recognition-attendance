import 'package:geolocator/geolocator.dart';

class LocationService {
  final double latLabACSL = -6.3673271445703845;
  final double longLabACSL = 106.83351290697773;

  Future<Position> getKoordinat() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS pada HP dimatikan. Silakan aktifkan terlebih dahulu.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin akses lokasi diblokir permanen. Buka pengaturan HP.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<bool> isInRadius() async {
    try {
      Position pos = await getKoordinat();
      
      double dist = Geolocator.distanceBetween(
        latLabACSL, 
        longLabACSL, 
        pos.latitude, 
        pos.longitude,
      );
      
      return dist <= 7500;
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}