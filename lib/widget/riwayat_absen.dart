import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pi/Pages/history_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatAbsenTerbaru extends StatelessWidget {
  const RiwayatAbsenTerbaru({super.key});

  Future<List<Map<String, dynamic>>> _ambilRiwayat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    return Supabase.instance.client
        .from('presensi')
        .select('waktu_absen, tipe_absen')
        .eq('user_id', user.id)
        .order('waktu_absen', ascending: false)
        .limit(2);
  }

  String _labelHari(DateTime waktu) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final tanggalAbsen = DateTime(waktu.year, waktu.month, waktu.day);
    final selisih = hariIni.difference(tanggalAbsen).inDays;

    if (selisih == 0) return 'Hari Ini';
    if (selisih == 1) return 'Kemarin';

    const namaHari = [
      'Senin', 'Selasa', 'Rabu', 'Kamis',
      'Jumat', 'Sabtu', 'Minggu',
    ];
    return namaHari[waktu.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
      color: Color.fromARGB(255, 244, 244, 244),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ambilRiwayat(),
        builder: (context, snapshot) {
          final riwayat = snapshot.data ?? [];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18,),
              const Text(
                'Riwayat Absen Terbaru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14, width: double.infinity),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )
              else if (riwayat.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text('Belum ada riwayat absen'),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < riwayat.length; i++)
                        _barisRiwayat(
                          DateTime.parse(riwayat[i]['waktu_absen']).toLocal(),
                          riwayat[i]['tipe_absen'] as String? ?? 'Masuk',
                          isFirst: i == 0, 
                          isLast: i == riwayat.length - 1, 
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RiwayatPage()),
                  );
                },
                icon: const Icon(Icons.keyboard_arrow_up),
                label: const Text('Lihat Riwayat Lengkap'), style: TextButton.styleFrom(
                  foregroundColor: Colors.black87,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
 Widget _barisRiwayat(DateTime waktu, String tipe, {required bool isLast, required bool isFirst}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          
          Container(
            width: 52,
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('HH:mm').format(waktu),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          SizedBox(
            width: 14,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.grey.shade300 : Colors.green,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 5), 
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.grey.shade300 : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 16), 
              child: Text(
                'Berhasil Absen ${tipe == 'Masuk' ? 'Masuk' : 'Keluar'} '
                '(${_labelHari(waktu)})',
              ),
            ),
          ),
          
        ],
      ),
    );
  }
}