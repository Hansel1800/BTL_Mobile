import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Services/auth_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/admin_home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Kiểm tra kết nối Firestore trước khi chạy app
  final authService = AuthService();
  final checkResult = await authService.checkFirestoreConnection();
  debugPrint('Firestore check: $checkResult');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatefulWidget {
  const AuthStateHandler({super.key});

  @override
  State<AuthStateHandler> createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  User? _currentUser;
  String? _userRole;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuthState();
  }

  void _initializeAuthState() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
      });
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        if (!mounted) return;
        if (userDoc.exists) {
          setState(() {
            _userRole = userDoc['role'];
          });
        }
      } //tranh viec setState neu widget disposed
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthStateHandler build - currentUser: ${_currentUser?.uid}, role: $_userRole');
    
    if (_currentUser == null) {
      debugPrint('Showing LoginScreen');
      return const LoginScreen();
    }
    if (_userRole == null) {
      debugPrint('Showing loading indicator');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    debugPrint('Showing ${_userRole == "Admin" ? "AdminScreen" : "UserMainScreen"}');
    return _userRole == "Admin" ? const AdminScreen() : const UserMainScreen();
  }
}
