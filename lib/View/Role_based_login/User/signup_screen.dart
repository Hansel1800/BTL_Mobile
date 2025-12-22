// ignore_for_file: use_build_context_synchronously

import 'dart:math' as math;
import 'package:do_an_quan_ao/Services/auth_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignupScreen extends StatefulWidget {
  final AuthService? authService;
  const SignupScreen({super.key, this.authService});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  bool isLoading = false;
  bool isPasswordHidden = true;
  bool isNight = false;

  late final AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _signup() async {
    setState(() {
      isLoading = true;
    });

    // Validate Name (Letters and spaces only)
    final name = nameController.text.trim();
    if (name.isEmpty || !RegExp(r'^[a-zA-ZÀ-ỹ\s]+$').hasMatch(name)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Họ và tên không hợp lệ (Chỉ được nhập chữ cái)")));
        setState(() => isLoading = false);
        return;
    }

    // Validate Phone
    final phone = phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10 || !phone.startsWith('0') || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Số điện thoại không hợp lệ (Phải có 10 số và bắt đầu bằng số 0)")));
        setState(() => isLoading = false);
        return;
    }

    // Validate Email
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email không đúng định dạng (ví dụ: a@gmail.com)")));
        setState(() => isLoading = false);
        return;
    }

    String? result = await _authService.signup(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      phone: phone,
      role: "User",
    );
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập.")));
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đăng ký thất bại: $result")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Duration animDuration = const Duration(milliseconds: 1000);

    // Colors (Consistent with Login)
    final Color daySkyColor = const Color(0xFFF9F3EA);
    final Color nightSkyColor = const Color(0xFF2C2444);
    
    final Color daySunColor = const Color(0xFFFDE08E);
    final Color nightMoonColor = const Color(0xFFFDF7C3);

    final Color dayMountain1 = const Color(0xFF8B5A9C);
    final Color nightMountain1 = const Color(0xFF3F305B);

    final Color dayMountain2 = const Color(0xFF5A3E7A);
    final Color nightMountain2 = const Color(0xFF251E3E);

    return Scaffold(
      body: Stack(
        children: [
          // Background Animation
          AnimatedContainer(
            duration: animDuration,
            width: double.infinity,
            height: double.infinity,
            color: isNight ? nightSkyColor : daySkyColor,
          ),

           // Stars
          ...List.generate(6, (index) {
             final random = math.Random(index);
             return AnimatedPositioned(
               duration: animDuration,
               top: isNight ? random.nextDouble() * 300 + 50 : -20,
               left: random.nextDouble() * size.width,
               child: AnimatedOpacity(
                 duration: animDuration,
                 opacity: isNight ? 0.8 : 0.0,
                 child: Icon(Icons.star, color: Colors.white, size: random.nextDouble() * 10 + 5),
               ),
             );
          }),

          // Sun/Moon
          AnimatedPositioned(
            duration: animDuration,
            curve: Curves.easeInOut,
            top: isNight ? size.height * 0.7 : size.height * 0.1, // Higher up for signup
            left: isNight ? size.width * 0.6 - 20 : size.width * 0.8,
            child: AnimatedContainer(
              duration: animDuration,
              width: 60, height: 60, // Smaller sun for signup
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNight ? nightMoonColor : daySunColor,
                boxShadow: [
                  BoxShadow(
                    color: (isNight ? nightMoonColor : daySunColor).withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  )
                ],
              ),
            ),
          ),

          // Mountains (Adjusted height for Signup)
          AnimatedPositioned(
             duration: animDuration,
             bottom: 0, left: -50, right: -50, height: size.height * 0.3,
             child: AnimatedContainer(
               duration: animDuration,
               decoration: BoxDecoration(
                 color: isNight ? nightMountain2 : dayMountain2,
                 borderRadius: const BorderRadius.vertical(top: Radius.circular(200)),
               ),
             ),
          ),
          AnimatedPositioned(
             duration: animDuration,
             bottom: -50, left: 0, right: 0, height: size.height * 0.25,
             child: AnimatedContainer(
               duration: animDuration,
               decoration: BoxDecoration(
                 color: isNight ? nightMountain1 : dayMountain1,
                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(150), topRight: Radius.circular(0)),
               ),
             ),
          ),

          // Form Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const SizedBox(height: 10),
                   // Header Toggle Switch
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                         setState(() {
                           isNight = !isNight;
                         });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isNight ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNight ? Icons.light_mode : Icons.dark_mode,
                          color: isNight ? Colors.yellow : Colors.orange,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  AnimatedDefaultTextStyle(
                    duration: animDuration,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white : Colors.black,
                    ),
                    child: const Text("Đăng Ký Tài Khoản"),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Họ và Tên"),
                  const SizedBox(height: 8),
                  _buildTextField(
                    nameController,
                    "Họ và tên", 
                    false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ỹ\s]')),
                    ]
                  ),
                  
                  const SizedBox(height: 16),
                  _buildLabel("Số Điện Thoại"), // English label for consistency with ref image style
                  const SizedBox(height: 8),
                  _buildTextField(
                    phoneController, 
                    "Số điện thoại", 
                    false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ]
                  ),

                  const SizedBox(height: 16),
                  _buildLabel("Email"),
                  const SizedBox(height: 8),
                  _buildTextField(emailController, "Nhập email", false),

                  const SizedBox(height: 16),
                  _buildLabel("Mật Khẩu"),
                  const SizedBox(height: 8),
                  _buildTextField(passwordController, "Nhập mật khẩu", true),

                  const SizedBox(height: 30),
                  
                  // Signup Button (Arrow)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                       onTap: _signup,
                       child: Container(
                         width: 60, height: 60,
                         decoration: BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                           boxShadow: [
                             BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,5))
                           ]
                         ),
                         child: isLoading 
                           ? const Padding(padding: EdgeInsets.all(15), child: CircularProgressIndicator(strokeWidth: 2))
                           : const Icon(Icons.arrow_forward, color: Color(0xFFC85A17), size: 30),
                       ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Đã có Tài Khoản? ",
                        style: TextStyle(fontSize: 14, color: isNight ? Colors.white70 : Colors.black87),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "Đăng nhập ngay",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          )
        ],
      )
    );
  }

  Widget _buildToggleItem(String text, bool active) {
     return GestureDetector(
       onTap: () {
         setState(() {
           isNight = (text == "Night");
         });
       },
       child: AnimatedContainer(
         duration: const Duration(milliseconds: 300),
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
         decoration: BoxDecoration(
           color: active ? Colors.white : Colors.transparent,
           borderRadius: BorderRadius.circular(25),
           boxShadow: active ? [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
           ] : null
         ),
         child: Text(
           text, 
           style: TextStyle(
             fontWeight: FontWeight.bold,
             color: active ? const Color(0xFFC85A17) : Colors.grey
           )
         ),
       ),
     );
  }

  Widget _buildLabel(String text) {
    return Text(
       text, 
       style: TextStyle(
         color: isNight ? Colors.white70 : Colors.grey[700],
         fontSize: 12
       )
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool isPass, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Container(
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withOpacity(0.1) : const Color(0xFFEEE8DD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass && isPasswordHidden,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: isNight ? Colors.white : Colors.black),
        decoration: InputDecoration(
           hintText: hint,
           hintStyle: TextStyle(color: isNight ? Colors.white30 : Colors.black38),
           border: InputBorder.none,
           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
           suffixIcon: isPass ? IconButton(
             icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
             onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
           ) : null
        ),
      ),
    );
  }
}
