# PI Attendance App

Aplikasi absensi berbasis Flutter yang menggabungkan verifikasi wajah, lokasi pengguna, dan integrasi Supabase untuk pencatatan kehadiran secara real-time.

## Fitur Utama

- Login dan registrasi akun pengguna
- Verifikasi wajah menggunakan kamera dan model ML
- Cek lokasi pengguna untuk memastikan berada dalam radius kantor/sekolah
- Presensi masuk dengan validasi wajah dan lokasi
- Riwayat absen per bulan
- Profil pengguna dengan data dan status wajah
- Peta lokasi user dengan Flutter Map
- Integrasi dengan Supabase untuk autentikasi, database, dan storage

## Teknologi yang Digunakan

- Flutter
- Dart
- Supabase
- Google ML Kit Face Detection
- TensorFlow Lite / tflite_flutter
- Geolocator
- Camera
- Flutter Map
- Provider
- Lottie

## Struktur Folder

```bash
.
├── android/
├── ios/
├── lib/
│   ├── Pages/
│   ├── auth/
│   ├── services/
│   ├── widget/
│   ├── main.dart
│   └── ...
├── assets/
├── test/
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── ...
```

## Prasyarat

Pastikan perangkat Anda sudah memiliki:

- Flutter SDK versi 3.9 atau yang lebih baru
- Dart SDK
- Android Studio / VS Code dengan extension Flutter
- Emulator atau perangkat Android/iOS yang dapat dijalankan
- Akun Supabase aktif

## Instalasi

1. Clone repository ini

```bash
git clone <repository-url>
cd pi
```

2. Install dependency

```bash
flutter pub get
```

3. Konfigurasi Supabase

Aplikasi ini sudah menggunakan Supabase di `lib/main.dart`. Jika diperlukan, sesuaikan URL dan `anonKey` dengan project Supabase Anda.

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

4. Jalankan aplikasi

```bash
flutter run
```

## Catatan Penting

- Model wajah yang digunakan berada di `assets/models/mobilefacenet.tflite`
- Aplikasi memerlukan izin akses kamera dan lokasi pada perangkat pengguna
- Fitur absensi sangat bergantung pada tabel dan fungsi di backend Supabase, seperti:
  - `pengguna`
  - `presensi`
  - `verify_face` (RPC function)
  - storage untuk avatar jika dipakai pada fitur profil

## Alur Aplikasi

1. User masuk ke aplikasi melalui login/register
2. User akan divalidasi dengan session autentikasi Supabase
3. Saat absen, aplikasi mengecek lokasi user dalam radius yang ditentukan
4. Aplikasi membuka kamera dan mendeteksi wajah
5. Wajah diproses menjadi embedding dan dibandingkan dengan data wajah yang sudah tersimpan
6. Jika valid, data presensi disimpan ke database Supabase

## Pengembangan Lanjutan

Beberapa peningkatan yang dapat dilakukan:

- Penambahan logout session yang lebih aman
- Validasi radius lokasi configurable dari backend
- UI/UX yang lebih modern dan responsif
- Notifikasi push untuk status absensi
- Support multi-role (admin, karyawan, supervisor)

## Lisensi

Proyek ini belum mencantumkan lisensi resmi. Jika ingin dipublikasikan ke publik, pastikan menambahkan lisensi yang sesuai sebelum deployment.

## Kontributor

Silakan sesuaikan dengan nama tim atau pembuat project Anda.
