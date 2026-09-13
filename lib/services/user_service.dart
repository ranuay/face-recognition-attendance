import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> getAvatarUrl() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  try {
    final response = await supabase
        .from('pengguna')
        .select('avatar_url')
        .eq('id', user.id)
        .maybeSingle();
    return response?['avatar_url'] as String?;
  } catch (e) {
    return null;
  }
}

Future<void> perbaruiFotoProfil() async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    print("Error: Pengguna belum login!");
    return;
  }

  try {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, 
      maxWidth: 512,    
      maxHeight: 512,   
    );

    if (pickedFile == null) return;

    final File fileGambar = File(pickedFile.path);

    final String namaPath = '${user.id}.jpg';

    print("Mulai mengunggah gambar...");

    await supabase.storage.from('avatars').upload(
      namaPath,
      fileGambar,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: true,
      ),
    );

    final String urlFoto = supabase.storage.from('avatars').getPublicUrl(namaPath);

    final String urlFotoDenganTimestamp = "$urlFoto?t=${DateTime.now().millisecondsSinceEpoch}";
    await supabase
        .from('pengguna')
        .update({'avatar_url': urlFotoDenganTimestamp})
        .eq('id', user.id);

    print("Sukses! Foto profil berhasil diperbarui.");
    print("Link foto: $urlFoto");
  } catch (error) {
    print("Terjadi kesalahan saat memperbarui foto: $error");
  }
}