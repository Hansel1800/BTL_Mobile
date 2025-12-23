
import 'dart:math' as math;
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:do_an_quan_ao/Services/auth_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/admin_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;
  bool isLoading = false;
  bool isNight = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async {
    setState(() {
      isLoading = true;
    });
    String? result = await _authService.login(
      email: emailController.text,
      password: passwordController.text,
    );
    setState(() {
      isLoading = false;
    });

    if (result != "Admin" && result != "User") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thất bại: $result")),
      );
    }
    // No navigation needed here, AuthStateHandler listens to stream changes
    // and will rebuild automatically.
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Duration animDuration = const Duration(milliseconds: 1000);

    // Colors
    final Color daySkyColor = const Color(0xFFF9F3EA); // Beige
    final Color nightSkyColor = const Color(0xFF2C2444); // Dark Purple
    
    final Color daySunColor = const Color(0xFFFDE08E);
    final Color nightMoonColor = const Color(0xFFFDF7C3);

    final Color dayMountain1 = const Color(0xFF8B5A9C);
    final Color nightMountain1 = const Color(0xFF3F305B);

    final Color dayMountain2 = const Color(0xFF5A3E7A);
    final Color nightMountain2 = const Color(0xFF251E3E);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Sky Background
          AnimatedContainer(
            duration: animDuration,
            width: double.infinity,
            height: double.infinity,
            color: isNight ? nightSkyColor : daySkyColor,
          ),

          // 2. Stars (Visible only at night)
          ...List.generate(6, (index) {
             final random = math.Random(index);
             return AnimatedPositioned(
               duration: animDuration,
               top: isNight ? random.nextDouble() * 300 + 50 : -20, // Move up/down
               left: random.nextDouble() * size.width,
               child: AnimatedOpacity(
                 duration: animDuration,
                 opacity: isNight ? 0.8 : 0.0,
                 child: Icon(Icons.star, color: Colors.white, size: random.nextDouble() * 10 + 5),
               ),
             );
          }),


          // 3. Sun / Moon
          AnimatedPositioned(
            duration: animDuration,
            curve: Curves.easeInOut,
            // Day: Top Right, Night: Center Behind Mountain? Or Top Left?
            // Ref image shows sun setting or behind. Let's make it move down/center
            top: isNight ? size.height * 0.6 : size.height * 0.15,
            left: isNight ? size.width * 0.3 - 40 : size.width * 0.7, // Moves from right to center
            /* Or based on user request "hạ xuống núi":
               Day: Higher up. 
               Night: Lower down (behind mountain).
            */
            child: AnimatedContainer(
              duration: animDuration,
              width: 80, 
              height: 80,
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

          // 4. Mountains
          // Back Mountain
          AnimatedPositioned(
             duration: animDuration,
             bottom: 0,
             left: -50,
             right: -50,
             height: size.height * 0.4,
             child: AnimatedContainer(
               duration: animDuration,
               decoration: BoxDecoration(
                 color: isNight ? nightMountain2 : dayMountain2,
                 borderRadius: const BorderRadius.vertical(top: Radius.circular(200)),
               ),
             ),
          ),
          
          // Front Mountain/Trees
          AnimatedPositioned(
             duration: animDuration,
             bottom: -50,
             left: 0,
             right: 0,
             height: size.height * 0.35,
             child: AnimatedContainer(
               duration: animDuration,
               decoration: BoxDecoration(
                 color: isNight ? nightMountain1 : dayMountain1,
                 // Simple approximation of the hill shape
                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(150), topRight: Radius.circular(0)),
               ),
             ),
          ),
          
           // Trees (Simple Rectangles/Circles for abstraction)
           AnimatedPositioned(
             duration: animDuration,
             bottom: 80,
             left: 60,
             child: Column(
               children: [
                 AnimatedContainer(
                   duration: animDuration,
                   width: 50, height: 70, 
                   decoration: BoxDecoration(
                     color: isNight ? const Color(0xFF221133) : const Color(0xFF4A2C6A),
                     borderRadius: BorderRadius.circular(25)
                   )
                 ),
                 Container(width: 5, height: 20, color: Colors.black26),
               ],
             ),
           ),
           AnimatedPositioned(
             duration: animDuration,
             bottom: 120,
             right: 60,
             child: Column(
               children: [
                 AnimatedContainer(
                   duration: animDuration,
                   width: 40, height: 60, 
                   decoration: BoxDecoration(
                      color: isNight ? const Color(0xFF221133) : const Color(0xFF4A2C6A),
                      borderRadius: BorderRadius.circular(20)
                   )
                 ),
                 Container(width: 5, height: 20, color: Colors.black26),
               ],
             ),
           ),


          // 5. Foreground Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header Time/Status (Mock)
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Text('9:41', style: TextStyle(color: isNight ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                  //     Text('LTE - 100%', style: TextStyle(color: isNight ? Colors.white70 : Colors.black54, fontSize: 10)),
                  //   ],
                  // ),
                  
                  const SizedBox(height: 30),
                  
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
                  
                  const SizedBox(height: 40),
                  
                  // Welcome Text
                  AnimatedDefaultTextStyle(
                    duration: animDuration,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isNight ? Colors.white : Colors.black,
                    ),
                    child: const Text("Mãnh Hổ Vương"), // Or Dynamic text?
                  ),
                  const SizedBox(height: 8),
                  AnimatedDefaultTextStyle(
                     duration: animDuration,
                     style: TextStyle(
                       fontSize: 14,
                       color: isNight ? Colors.white70 : Colors.grey[600],
                     ),
                     child: const Text("Chào mừng đến với cửa hàng của chúng tôi!"),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Form
                  _buildLabel("Email"),
                  const SizedBox(height: 8),
                  _buildTextField(emailController, "Vui lòng nhập email", false),
                  
                  const SizedBox(height: 20),
                  _buildLabel("Mật khẩu"),
                  const SizedBox(height: 8),
                  _buildTextField(passwordController, "Vui lòng nhập mật khẩu", true),
                  
                  const SizedBox(height: 10),
                  // Align(
                  //   alignment: Alignment.centerRight,
                  //   child: TextButton(
                  //     onPressed: () {}, 
                  //     child: Text("Forgot password?", style: TextStyle(color: isNight ? Colors.white70 : Colors.grey)),
                  //   ),
                  // ),

                  // Login Button (Arrow)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                       onTap: login,
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
                  
                  const SizedBox(height: 40),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Chưa có Tài Khoản? ",
                        style: TextStyle(fontSize: 14, color: isNight ? Colors.white70 : Colors.black87),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          "Đăng ký ngay",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange, // Matches arrow
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleItem(String text, bool active) {
     return GestureDetector(
       onTap: () {
         setState(() {
           isNight = (text == "Night Login");
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

  Widget _buildTextField(TextEditingController controller, String hint, bool isPass) {
    return Container(
      decoration: BoxDecoration(
        color: isNight ? Colors.white.withOpacity(0.1) : const Color(0xFFEEE8DD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass && isPasswordHidden,
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
