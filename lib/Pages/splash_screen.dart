import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pi/auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            Lottie.asset(
              'assets/Scan.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'Prensensi Laboratorium',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Prensensi Lab v1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}