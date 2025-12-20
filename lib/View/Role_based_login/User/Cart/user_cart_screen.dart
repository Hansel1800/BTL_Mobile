import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_an_quan_ao/ViewModel/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/user_main_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Checkout/checkout_screen.dart';

class UserCartScreen extends ConsumerWidget {
  const UserCartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    
    // Calculations

    double subtotal = notifier.subtotal;
    double shipping = 30000;
    // double discount = 80000; // Removed per user request
    double total = subtotal + shipping;
    if (subtotal == 0) {
      shipping = 0;
      total = 0;
    }

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
                            context.findAncestorStateOfType<UserMainScreenState>()?.navigateToTab(0);
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
                               child: CachedNetworkImage(
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
                                       // Actually screenshot shows "199.000đ" which looks like unit price.
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
                                             onTap: () => notifier.updateQuantity(item, 1),
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
                    // _buildSummaryRow('Ưu đãi', -discount, isDiscount: true), // Removed
                    _buildSummaryRow('Phí vận chuyển (ước tính)', shipping),
                    const Divider(height: 24),
                    _buildSummaryRow('Tổng cộng', total, isTotal: true),
                    const SizedBox(height: 16),
                    
                    // Coupon Input
                    Row(
                      children: [
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Nhập mã giảm giá',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                              suffixIcon: Icon(Icons.confirmation_number_outlined, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEBE4DB),
                            foregroundColor: Colors.black,
                            elevation: 0,
                          ),
                          child: const Text('Áp dụng'),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const CheckoutScreen()));
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
