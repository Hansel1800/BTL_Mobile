// ignore_for_file: use_build_context_synchronously

import 'package:do_an_quan_ao/Services/auth_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  String selectedRole = "User";
  bool isLoading = false;
  bool isPasswordHidden = true;

  // instance for Auth service for authentication logic
  final AuthService _authService = AuthService();

  // ham de dang ki
  void _signup() async {
    setState(() {
      isLoading = true;
    });
    // ham goi tu authService voi nguoi dung dang nhap
    String? result = await _authService.signup(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      role: selectedRole,
    );
    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đăng nhập thành công")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đăng ký thất bại $result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset("assets/images/SignIn.png"),

              // ô tên
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  hintText: "Hãy nhập tên của bạn",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              //ô email
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "Hãy nhập email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              //  password
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Hãy nhập mật khẩu",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: isPasswordHidden, // che mk
              ),
              const SizedBox(height: 20),

              // dropdown chon role
              DropdownButtonFormField(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: "Vai trò",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                items: ["Admin", "User"].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedRole = newValue!; // cap nhat su lua chon vai tro
                  });
                },
              ),
              const SizedBox(height: 20),
              // Nut dang ky
              const SizedBox(height: 20),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signup,
                        child: Text("Đăng Ký"),
                      ),
                    ),
              const SizedBox(height: 20),
              // chuan bi dang ki
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    "Đã có Tài Khoản ",
                    style: TextStyle(fontSize: 18),
                  ),

                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Đăng nhập ngay",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
