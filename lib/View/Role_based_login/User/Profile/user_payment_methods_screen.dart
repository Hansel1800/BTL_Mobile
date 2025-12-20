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
  
  // Track selected card index for animation/stacking
  String? _focusedCardId;

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
        title: const Text('Quản lý thẻ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
            IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.black),
                onPressed: _showAddMethodBottomSheet,
            )
        ],
      ),
      body: StreamBuilder<List<PaymentMethod>>(
        stream: _userRepo.getPaymentMethods(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final methods = snapshot.data ?? [];
          final cards = methods.where((m) => m.type != 'COD' && m.type != 'MOMO').toList();
          final visibleCards = cards.take(5).toList();
          final others = methods.where((m) => m.type == 'COD' || m.type == 'MOMO').toList();

          // Ensure focused card logic
          if (_focusedCardId != null && !cards.any((c) => c.id == _focusedCardId)) {
             _focusedCardId = null;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Thẻ của tôi (${cards.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (visibleCards.isNotEmpty)
                    _buildWalletStack(visibleCards)
                else
                    Container(
                        height: 200, 
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(16)),
                        child: const Center(child: Text('Chưa có thẻ nào')),
                    ),
                
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Phương thức khác', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...others.map((method) => _buildMethodItem(method)),
                
                const SizedBox(height: 80), // Bottom padding
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletStack(List<PaymentMethod> cards) {
      const double cardHeight = 200;
      const double cardOffset = 60.0;
      final totalHeight = cardHeight + (cards.length - 1) * cardOffset;

      return SizedBox(
          height: totalHeight + 20, // Add some buffer
          child: Stack(
              clipBehavior: Clip.none,
              children: _buildStackContent(cards, cardHeight, cardOffset),
          ),
      );
  }
  
  // Custom Build Stack Helper
  List<Widget> _buildStackContent(List<PaymentMethod> cards, double cardHeight, double cardOffset) {
     final List<Widget> children = [];
     
     // Add non-focused cards first
     for (int i = 0; i < cards.length; i++) {
        final card = cards[i];
        if (card.id == _focusedCardId) continue; // Skip focused for now
        
        children.add(Positioned(
            top: i * cardOffset, // Keep original visual position
            left: 0, 
            right: 0,
            child: GestureDetector(
                onTap: () {
                    setState(() {
                         _focusedCardId = card.id;
                    });
                },
                child: _buildCreditCardVisual(card, i, isFocused: false),
            ),
        ));
     }

     // Now add focused one (last, so it's on top)
     if (_focusedCardId != null) {
         final index = cards.indexWhere((c) => c.id == _focusedCardId);
         if (index != -1) {
             final card = cards[index];
             children.add(Positioned(
                top: index * cardOffset, // Same position
                left: 0,
                right: 0,
                child: GestureDetector(
                    onTap: () {
                         // If already focused, navigate to detail screen
                         Navigator.push(context, MaterialPageRoute(builder: (context) => CardDetailScreen(paymentMethod: card)));
                    },
                    child: _buildCreditCardVisual(card, index, isFocused: true),
                ),
             ));
         }
     }
     
     return children;
  }              

  Widget _buildCreditCardVisual(PaymentMethod method, int index, {bool isFocused = false}) {
      final List<List<Color>> gradients = [
          [const Color(0xFF0F2027), const Color(0xFF2C5364)], 
          [const Color(0xFF373B44), const Color(0xFF4286f4)], 
          [const Color(0xFF233329), const Color(0xFF63D471)], 
          [const Color(0xFF833ab4), const Color(0xFFfd1d1d)],
      ];
      final gradient = gradients[index % gradients.length];
      
      final cardNumberRaw = method.details['cardNumber'] ?? '**** **** **** 0000';
      String displayNum = cardNumberRaw;
      if (cardNumberRaw.length >= 4) {
          displayNum = '**** **** **** ${cardNumberRaw.substring(cardNumberRaw.length - 4)}';
      }

      return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 200, 
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                    if (isFocused) 
                       BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 0))
                    else
                       BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))
                ],
                border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
            ),
            padding: const EdgeInsets.all(16), 
            child: Stack(
              children: [
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        const Icon(Icons.credit_card, color: Colors.white),
                        // Flexible or constrained text
                        Text(displayNum, style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontFamily: 'Courier')),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                 Expanded(
                                   child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                           const Text('Card Holder', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                           Text(method.subtitle.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                       ],
                                   ),
                                 ),
                                 if (isFocused)
                                   GestureDetector(
                                     onTap: () {
                                         // Detail Navigation
                                         Navigator.push(context, MaterialPageRoute(builder: (context) => CardDetailScreen(paymentMethod: method)));
                                     },
                                     child: Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                         decoration: BoxDecoration(
                                             color: Colors.white,
                                             borderRadius: BorderRadius.circular(20),
                                         ),
                                         child: const Text('Chi tiết', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                                     ),
                                   ),
                            ]
                        )
                    ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (method.isDefault)
                         const Padding(
                           padding: EdgeInsets.only(right: 4),
                           child: Text('Mặc định', style: TextStyle(color: Colors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
                         ),
                      GestureDetector(
                        onTap: () {
                          _userRepo.setDefaultPaymentMethod(_userId, method.id);
                        },
                        child: Icon(
                          method.isDefault ? Icons.star : Icons.star_border,
                          color: method.isDefault ? Colors.yellow : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      );
  }

  Widget _getPaymentIcon(String type) {
    switch (type) {
      case 'MOMO':
        return const Icon(Icons.account_balance_wallet, color: Colors.pink, size: 20);
      case 'COD':
        return const Icon(Icons.local_shipping, color: Colors.green, size: 20);
      case 'VISA':
      case 'MASTER':
      default:
        return const Icon(Icons.credit_card, color: Colors.blue, size: 20);
    }
  }

  Widget _buildMethodItem(PaymentMethod method) {
    bool isDefault = method.isDefault;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE4),
        borderRadius: BorderRadius.circular(16),
        border: isDefault ? Border.all(color: const Color(0xFFC69C6D), width: 1.5) : null,
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: _getPaymentIcon(method.type),
        ),
        title: Text(method.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(method.subtitle),
                if (isDefault)
                   const Padding(
                       padding: EdgeInsets.only(top: 4),
                       child: Text('Đã chọn làm mặc định', style: TextStyle(color: Color(0xFFC69C6D), fontSize: 12, fontWeight: FontWeight.bold)),
                   ),
            ]
        ),
        trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                if (!isDefault)
                  PopupMenuButton<String>(
                      onSelected: (val) {
                          if (val == 'default') {
                              _userRepo.setDefaultPaymentMethod(_userId, method.id);
                          } else if (val == 'delete') {
                              _userRepo.deletePaymentMethod(_userId, method.id);
                          }
                      },
                      itemBuilder: (context) => [
                          const PopupMenuItem(value: 'default', child: Text('Đặt làm mặc định')),
                          if (method.type != 'COD') const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                      ],
                      child: const Icon(Icons.more_vert, color: Colors.grey),
                  )
                else
                   // If default, maybe option to delete only if not cod? NO, can't delete default usually without switching.
                   // Just show Star
                   const Icon(Icons.star, color: Color(0xFFC69C6D)),
            ],
        ),
      ),
    );
  }
}
