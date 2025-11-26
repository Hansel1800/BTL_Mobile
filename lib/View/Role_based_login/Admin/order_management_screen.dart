import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/order_detail_screen.dart';
import 'package:do_an_quan_ao/ViewModel/order_provider.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
             if (Navigator.canPop(context)) {
               Navigator.pop(context);
             }
          },
        ),
        title: const Text(
          'Đơn hàng',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                // Perform logout
                await FirebaseAuth.instance.signOut();
                
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: ordersAsyncValue.when(
              data: (orders) {
                final todayOrders = orders.where((order) {
                  final now = DateTime.now();
                  return order.createdAt.year == now.year &&
                      order.createdAt.month == now.month &&
                      order.createdAt.day == now.day;
                }).length;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tất cả đơn hàng',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${orders.length} đơn • $todayOrders đơn mới hôm nay',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tất cả đơn hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Đang tải...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              error: (error, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tất cả đơn hàng',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Lỗi tải dữ liệu',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Danh sách đơn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ordersAsyncValue.when(
              data: (orders) => _buildOrderList(context, orders),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Lỗi: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có đơn hàng nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(context, order);
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    // Format time
    final now = DateTime.now();
    final isToday = order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day;
    final isYesterday = order.createdAt.year == now.year &&
        order.createdAt.month == now.month &&
        order.createdAt.day == now.day - 1;

    String timeText;
    if (isToday) {
      timeText = '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')} • Hôm nay';
    } else if (isYesterday) {
      timeText = 'Hôm qua • ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      timeText = '${order.createdAt.day}/${order.createdAt.month} • ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}';
    }

    // Status mapping  
    String statusText;
    Color statusColor;
    switch (order.status.toLowerCase()) {
      case 'pending':
        statusText = 'Processing';
        statusColor = Colors.orange;
        break;
      case 'processing':
        statusText = 'Processing';
        statusColor = Colors.orange;
        break;
      case 'shipped':
        statusText = 'Shipping';
        statusColor = Colors.blue;
        break;
      case 'delivered':
        statusText = 'Delivered';
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusText = 'Cancelled';
        statusColor = Colors.red;
        break;
      default:
        statusText = order.status;
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.id.substring(0, order.id.length > 12 ? 12 : order.id.length)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  timeText,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.customerName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '${order.products.length} sản phẩm',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₫${order.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
