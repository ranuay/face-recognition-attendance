import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingScreen extends StatelessWidget {
  const LottieLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/loading.json', 
              width: 200, 
              height: 200,
              repeat: true,
            ),
            const SizedBox(height: 16),
            const Text("Memuat data...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}