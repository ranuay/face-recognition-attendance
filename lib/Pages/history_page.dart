import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late String _bulanPilih;
  late List<String> _pilihanBulan;
  late Future<List<Map<String, dynamic>>> _futureRiwayat;

  @override
  void initState() {
    super.initState();
    _inisialisasiBulan();
    _refreshData();
  }

  void _inisialisasiBulan() {
    _pilihanBulan = [];
    final now = DateTime.now();
    const namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    for (int i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 1);
      _pilihanBulan.add('${namaBulan[d.month - 1]} ${d.year}');
    }
    
    _bulanPilih = _pilihanBulan.first; 
  }

  void _refreshData() {
    setState(() {
      _futureRiwayat = _ambilRiwayatSupabase(_bulanPilih);
    });
  }

  int _mapNamaBulan(String nama) {
    const namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return namaBulan.indexOf(nama) + 1;
  }

  Future<List<Map<String, dynamic>>> _ambilRiwayatSupabase(String bulanTahun) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final split = bulanTahun.split(' ');
    final bulan = _mapNamaBulan(split[0]);
    final tahun = int.parse(split[1]);

    final awalBulan = DateTime(tahun, bulan, 1).toIso8601String();
    final akhirBulan = DateTime(tahun, bulan + 1, 1).subtract(const Duration(seconds: 1)).toIso8601String();

    final response = await Supabase.instance.client
        .from('presensi')
        .select('waktu_absen, tipe_absen')
        .eq('user_id', user.id)
        .gte('waktu_absen', awalBulan)
        .lte('waktu_absen', akhirBulan)
        .order('waktu_absen', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  String _formatTanggal(String isoString) {
    final waktu = DateTime.parse(isoString).toLocal();
    return DateFormat('EEEE, dd MMMM', 'id_ID').format(waktu);
  }

  String _formatJam(String isoString) {
    final waktu = DateTime.parse(isoString).toLocal();
    return DateFormat('HH:mm').format(waktu);
  }

  Future<void> _eksporKeCSV() async {
    try {
      final riwayat = await _futureRiwayat;
      
      if (riwayat.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada data untuk diekspor'), backgroundColor: Colors.orange),
        );
        return;
      }

      StringBuffer csv = StringBuffer();
      csv.writeln("Tanggal,Jam,Tipe Absen");

      for (var data in riwayat) {
        final waktu = DateTime.parse(data['waktu_absen']).toLocal();
        final tgl = DateFormat('yyyy-MM-dd').format(waktu);
        final jam = DateFormat('HH:mm:ss').format(waktu);
        final tipe = data['tipe_absen'] ?? 'Masuk';
        
        csv.writeln("$tgl,$jam,$tipe");
      }

      final directory = await getTemporaryDirectory();
      final namaFile = 'Riwayat_Absen_${_bulanPilih.replaceAll(' ', '_')}.csv'; 
      final path = '${directory.path}/$namaFile';
      final file = File(path);
      
      await file.writeAsString(csv.toString());

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(path)], 
        text: 'Ini riwayat absen bulan $_bulanPilih',
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ekspor: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF5F6F8); 

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            color: Colors.green.shade800, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded, color: Colors.green.shade800),
            tooltip: 'Ekspor Data',
            onPressed: () {
               // Panggil fungsinya
              _eksporKeCSV();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureRiwayat,
        builder: (context, snapshot) {
          final riwayat = snapshot.data ?? []; 
          
          return Column(
            children: [
              _buildFilterBulan(riwayat.length),
              const SizedBox(height: 16),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : riwayat.isEmpty
                        ? const Center(child: Text('Tidak ada riwayat absen di bulan ini'))
                        : ListView.builder(
                            itemCount: riwayat.length,
                            itemBuilder: (context, index) {
                              return _buildKartuRiwayat(
                                riwayat[index],
                                bgColor: bgColor,
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBulan(int totalHadir) {
    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bulan Ini', style: TextStyle(fontSize: 12, color: Colors.grey)),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _bulanPilih,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.green),
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.green.shade800
                  ),
                  items: _pilihanBulan.map((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(val),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      _bulanPilih = newValue;
                      _refreshData(); 
                    }
                  },
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('$totalHadir Hadir', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuRiwayat(Map<String, dynamic> data, {required Color bgColor}) {
    final waktuAbsen = data['waktu_absen'] as String;
    final tipeAbsen = data['tipe_absen'] as String? ?? 'Masuk';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 70, 
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 44, 
                  color: Colors.grey.shade300, 
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgColor, 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.login, 
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300, 
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 20, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTanggal(waktuAbsen),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Berhasil Absen $tipeAbsen',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Kampus D Gunadarma",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatJam(waktuAbsen),
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16, 
                          color: Colors.green.shade800
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}