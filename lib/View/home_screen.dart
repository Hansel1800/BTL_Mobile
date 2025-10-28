import 'package:do_an_quan_ao/Services/auth_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:flutter/material.dart';

final AuthService _authService = AuthService();

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text("Admin screen"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _authService.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text("Đăng suất"),
        ),
      ),
    );
  }
}

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text("User screen"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 166, 98, 98),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("Xin chào Thành")],
        ),
      ),
    );
  }
}
