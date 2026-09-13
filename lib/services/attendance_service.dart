import 'package:supabase_flutter/supabase_flutter.dart';
import 'location_service.dart';

class AttendanceService {
  final _supabase = Supabase.instance.client;
  final _locationService = LocationService();

  Future<Map<String, dynamic>> submitAttendance(List<double> vectorKamera) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return {'success': false, 'message': 'Sesi berakhir, silakan login ulang.'};

    try {
      bool isInside = await _locationService.isInRadius();
      if (!isInside) {
        return {'success': false, 'message': 'Anda berada di luar radius!'};
      }

      final double score = await _supabase.rpc('verify_face', params: {
        'target_user_id': user.id,
        'query_embedding': vectorKamera,
      });

      if (score < 0.80) {
        return {'success': false, 'message': 'Verifikasi Gagal: Wajah tidak cocok! ($score)'};
      }

      final pos = await _locationService.getKoordinat(); 

      await _supabase.from('presensi').insert({
        'user_id': user.id,
        'tipe_absen': 'Masuk',
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'akurasi_wajah': score,
        'status_lokasi': 'Dalam Radius',
        'waktu_absen': DateTime.now().toUtc().toIso8601String(),
      });

      return {'success': true, 'message': 'Berhasil! Presensi masuk tercatat.'};

    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}