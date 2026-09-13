import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();

  final namaLengkapController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isObscured = true;

  void register() async {
    final namaLengkap = namaLengkapController.text.trim();
    final email = emailController.text;
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (namaLengkap.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('nama lengkap wajib diisi')),
        );
      }
      return;
    }

    if (password != confirmPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('password tidak cocok')),
        );
      }
      return;
    }

    try {
      await authService.signUpWithEmail(email, password, namaLengkap);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi gagal: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: namaLengkapController,
            decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: _isObscured,
            controller: passwordController,
            decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400),
            onPressed: () {
              setState(() {
                _isObscured = !_isObscured;
              });
            },
          ),
          ), 
          ),
          const SizedBox(height: 12),
          TextField(
            obscureText: _isObscured,
            controller: confirmPasswordController,
            decoration: InputDecoration(labelText: 'Confirm Password', suffixIcon: IconButton(
            icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400),
            onPressed: () {
              setState(() {
                _isObscured = !_isObscured;
              });
            },
          ),
          ),
          ),
            const SizedBox(height: 20),
            ElevatedButton(
            onPressed: register,
            child: const Text('Register'),
          ),
        ]
      ),
    )
  )
)
)
);
}
}