import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_an_quan_ao/ViewModel/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Checkout/checkout_screen.dart';
import 'package:do_an_quan_ao/ViewModel/navigation_provider.dart';

class UserCartScreen extends ConsumerStatefulWidget {
  const UserCartScreen({super.key});

  @override
  ConsumerState<UserCartScreen> createState() => _UserCartScreenState();
}

class _UserCartScreenState extends ConsumerState<UserCartScreen> {
  final TextEditingController _voucherController = TextEditingController();
  double _discountAmount = 0.0;
  String? _appliedVoucherCode;
  bool _isCheckingVoucher = false;

  @override
  void initState() {
    super.initState();
    _voucherController.addListener(() {
      if (_appliedVoucherCode != null && 
          _voucherController.text.trim().toUpperCase() != _appliedVoucherCode) {
        setState(() {
          _discountAmount = 0;
          _appliedVoucherCode = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập mã giảm giá')));
      return;
    }

    setState(() {
      _isCheckingVoucher = true;
    });

    try {
      // Query by 'code' field
      final querySnapshot = await FirebaseFirestore.instance
          .collection('vouchers')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      DocumentSnapshot<Map<String, dynamic>>? docSnapshot;
      if (querySnapshot.docs.isNotEmpty) {
        docSnapshot = querySnapshot.docs.first;
      } else {
        // Fallback to check doc ID
        final doc = await FirebaseFirestore.instance.collection('vouchers').doc(code).get();
        if (doc.exists) {
          docSnapshot = doc;
        }
      }

      if (docSnapshot == null || !docSnapshot.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mã giảm giá không tồn tại')));
        setState(() {
           _discountAmount = 0;
           _appliedVoucherCode = null;
        });
        return;
      }

      final data = docSnapshot.data()!;
      
      // Basic validation checks
      final isActive = data['isActive'] ?? false;
      final usageCount = data['usedCount'] ?? data['usageCount'] ?? 0;
      final usageLimit = data['usageLimit'] ?? 0;
      final startDate = (data['startDate'] as Timestamp).toDate();
      final endDate = (data['endDate'] as Timestamp).toDate();
      final now = DateTime.now();

      if (!isActive) {
        throw 'Mã giảm giá đã bị khóa';
      }
      if (now.isBefore(startDate) || now.isAfter(endDate)) {
        throw 'Mã giảm giá đã hết hạn hoặc chưa có hiệu lực';
      }
      if (usageLimit > 0 && usageCount >= usageLimit) {
        throw 'Mã giảm giá đã hết lượt sử dụng';
      }

      // Calculate discount
      final notifier = ref.read(cartProvider.notifier);
      final subtotal = notifier.subtotal;
      final minOrderValue = (data['minOrderValue'] ?? 0).toDouble();

      if (subtotal < minOrderValue) {
        throw 'Đơn hàng chưa đạt giá trị tối thiểu ${NumberFormat('#,###').format(minOrderValue)}đ';
      }

      final discountType = data['type'] ?? data['discountType'] ?? 'fixed';
      final discountValue = (data['value'] ?? data['discountValue'] ?? 0).toDouble();
      final maxDiscount = (data['maxDiscount'] ?? 0).toDouble();
      
      double discount = 0;
      if (discountType == 'percent') {
        discount = subtotal * (discountValue / 100);
        if (maxDiscount > 0 && discount > maxDiscount) {
           discount = maxDiscount;
        }
      } else {
        discount = discountValue;
      }

      // Validate discount doesn't exceed subtotal
      if (discount > subtotal) discount = subtotal;

      setState(() {
        _discountAmount = discount;
        _appliedVoucherCode = code;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Áp dụng mã $code thành công!')));

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      setState(() {
        _discountAmount = 0;
        _appliedVoucherCode = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVoucher = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    
    // Calculations
    double subtotal = notifier.subtotal;
    // Shipping is determined at checkout based on location
    double shipping = 0; 

    // Recalculate discount if subtotal changes (to ensure not > subtotal or min order value)
    // For simplicity, we keep _discountAmount but cap it at subtotal
    if (_discountAmount > subtotal) {
       _discountAmount = subtotal;
    }
    // If subtotal is 0, reset everything
    if (subtotal == 0) {
      _discountAmount = 0;
    }

    double total = subtotal + shipping - _discountAmount;
    if (total < 0) total = 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   Container(
                     decoration: const BoxDecoration(
                       shape: BoxShape.circle,
                      color: Color(0xFFEBE4DB),
                     ),
                     child: IconButton(
                       icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                       onPressed: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            ref.read(navigationProvider.notifier).setIndex(0);
                          }
                       },
                     ),
                   ),
                   const SizedBox(width: 16),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        const Text(
                         'Giỏ hàng',
                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                       ),
                       Text(
                         '${cartItems.length} sản phẩm · Dự kiến giao 2-3 ngày',
                         style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                       ),
                     ],
                   )
                ],
              ),
            ),

            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepCircle('1', true), 
                _buildStepLine(),
                _buildStepCircle('2', false),
                _buildStepLine(),
                _buildStepCircle('3', false),
              ],
            ),
            const SizedBox(height: 16),
            
            // List
            Expanded(
              child: cartItems.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Giỏ hàng trống', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Container( // Cart Item Card
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           // Image
                           ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: SizedBox(
                               width: 80, height: 80,
                                 child: UniversalImage(
                                   imageUrl: item.image,
                                   fit: BoxFit.cover,
                                 ),
                             ),
                           ),
                           const SizedBox(width: 12),
                           // Details
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Expanded(child: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1)),
                                     GestureDetector(
                                       onTap: () => notifier.removeFromCart(item),
                                       child: Container(
                                         padding: const EdgeInsets.all(4),
                                         decoration: const BoxDecoration(color: Color(0xFFF5F2EF), shape: BoxShape.circle),
                                         child: const Icon(Icons.close, size: 14),
                                       ),
                                     )
                                   ],
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                    'Màu: ${item.selectedColor ?? "N/A"} · Size: ${item.selectedSize ?? "N/A"}',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                 ),
                                 const SizedBox(height: 12),
                                 Row(
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Text(
                                       '${NumberFormat('#,###').format(item.price * item.quantity)}đ', 
                                       style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD29062)),
                                     ),
                                     
                                     // Qty Control
                                     Container(
                                       decoration: BoxDecoration(
                                         color: const Color(0xFFF5F2EF),
                                         borderRadius: BorderRadius.circular(20),
                                       ),
                                       child: Row(
                                         children: [
                                           InkWell(
                                             onTap: () => notifier.updateQuantity(item, -1),
                                             child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.remove, size: 16)),
                                           ),
                                           Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                           InkWell(
                                             onTap: () {
                                                if (item.quantity >= item.stock) {
                                                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chỉ còn ${item.stock} sản phẩm trong kho')));
                                                } else {
                                                   notifier.updateQuantity(item, 1);
                                                }
                                             },
                                             child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Icon(Icons.add, size: 16)),
                                           ),
                                         ],
                                       ),
                                     )
                                   ],
                                 )
                               ],
                             ),
                           )
                        ],
                      ),
                    );
                  },
                ),
            ),
            
            // Footer Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSummaryRow('Tạm tính', subtotal),
                    if (_discountAmount > 0)
                      _buildSummaryRow('Ưu đãi', -_discountAmount, isDiscount: true),
                    // Removed Shipping Fee Row per user request
                    const Divider(height: 24),
                    _buildSummaryRow('Tổng cộng', total, isTotal: true),
                    const SizedBox(height: 16),
                    
                    // Coupon Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            decoration: InputDecoration(
                              hintText: _appliedVoucherCode != null ? 'Đã dùng: $_appliedVoucherCode' : 'Nhập mã giảm giá',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              suffixIcon: const Icon(Icons.confirmation_number_outlined, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isCheckingVoucher ? null : _applyVoucher,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEBE4DB),
                            foregroundColor: Colors.black,
                            elevation: 0,
                          ),
                          child: _isCheckingVoucher 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Áp dụng'),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                             if (cartItems.isEmpty) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giỏ hàng trống!')));
                               return;
                             }
                             
                             Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(voucherCode: _appliedVoucherCode)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC69C6D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Thanh toán', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                           Navigator.pushAndRemoveUntil(
                             context,
                             MaterialPageRoute(builder: (context) => const UserMainScreen()),
                             (route) => false,
                           );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:  const Color(0xFFF0EAE4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tiếp tục mua sắm', style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            '${isDiscount ? '' : ''}${NumberFormat('#,###').format(value)}đ',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFFD29062) : (isDiscount ? Colors.red : Colors.black),
            ),
          ),
        ],
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
