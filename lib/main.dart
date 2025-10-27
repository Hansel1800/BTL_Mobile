import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_food_moi/Services/auth_service.dart';
import 'package:do_an_food_moi/View/home_screen.dart';
import 'package:do_an_food_moi/View/Role_based_login/User/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Kiểm tra kết nối Firestore trước khi chạy app
  final authService = AuthService();
  final checkResult = await authService.checkFirestoreConnection();
  debugPrint('Firestore check: $checkResult');
  runApp(const MyApp());
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

  void iniState() {
    _initializeAuthState();
    super.initState();
  }

  void _initializeAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
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
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const LoginScreen();
    }
    if (_userRole == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _userRole == "Admin" ? AdminScreen() : UserScreen();
  }
}
