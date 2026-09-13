import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pi/Pages/camera_scan.dart';
import 'package:pi/Pages/loading_screen.dart';
import 'package:pi/widget/card_map.dart';
import 'package:pi/widget/riwayat_absen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../auth/auth_service.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';
import 'profile_page.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  final authService = AuthService();
  final _supabase = Supabase.instance.client;
  final _locationService = LocationService();
  
  String fullName = 'User';
  String? avatarUrl;
  String _jamAbsenMasuk = '--/--'; 
  
  bool _isLoading = true;
  bool _wajahSudahTerdaftar = false;
  Position? _userPosition;

  String capitalize(String s) => s.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');
  
  @override
  void initState() {
    super.initState();
    _inisialisasiData();
    
  }

  Future<void> _inisialisasiData() async {
    setState(() => _isLoading = true); 

    try {
      await _muatDataProfilDanAbsen();
      setState(() => _isLoading = false);
      _ambilLokasiUser(); 
    } catch (e) {
      print("Error inisialisasi: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ambilLokasiUser() async {
    try {
      Position? pos = await _locationService.getKoordinat();
      if (!mounted) return;
      setState(() {
        _userPosition = pos;
      });
    } catch (e) {
      print("Gagal mendapat lokasi: $e");
    }
  }

  Future<String?> _ambilJamAbsenHariIni() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final now = DateTime.now();
      final awalHari = DateTime(now.year, now.month, now.day).toIso8601String();
      final akhirHari = DateTime(now.year, now.month, now.day + 1).subtract(const Duration(seconds: 1)).toIso8601String();

      final data = await _supabase
          .from('presensi')
          .select('waktu_absen')
          .eq('user_id', user.id)
          .eq('tipe_absen', 'Masuk')
          .gte('waktu_absen', awalHari) 
          .lte('waktu_absen', akhirHari)
          .order('waktu_absen', ascending: false)
          .limit(1);

      if (data.isNotEmpty && data.first['waktu_absen'] != null) {
        final waktuLokal = DateTime.parse(data.first['waktu_absen']).toLocal();
        return DateFormat('HH:mm').format(waktuLokal);
      }
      return null;
    } catch (e) {
      print("Error ambil jam absen: $e");
      return null;
    }
  }

  Future<void> _daftarkanWajahBaru() async {
    final vektorWajah = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScanScreen()),
    );

    if (vektorWajah == null || vektorWajah is! List<double>) return;

    setState(() => _isLoading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Sesi pengguna tidak valid.");

      await _supabase.from('pengguna').update({
        'face_embedding': vektorWajah,
      }).eq('id', user.id);

      setState(() {
        _wajahSudahTerdaftar = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wajah referensi berhasil disimpan!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan wajah: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _prosesAbsenMasuk() async {
    setState(() => _isLoading = true);

    try {
      final locationService = LocationService();
      bool isInside = await locationService.isInRadius();

      if (!isInside) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda berada di luar jangkauan!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return; 
      }

      setState(() => _isLoading = false);

      final vektorAbsen = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScanScreen()),
      );

      if (vektorAbsen == null || vektorAbsen is! List<double>) return;

      setState(() => _isLoading = true);

      final result = await AttendanceService().submitAttendance(vektorAbsen);

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        final jamAbsenBaru = await _ambilJamAbsenHariIni();
        if (!mounted) return;
        setState(() {
          _jamAbsenMasuk = jamAbsenBaru ?? DateFormat('HH:mm').format(DateTime.now());
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _muatDataProfilDanAbsen() async {
    final name = await authService.getCurrentUserFullName();
    final avatar = await getAvatarUrl(); 
    final jamAbsen = await _ambilJamAbsenHariIni();
    
    final user = _supabase.auth.currentUser;
    bool statusWajah = false;
    
    if (user != null) {
      final data = await _supabase
          .from('pengguna')
          .select('face_embedding')
          .eq('id', user.id)
          .maybeSingle();
      
      if (data != null) {
        statusWajah = data['face_embedding'] != null;
      }
    }

    if (!mounted) return;
    setState(() {
      fullName = name?.trim().isNotEmpty == true ? name!.trim() : 'User';
      avatarUrl = avatar;
      _jamAbsenMasuk = jamAbsen ?? '--/--';
      _wajahSudahTerdaftar = statusWajah;
    });
  }

  Future<void> _refreshProfil() async {
    try {
      await _muatDataProfilDanAbsen(); 
    } catch (e) {
      print("Gagal refresh profil: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LottieLoadingScreen();
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Text(
              'Welcome, ${capitalize(fullName)}', 
              style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            Row(
              children: [
                Text(
                  _wajahSudahTerdaftar ? 'Biometrik Terdaftar' : 'Biometrik Belum Terdaftar',
                  style: TextStyle(
                    color: _wajahSudahTerdaftar ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _wajahSudahTerdaftar ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _wajahSudahTerdaftar ? Colors.green.shade700 : Colors.red.shade700,
                  size: 14,
                ),
              ],
            ),
          
          ],
        ),
        actions: [
          IconButton(
            
            icon: CircleAvatar(
              radius: 21,
              backgroundColor: Colors.blue.shade100,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, size: 20, color: Colors.blue)
                  : null,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              _refreshProfil();
            },
          ),
          SizedBox(width: 8),
        ],
      ),
     body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(             
              child:
          Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [          
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                       color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(" ${DateFormat('MMM d, yyyy').format(DateTime.now())}", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          _jamAbsenMasuk,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),  
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
  
                  MapCard(
                    userPosition: _userPosition,
                    latLab: _locationService.latLabACSL,
                    longLab: _locationService.longLabACSL,
                  ),

                  if (!_wajahSudahTerdaftar) ...[
                    const SizedBox(height: 24),
                    const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      "Anda wajib mendaftarkan wajah Anda sebelum bisa melakukan presensi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _daftarkanWajahBaru,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('DAFTARKAN WAJAH SEKARANG'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 45),
                    ElevatedButton.icon(
                      onPressed: _prosesAbsenMasuk,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('ABSEN MASUK'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height:1),
                ],
              ),
            ),            
          ),
          if (_wajahSudahTerdaftar)
          const SliverFillRemaining(
                  hasScrollBody: false, 
                  child: Align(
                    alignment: Alignment.bottomCenter, 
                    child: RiwayatAbsenTerbaru(),
                  ),
                ),
              ],
            ),
          );
        }
      }