import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String namaLengkap,
  ) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama_lengkap': namaLengkap,
        'email': email,
      },
    );

    final userId = response.user?.id;
    if (userId != null) {
      await _supabase.from('pengguna').upsert({
        'id': userId,
        'email': email,
        'nama_lengkap': namaLengkap,
      });
    }

    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  String? getCurrentUseEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  Future<String?> getCurrentUserFullName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final nama = user.userMetadata?['nama_lengkap'] as String?;
    if (nama != null && nama.trim().isNotEmpty) {
      return nama.trim();
    }

    final response = await _supabase
        .from('pengguna')
        .select('nama_lengkap')
        .eq('id', user.id)
        .maybeSingle();

    return response?['nama_lengkap'] as String?;
  }
}