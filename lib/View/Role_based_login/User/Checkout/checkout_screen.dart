import 'package:cached_network_image/cached_network_image.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:do_an_quan_ao/Model/user_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_profile_screen.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:do_an_quan_ao/Services/promotion_repository.dart';
import 'package:do_an_quan_ao/Model/promotion_model.dart';
import 'package:do_an_quan_ao/Model/promotion_model.dart';
import 'package:do_an_quan_ao/Model/payment_method_model.dart';
import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/Services/user_repository.dart';
import 'package:do_an_quan_ao/Services/user_repository.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_profile_detail_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_order_history_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_payment_methods_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/ViewModel/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:do_an_quan_ao/View/Widgets/success_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Checkout/payment_success_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? voucherCode;
  
  const CheckoutScreen({super.key, this.voucherCode});

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
  PaymentMethod? _displayCard;
  VoucherModel? _appliedVoucher;
  String _shippingMethod = 'standard'; // 'standard', 'express'
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
  
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

    // Check Applied Voucher from Cart
    if (widget.voucherCode != null && widget.voucherCode!.isNotEmpty) {
        final voucher = await _promoRepo.getVoucherByCode(widget.voucherCode!);
        if (voucher != null && voucher.isActive) {
             if (mounted) {
                 setState(() {
                     _appliedVoucher = voucher;
                 });
             }
        }
    } else {
        // Only check First Order if no voucher was applied from cart
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

    // Auto-switch to Saver if address missing
    if (mounted && (_user?.address.isEmpty ?? true) && _shippingMethod == 'standard') {
        setState(() {
            _shippingMethod = 'saver';
        });
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
    final shippingFee = _shippingMethod == 'standard' ? _calculateShippingFeeVal(_user?.city ?? '') : 0.0;
    
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
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
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
            _buildCostDetails(subtotal, shippingFee, total),
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

  void _processOrder() async {
    if (_user == null) return;
    
    // User Requirement: Must enter address if "Giao nhanh" (standard) is selected
    if (_shippingMethod == 'standard' && (_user!.address.isEmpty || _user!.address.trim().isEmpty)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thiếu địa chỉ giao hàng'),
          content: const Text('Bạn đã chọn Giao nhanh. Vui lòng cập nhật địa chỉ để tiếp tục.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileDetailScreen())).then((_) => _loadUserData());
              },
              child: const Text('Cập nhật ngay'),
            ),
          ],
        ),
      );
      return;
    }

    // General validation (Phone is always needed)
    if (_user!.phoneNumber.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng cập nhật số điện thoại')));
       return;
    }

    // Recalculate totals
    final cartItems = ref.read(cartProvider);
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    final shippingFee = _shippingMethod == 'standard' ? _calculateShippingFeeVal(_user?.city ?? '') : 0.0;
    
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

    // Create Order Items
    final orderItems = cartItems.map((item) {
        return OrderItem(
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity,
            price: item.price, // access getter for correct variant price
            imageUrl: item.image, // access getter for correct variant image
            size: item.selectedSize,
            color: item.selectedColor,
        );
    }).toList();

    // Create Order Object
    final order = Order(
        id: '', // Generated by repo
        userId: _userId,
        customerName: _user!.fullName.isNotEmpty ? _user!.fullName : _user!.name,
        customerPhone: _user!.phoneNumber,
        customerAddress: _user!.address,
        products: orderItems,
        totalPrice: total,
        status: 'Chờ xác nhận',
        paymentMethod: _selectedPaymentMethod?.title ?? 'Thanh toán khi nhận hàng',
        createdAt: DateTime.now(),
        note: _noteController.text.trim(),
    );

    try {
        await _orderRepo.addOrder(order);
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi đặt hàng: $e')));
        return;
    }

    if (!mounted) return;

    ref.read(cartProvider.notifier).clearCart();
    
    // Navigate to Success Screen
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()), 
      (route) => false
    );
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
              const Text('Thông tin giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileDetailScreen())).then((_) => _loadUserData());
                },
                child: const Text('Thay đổi', style: TextStyle(color: Color(0xFFC69C6D), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_user != null) ...[
             Text('${(_user!.fullName.isNotEmpty ? _user!.fullName : _user!.name).trim()} · ${(_user!.phoneNumber.isNotEmpty ? _user!.phoneNumber : "Chưa có SĐT").trim()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
             const SizedBox(height: 4),
             Text("Địa chỉ: "+(_user!.address.isNotEmpty ? _user!.address.trim() : 'Chưa có địa chỉ giao hàng'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ] else 
             const Center(child: CircularProgressIndicator()),
          
           const SizedBox(height: 12),
           TextField(
             controller: _noteController,
             decoration: InputDecoration(
               hintText: 'Ghi chú cho đơn hàng (tùy chọn)',
               hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
               border: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(8),
                 borderSide: BorderSide(color: Colors.grey[300]!),
               ),
               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
             ),
             style: const TextStyle(fontSize: 13),
             maxLines: 1,
           ),
           const SizedBox(height: 12),
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //   width: double.infinity,
          //   decoration: BoxDecoration(color: const Color(0xFFEBE4DB).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
          //   alignment: Alignment.center,
          //   child: const Text('Mặc định', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          // )
        ],
      ),
    );
  }

  Widget _buildDeliveryMethodSection() {
    final hasAddress = _user != null && _user!.address.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phương thức giao hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildRadioItem(
            'Giao nhanh', 
            hasAddress ? 'Dự kiến: hôm nay - ngày mai' : 'Cần cập nhật địa chỉ', 
            hasAddress ? _formatCurrency(_calculateShippingFeeVal(_user?.city ?? '')) : '--', 
            'standard',
            enabled: hasAddress,
          ),
          const Divider(),
          _buildRadioItem('Tiết kiệm', '3 - 5 ngày làm việc', 'Miễn phí', 'saver'),
        ],
      ),
    );
  }

  Widget _buildRadioItem(String title, String subtitle, String price, String value, {bool enabled = true}) {
    final isSelected = _shippingMethod == value;
    return InkWell(
      onTap: enabled ? () => setState(() => _shippingMethod = value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, 
              color: enabled ? const Color(0xFFC69C6D) : Colors.grey[300]
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: enabled ? Colors.black : Colors.grey)),
                  Text(subtitle, style: TextStyle(color: enabled ? Colors.grey : Colors.grey[400], fontSize: 10)),
                ],
              ),
            ),
            Text(price, style: TextStyle(fontWeight: FontWeight.bold, color: enabled ? Colors.black : Colors.grey)),
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
          // const SizedBox(height: 12), // Removed header button
          const SizedBox(height: 12),
          StreamBuilder<List<PaymentMethod>>(
            stream: _userRepo.getPaymentMethods(_userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              final allMethods = List<PaymentMethod>.from(snapshot.data ?? []);
              
              // 1. Resolve Cards
              final cards = allMethods.where((m) => m.type != 'cod' && m.type != 'momo').toList();
              // Sort cards by default so we pick the best one initially
              cards.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
              
              // Init _displayCard if needed
              if (_displayCard == null && cards.isNotEmpty) {
                 // Try to find one that is default
                 _displayCard = cards.first; 
              }
              // If _displayCard is dirty (deleted), reset
              if (_displayCard != null && !cards.any((c) => c.id == _displayCard!.id)) {
                 _displayCard = cards.isNotEmpty ? cards.first : null;
              }

              // 2. Resolve COD
              var cod = allMethods.firstWhere(
                  (m) => m.type == 'cod', 
                  orElse: () => PaymentMethod(id: 'cod', type: 'cod', title: 'Thanh toán khi nhận hàng', subtitle: 'Phù hợp cho mọi đơn hàng', isDefault: false)
              );
              
              // 3. Resolve Momo
              var momo = allMethods.firstWhere(
                  (m) => m.type == 'momo', 
                  orElse: () => PaymentMethod(id: 'momo', type: 'momo', title: 'Ví MoMo', subtitle: 'SĐT: 0323232646', isDefault: false)
              );

              // Auto-select initial (once)
              if (_selectedPaymentMethod == null) {
                  // Check if any is default in DB
                  if (allMethods.any((m) => m.isDefault)) {
                     final def = allMethods.firstWhere((m) => m.isDefault);
                     // If default is a card, ensure _displayCard matches
                     if (def.type != 'cod' && def.type != 'momo') {
                        _displayCard = def;
                     }
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedPaymentMethod = def);
                     });
                  } else {
                     // Default to COD if no default set
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedPaymentMethod = cod);
                     });
                  }
              }

              // Display List: Card (if exists), COD, Momo
              return Column(
                children: [
                  // CARD SLOT
                  if (_displayCard != null)
                     RadioListTile<String>(
                       value: _displayCard!.id,
                       groupValue: _selectedPaymentMethod?.id,
                       activeColor: const Color(0xFFC69C6D),
                       secondary: _getPaymentIcon(_displayCard!.type),
                       title: Row(
                         children: [
                           Expanded(child: Text(_getMaskedTitle(_displayCard!.title), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                           GestureDetector(
                             onTap: () => _showCardPicker(cards),
                             child: const Text('Thay đổi', style: TextStyle(color: Colors.blue, fontSize: 12)),
                           )
                         ],
                       ),
                       subtitle: Text(_displayCard!.subtitle.toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                       onChanged: (val) {
                          setState(() => _selectedPaymentMethod = _displayCard);
                          _userRepo.setDefaultPaymentMethod(_userId, _displayCard!.id);
                       },
                     ),
                  
                  // COD SLOT
                  RadioListTile<String>(
                     value: cod.id,
                     groupValue: _selectedPaymentMethod?.id,
                     activeColor: const Color(0xFFC69C6D),
                     secondary: _getPaymentIcon(cod.type),
                     title: Text(cod.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                     subtitle: Text(cod.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                     onChanged: (val) {
                        setState(() => _selectedPaymentMethod = cod);
                        _userRepo.setDefaultPaymentMethod(_userId, cod.id);
                     },
                  ),

                  // MOMO SLOT
                  RadioListTile<String>(
                     value: momo.id,
                     groupValue: _selectedPaymentMethod?.id,
                     activeColor: const Color(0xFFC69C6D),
                     secondary: _getPaymentIcon(momo.type),
                     title: Text(momo.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                     subtitle: Text(momo.subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                     onChanged: (val) {
                        setState(() => _selectedPaymentMethod = momo);
                        _userRepo.setDefaultPaymentMethod(_userId, momo.id);
                     },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getMaskedTitle(String title) {
     if (title.contains('Visa ending')) {
        final parts = title.split(' ');
        if (parts.isNotEmpty) {
            final last = parts.last;
            if (RegExp(r'^\d+$').hasMatch(last)) {
               // Replace "Visa ending" with "***"
               return '*** $last';
            }
        }
        return title.replaceFirst('Visa ending', '***');
     }
     return title;
  }

  void _showCardPicker(List<PaymentMethod> cards) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
           return Container(
             padding: const EdgeInsets.all(16),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Text('Chọn thẻ thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 16),
                 ...cards.where((c) => ['visa', 'card'].contains(c.type.toLowerCase())).map((card) => ListTile(
                    leading: const Icon(Icons.credit_card, color: Colors.blue),
                    title: Text(_getMaskedTitle(card.title)),
                    subtitle: Text(card.subtitle),
                    trailing: _displayCard?.id == card.id ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                       setState(() {
                         _displayCard = card;
                         _selectedPaymentMethod = card;
                       });
                       _userRepo.setDefaultPaymentMethod(_userId, card.id);
                       Navigator.pop(context);
                    },
                 )),
               ],
             ),
           );
        }
      );
  }

  Widget _getPaymentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
      case 'card':
        return const Icon(Icons.credit_card, color: Colors.blue);
      case 'momo':
        return const Icon(Icons.account_balance_wallet, color: Colors.pink);
      case 'cod':
        return const Icon(Icons.local_shipping, color: Colors.orange);
      default:
        return const Icon(Icons.payment, color: Colors.grey);
    }
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
                  child: UniversalImage(
                    imageUrl: item.image,
                    width: 60, height: 60, fit: BoxFit.cover,
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

  Widget _buildCostDetails(double subtotal, double shipping, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _buildRow('Tạm tính', subtotal),
          _buildRow('Phí vận chuyển', shipping),
          if (total < subtotal + shipping) 
             _buildRow('Mã giảm giá', -(subtotal + shipping - total)),
          
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

  String _getRegion(String city) {
    // List of cities in North
    const northCities = [
      'Hà Nội', 'Hải Phòng', 'Lai Châu', 'Lạng Sơn', 'Lào Cai', 'Nam Định', 
      'Ninh Bình', 'Phú Thọ', 'Quảng Ninh', 'Sơn La', 'Thái Bình', 
      'Thái Nguyên', 'Tuyên Quang', 'Vĩnh Phúc', 'Yên Bái'
    ];
    
    // List of cities in Central
    const centralCities = [
      'Đà Nẵng', 'Lâm Đồng', 'Nghệ An', 'Ninh Thuận', 'Phú Yên', 
      'Quảng Bình', 'Quảng Nam', 'Quảng Ngãi', 'Quảng Trị', 
      'Thanh Hóa', 'Thừa Thiên Huế'
    ];

    if (northCities.contains(city)) return 'Miền Bắc';
    if (centralCities.contains(city)) return 'Miền Trung';
    return 'Miền Nam'; 
  }

  double _calculateShippingFeeVal(String city) {
     if (city.isEmpty) return 25000.0; // Fallback default
     final region = _getRegion(city);
     if (region == 'Miền Bắc') return 50000.0;
     if (region == 'Miền Trung') return 70000.0;
     return 100000.0; // Miền Nam
  }
}
