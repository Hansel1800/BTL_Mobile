import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/Model/user_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_profile_screen.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:do_an_quan_ao/Services/promotion_repository.dart';
import 'package:do_an_quan_ao/Model/promotion_model.dart';
import 'package:do_an_quan_ao/Model/payment_method_model.dart';
import 'package:do_an_quan_ao/Services/user_repository.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Home/user_home_screen.dart';
import 'package:do_an_quan_ao/ViewModel/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final UserRepository _userRepo = UserRepository();
  final OrderRepository _orderRepo = OrderRepository();
  final PromotionRepository _promoRepo = PromotionRepository();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  UserModel? _user;
  PaymentMethod? _selectedPaymentMethod;
  VoucherModel? _appliedVoucher;
  String _shippingMethod = 'standard'; // 'standard', 'express'
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _userRepo.getUser(_userId);
    if (!mounted) return;
    setState(() {
      _user = user;
    });

    // Check First Order Discount
    final hasOrdered = await _orderRepo.hasUserOrdered(_userId);
    if (!hasOrdered) {
        final voucher = await _promoRepo.getVoucherByCode('FIRST10');
        if (voucher != null && voucher.isActive && voucher.startDate.isBefore(DateTime.now()) && voucher.endDate.isAfter(DateTime.now())) {
            if (mounted) {
                setState(() {
                    _appliedVoucher = voucher;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã áp dụng mã giảm giá ${voucher.code} cho đơn hàng đầu tiên!')));
            }
        }
    }
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(amount)}đ";
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    final shippingFee = _shippingMethod == 'standard' ? 25000.0 : 45000.0;
    
    double discount = 0.0;
    if (_appliedVoucher != null) {
        if (_appliedVoucher!.discountType == 'percent') {
            discount = subtotal * (_appliedVoucher!.discountValue / 100);
        } else {
            discount = _appliedVoucher!.discountValue;
        }
        if (subtotal < _appliedVoucher!.minOrderValue) {
            discount = 0;
        }
    }
    
    final total = (subtotal + shippingFee - discount) > 0 ? (subtotal + shippingFee - discount) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Thanh toán nhanh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Hoàn tất đơn hàng cho sản phẩm này', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        centerTitle: true,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepCircle('1', false),
                _buildStepLine(),
                _buildStepCircle('2', true), // Current
                _buildStepLine(),
                _buildStepCircle('3', false),
              ],
            ),
            const SizedBox(height: 24),
            _buildAddressSection(),
            const SizedBox(height: 16),
            _buildDeliveryMethodSection(),
            const SizedBox(height: 16),
            _buildPaymentMethodSection(),
            const SizedBox(height: 16),
            _buildOrderSummary(cartItems),
            const SizedBox(height: 16),
            _buildCostDetails(subtotal, shippingFee, discount, total),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Thanh toán', style: TextStyle(color: Colors.grey)),
                Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEBE4DB),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Xem giỏ hàng'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _processOrder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC69C6D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đặt hàng'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _processOrder() {
    if (_user == null) return;
    
    if (_user!.address.isEmpty || _user!.phoneNumber.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thông tin còn thiếu'),
          content: const Text('Vui lòng cập nhật số điện thoại và địa chỉ giao hàng trước khi đặt hàng.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())).then((_) => _loadUserData());
              },
              child: const Text('Cập nhật ngay'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt hàng thành công!')));
    // Clear cart and navigate home
    ref.read(cartProvider.notifier).clearCart();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const UserHomeScreen()), (route) => false);
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Địa chỉ giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())).then((_) => _loadUserData());
                },
                child: const Text('Thay đổi', style: TextStyle(color: Color(0xFFC69C6D), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_user != null) ...[
             Text('${_user!.fullName.isNotEmpty ? _user!.fullName : _user!.name} · ${_user!.phoneNumber.isNotEmpty ? _user!.phoneNumber : "Chưa có SĐT"}', style: const TextStyle(fontWeight: FontWeight.bold)),
             const SizedBox(height: 4),
             Text(_user!.address.isNotEmpty ? _user!.address : 'Chưa có địa chỉ giao hàng', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ] else 
             const Center(child: CircularProgressIndicator()),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFEBE4DB).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('Mặc định', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          )
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phương thức giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRadioItem('Giao nhanh', 'Dự kiến: hôm nay - ngày mai', '25.000đ', 'standard'),
          const Divider(),
          _buildRadioItem('Tiết kiệm', '3 - 5 ngày làm việc', 'Miễn phí', 'saver'),
        ],
      ),
    );
  }

  Widget _buildRadioItem(String title, String subtitle, String price, String value) {
    final isSelected = _shippingMethod == value;
    return InkWell(
      onTap: () => setState(() => _shippingMethod = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: const Color(0xFFC69C6D)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<List<PaymentMethod>>(
            stream: _userRepo.getPaymentMethods(_userId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('Chưa có phương thức thanh toán');
              
              final methods = snapshot.data!;
              final defaultMethod = methods.firstWhere((m) => m.isDefault, orElse: () => methods.first); // fallback

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFEBE4DB).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                     Expanded(
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(defaultMethod.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                           Text(defaultMethod.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                         ],
                       ),
                     ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Text('Thẻ ngân hàng', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('Visa, Master, ATM nội địa', style: TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 8),
          const Text('Ví điện tử', style: TextStyle(fontWeight: FontWeight.w500)),
          const Text('Momo, ZaloPay, VNPay...', style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(List<CartItem> cartItems) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tóm tắt đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...cartItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.product.imageUrl,
                    width: 60, height: 60, fit: BoxFit.cover,
                    placeholder: (_,__) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Màu: ${item.selectedColor ?? "N/A"} - Size: ${item.selectedSize ?? "N/A"} - SL: ${item.quantity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text(_formatCurrency(item.product.price * item.quantity), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCostDetails(double subtotal, double shipping, double discount, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildRow('Tạm tính', subtotal),
          _buildRow('Phí vận chuyển', shipping),
          _buildRow('Mã giảm giá', discount),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(_formatCurrency(value), style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStepCircle(String text, bool isActive) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC69C6D) : const Color(0xFFEBE4DB),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40, height: 2,
      color: const Color(0xFFEBE4DB),
    );
  }
}
