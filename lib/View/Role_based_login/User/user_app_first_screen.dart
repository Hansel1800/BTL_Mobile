import 'package:flutter/material.dart';

class UserAppFirstScreen extends StatefulWidget {
  const UserAppFirstScreen({super.key});

  @override
  State<UserAppFirstScreen> createState() => _UserAppFirstScreenState();
}

class _UserAppFirstScreenState extends State<UserAppFirstScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("User App")));
  }
}
