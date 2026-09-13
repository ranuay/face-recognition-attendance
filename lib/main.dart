import 'package:flutter/material.dart';
import 'package:pi/Pages/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Supabase.initialize(
    url: 'https://mcqedvwbwfswbsblchcz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jcWVkdndid2Zzd2JzYmxjaGN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwMzk0NDUsImV4cCI6MjA5NDYxNTQ0NX0.Waqjdv4qOaH-EPpax04fqx7NCl5LWXYzUgd3oFKOQAI',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(canvasColor: Color(0xFFF5F5F5), buttonTheme: ButtonThemeData( buttonColor: Color(0xFFF5F5F5))),
    );
  }
}