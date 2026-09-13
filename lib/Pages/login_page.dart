import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import 'register_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isObscured = true;

  void login() async {
    final email = emailController.text;
    final password = passwordController.text;

    try {
      await authService.signInWithEmail(email, password);
    }

    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton(
                      onPressed: login,
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const RegisterPage())
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const IgnorePointer(
                          child: Text("Don't have an account? "),
                        ),
                        Text(
                          "Sign up",
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                        ),
                      ]
                    )
                      
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}