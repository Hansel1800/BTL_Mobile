import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/add_card_screen.dart';
import 'package:flutter/material.dart';

class UserPaymentMethodsScreen extends StatefulWidget {
  const UserPaymentMethodsScreen({super.key});

  @override
  State<UserPaymentMethodsScreen> createState() => _UserPaymentMethodsScreenState();
}

class _UserPaymentMethodsScreenState extends State<UserPaymentMethodsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: false,
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: const BoxDecoration(
            color: Color(0xFFEBE4DB),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: const BoxDecoration(
               color: Color(0xFFEBE4DB),
               shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_horiz, color: Colors.black),
              onPressed: () {},
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phương thức hiện tại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EAE4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 32,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)), // Placeholder for Visa Logo
                    alignment: Alignment.center,
                    child: const Text('VISA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thẻ Visa •••• 1234', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Hết hạn 08/27 · Tên: NGUYEN M. AN', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                   Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BFA5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Mặc định', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                      ),
                       const SizedBox(height: 4),
                       const Text('Chi tiết', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Các phương thức khác', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
             const SizedBox(height: 12),
             
             _buildMethodItem('Ví Momo', 'SĐT: 0901 234 567', 'MOMO'),
             const SizedBox(height: 12),
             _buildMethodItem('Thanh toán khi nhận hàng', 'Phù hợp cho mọi đơn hàng', 'COD'),
             
             const SizedBox(height: 24),
             
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCardScreen()));
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFFEBE4DB),
                   foregroundColor: Colors.black,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   elevation: 0,
                 ),
                 child: const Text('+ Thêm thẻ / ví mới'),
               ),
             ),
             const SizedBox(height: 16),
              SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: () {
                   Navigator.pop(context);
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFFC69C6D),
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   elevation: 0,
                 ),
                 child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
               ),
             ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMethodItem(String title, String subtitle, String type) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
           Container(
            width: 50, height: 32,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.center,
            child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Đặt làm mặc định', style: TextStyle(fontSize: 10, color: Colors.grey[800])),
              if (type != 'COD')
               const Text('Xóa', style: TextStyle(fontSize: 10, color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }
}
