import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/Profile/user_order_detail_screen.dart';
import 'package:do_an_quan_ao/View/Widgets/success_dialog.dart';

class UserOrderHistoryScreen extends StatefulWidget {
  const UserOrderHistoryScreen({super.key});

  @override
  State<UserOrderHistoryScreen> createState() => _UserOrderHistoryScreenState();
}

class _UserOrderHistoryScreenState extends State<UserOrderHistoryScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  String? _selectedStatus;
  List<String> get _statuses => ['Tất cả', 'Chờ xác nhận', 'Đang giao', 'Đã giao', 'Đã hủy'];

  String _formatCurrency(double amount) {
    final format = NumberFormat("#,##0", "vi_VN");
    return "${format.format(amount)}đ";
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'chờ xác nhận': return Colors.orange;
      case 'đang giao': return Colors.blue;
      case 'đã giao': return Colors.green;
      case 'giao hàng thành công': return Colors.green;
      case 'đã hủy': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _orderRepository.updateOrderStatus(order.id, 'Đã hủy');
        if (mounted) {
           await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (context) => const SuccessDialog(title: 'Đã hủy đơn hàng thành công'),
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navStatus = _selectedStatus ?? 'Tất cả';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final isSelected = navStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                         _selectedStatus = status;
                      });
                    }
                  },
                  selectedColor: const Color(0xFFD29062), // App primary color or similar
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.grey.shade300,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Order List
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _orderRepository.getOrdersByUserId(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Bạn chưa có đơn hàng nào'));
                }
            
                final orders = snapshot.data!.where((order) {
                   if (navStatus == 'Tất cả') return true;
                   
                   final orderStatus = order.status.toLowerCase().trim();
                   final filterStatus = navStatus.toLowerCase().trim();

                   if (filterStatus == 'đã giao') {
                     return orderStatus == 'đã giao' || orderStatus == 'giao hàng thành công';
                   }
                   
                   return orderStatus == filterStatus;
                }).toList();
                
                if (orders.isEmpty) {
                   return const Center(child: Text('Không có đơn hàng nào theo trạng thái này'));
                }
            
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => UserOrderDetailScreen(order: order)));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Đơn hàng: #${order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    order.status,
                                    style: TextStyle(
                                      color: _getStatusColor(order.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Ngày đặt: ${_formatDate(order.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const Divider(height: 24),
                            ...order.products.map((product) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 50,
                                      height: 50,
                                      child: UniversalImage(
                                        imageUrl: product.imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${product.productName} x${product.quantity}', style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                        Text(
                                          'Size: ${product.size ?? "N/A"} - Màu: ${product.color ?? "N/A"}', 
                                          style: const TextStyle(color: Colors.grey, fontSize: 12)
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     const Text('Tổng tiền', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                     Text(_formatCurrency(order.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFA07048))),
                                  ],
                                ),
                                if (order.status.toLowerCase() == 'chờ xác nhận')
                                   OutlinedButton(
                                     onPressed: () => _cancelOrder(order),
                                     style: OutlinedButton.styleFrom(
                                       foregroundColor: Colors.red,
                                       side: const BorderSide(color: Colors.red),
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                       minimumSize: Size.zero,
                                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                     ),
                                     child: const Text('Hủy đơn', style: TextStyle(fontSize: 12)),
                                   ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    
    );
  }
}
