import 'package:flutter/material.dart';
import 'package:pi/auth/auth_gate.dart';
import '../auth/auth_service.dart';
import '../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  String fullName = 'User';
  String? userEmail;
  String? avatarUrl;
  String capitalize(String s) => s.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');


  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final email = authService.getCurrentUseEmail();
    final name = await authService.getCurrentUserFullName();
    final avatar = await getAvatarUrl();

    if (!mounted) return;
    setState(() {
      userEmail = email;
      fullName = name?.trim().isNotEmpty == true ? name!.trim() : 'User';
      avatarUrl = avatar;
    });
  }

  Future<void> changeAvatar() async {
    await perbaruiFotoProfil();
    await loadProfile();
  }

  void logout() async {
    await authService.signOut();
    if (!mounted) return;
  
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const AuthGate()),
    (route) => false, 
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 56,
                          color: Colors.blue,
                        )
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 1,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: changeAvatar,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit, size: 14, color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            capitalize(fullName) ?? 'User',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userEmail ?? 'Email',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 20), 

          Padding(
            padding: const EdgeInsets.only(bottom: 16),
           child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, 
                foregroundColor: Colors.red,   
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: logout,
              child: const Text('Logout'),
            ),
          
          )
        ],
      ),
    );
  }
}