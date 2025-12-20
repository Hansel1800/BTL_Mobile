import 'package:flutter/material.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: const BoxDecoration(color: Color(0xFFEBE4DB), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.black),
            onPressed: () => Navigator.pushAndRemoveUntil(
                context, MaterialPageRoute(builder: (_) => const UserMainScreen()), (route) => false),
          ),
        ),
        title: const Text('Thanh toán thành công', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
               // Steps
               Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepCircle('1', false),
                  _buildStepLine(),
                  _buildStepCircle('2', false),
                  _buildStepLine(),
                  _buildStepCircle('3', true), // Completed
                ],
              ),
              const Spacer(),
              Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFEBE4DB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 60, color: Color(0xFFC69C6D)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Đặt hàng thành công!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cảm ơn bạn đã mua sắm tại cửa hàng.\nĐơn hàng của bạn đang được xử lý.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                         context, MaterialPageRoute(builder: (_) => const UserMainScreen()), (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC69C6D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tiếp tục mua sắm'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCircle(String step, bool isActive) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC69C6D) : const Color(0xFFEBE4DB),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        step,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: const Color(0xFFEBE4DB),
    );
  }
}
