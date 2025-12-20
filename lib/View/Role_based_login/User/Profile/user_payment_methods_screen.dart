import 'package:do_an_quan_ao/Model/payment_method_model.dart';
import 'package:do_an_quan_ao/Services/user_repository.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/add_card_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/card_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserPaymentMethodsScreen extends StatefulWidget {
  const UserPaymentMethodsScreen({super.key});

  @override
  State<UserPaymentMethodsScreen> createState() => _UserPaymentMethodsScreenState();
}

class _UserPaymentMethodsScreenState extends State<UserPaymentMethodsScreen> {
  final UserRepository _userRepo = UserRepository();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _showAddMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: const Text('Thẻ Quốc tế (Visa/Master)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCardScreen()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.pink),
                title: const Text('Ví MoMo'),
                onTap: () {
                  Navigator.pop(context);
                  _showMomoDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.green),
                title: const Text('Thanh toán khi nhận hàng (COD)'),
                onTap: () {
                  Navigator.pop(context);
                  _showCODDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMomoDialog() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Liên kết Ví MoMo'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại MoMo',
            hintText: 'Nhập số điện thoại (10 số)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.length == 10 && phone.startsWith('0') && int.tryParse(phone) != null) {
                _addMomoMethod(phone);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Số điện thoại không hợp lệ (phải có 10 số và bắt đầu bằng 0)'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Liên kết'),
          )
        ],
      ),
    );
  }

  void _showCODDialog() {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông tin giao hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const Text('Vui lòng nhập thông tin để chúng tôi liên hệ giao hàng.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ nhận hàng', hintText: 'Nhập địa chỉ của bạn', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại liên hệ', hintText: 'Nhập số điện thoại', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
             onPressed: () async {
               if (addressController.text.isEmpty || phoneController.text.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin'), backgroundColor: Colors.red),
                 );
                 return;
               }
               
               if (phoneController.text.length != 10 || !phoneController.text.startsWith('0')) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Số điện thoại không hợp lệ'), backgroundColor: Colors.red),
                 );
                 return;
               }
               
               // Save Payment Method
               await _addCODMethod();
               
               // Update User Profile
               await _userRepo.updateUserProfile(_userId, {
                 'address': addressController.text.trim(),
                 'phoneNumber': phoneController.text.trim(),
               });
               
               if (context.mounted) {
                 Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Đã cập nhật địa chỉ và thêm phương thức COD'), backgroundColor: Colors.green),
                 );
               }
             }, 
             child: const Text('Xác nhận')
          )
        ],
      ),
    );
  }

  Future<void> _addMomoMethod(String phone) async {
    final method = PaymentMethod(
      id: '',
      type: 'MOMO',
      title: 'Ví MoMo',
      subtitle: 'SĐT: $phone',
      details: {'phoneNumber': phone},
    );
    await _userRepo.addPaymentMethod(_userId, method);
  }

  Future<void> _addCODMethod() async {
    final method = PaymentMethod(
      id: '',
      type: 'COD',
      title: 'Thanh toán khi nhận hàng',
      subtitle: 'Phù hợp cho mọi đơn hàng',
    );
    await _userRepo.addPaymentMethod(_userId, method);
  }

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
          decoration: const BoxDecoration(color: Color(0xFFEBE4DB), shape: BoxShape.circle),
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
      body: StreamBuilder<List<PaymentMethod>>(
        stream: _userRepo.getPaymentMethods(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Text('Chưa có phương thức thanh toán nào'),
                   const SizedBox(height: 20),
                   ElevatedButton(
                     onPressed: _showAddMethodBottomSheet,
                     child: const Text('Thêm phương thức mới'),
                   )
                 ],
               ),
             );
          }

          final methods = snapshot.data!;
          // Find default, or first one if no default set (fallback)
          PaymentMethod? defaultMethod;
          try {
             defaultMethod = methods.firstWhere((m) => m.isDefault);
          } catch (e) {
             defaultMethod = methods.first;
          }
          
          final otherMethods = methods.where((m) => m.id != defaultMethod!.id).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (methods.isNotEmpty) ...[
                  const Text('Phương thức hiện tại', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildMethodItem(defaultMethod!, isDefault: true),
                ],
                
                if (otherMethods.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Text('Các phương thức khác', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...otherMethods.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildMethodItem(m),
                  )),
                ],
                
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _showAddMethodBottomSheet,
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
                     onPressed: () => Navigator.pop(context),
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
          );
        },
      ),
    );
  }
  
  Widget _buildMethodItem(PaymentMethod method, {bool isDefault = false}) {
    IconData iconData;
    Color iconColor;
    
    if (method.type == 'MOMO') {
      iconData = Icons.account_balance_wallet;
      iconColor = Colors.pink;
    } else if (method.type == 'COD') {
      iconData = Icons.local_shipping;
      iconColor = Colors.green;
    } else {
      iconData = Icons.credit_card;
      iconColor = Colors.blue;
    }

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
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(method.subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isDefault)
                TextButton(
                  onPressed: () => _userRepo.setDefaultPaymentMethod(_userId, method.id),
                  style: ButtonStyle(
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.grey.withOpacity(0.1); 
                        }
                        return null;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                      (states) {
                        if (states.contains(WidgetState.hovered)) {
                          return const Color(0xFFD29062);
                        }
                        return Colors.grey[800];
                      },
                    ),
                    padding: WidgetStateProperty.all(EdgeInsets.zero),
                    minimumSize: WidgetStateProperty.all(Size.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
                  ),
                  child: const Text('Đặt làm mặc định', style: TextStyle(fontSize: 10)),
                )
              else 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Mặc định', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                
              const SizedBox(height: 4),
              isDefault 
                ? GestureDetector(
                    onTap: () {
                      // Only navigate for Visa/Master cards as they have the 3D visual
                      // Or maybe all? CardDetailScreen can handle MOMO/COD if we mock it?
                      // User asked: "tạo thêm màn hình xem chi tiết thẻ khi ấn vào cũng quay lật 3D" -> Implies Card.
                      // For now, let's enable it for cards only or generic but visuals might look weird if no number.
                      // CardDetailScreen uses defaults if missing.
                      // But let's check type.
                      if (method.type == 'VISA' || method.type == 'MASTER' || method.details.containsKey('cardNumber')) {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => CardDetailScreen(paymentMethod: method)));
                      }
                    },
                    child: Text(
                      (method.details.containsKey('cardNumber')) ? 'Chi tiết' : '', 
                      style: const TextStyle(fontSize: 10, color: Colors.grey, decoration: TextDecoration.underline)
                    ),
                  )
                : GestureDetector(
                    onTap: () => _userRepo.deletePaymentMethod(_userId, method.id),
                    child: const Text('Xóa', style: TextStyle(fontSize: 10, color: Colors.red)),
                  ),
            ],
          )
        ],
      ),
    );
  }
}
