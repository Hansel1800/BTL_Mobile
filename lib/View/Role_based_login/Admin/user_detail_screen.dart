import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/Model/user_model.dart';
import 'package:do_an_quan_ao/ViewModel/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UserDetailScreen extends ConsumerWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết user',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(
              _getInitials(user.name),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          // Filter orders for this user
          final userOrders = orders.where((o) {
            if (user.phoneNumber.isNotEmpty && o.customerPhone == user.phoneNumber) {
              return true;
            }
            if (user.phoneNumber.isEmpty && o.customerName.toLowerCase() == user.name.toLowerCase()) {
              return true;
            }
            return false;
          }).toList();

          // Sort by date desc
          userOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final totalSpent = userOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);
          final avgOrderValue = userOrders.isNotEmpty ? totalSpent / userOrders.length : 0.0;
          final lastOrderTime = userOrders.isNotEmpty 
              ? _formatTime(userOrders.first.createdAt) 
              : 'Chưa có đơn';

          // Try to get address from latest order
          final address = userOrders.isNotEmpty ? userOrders.first.customerAddress : 'Chưa cập nhật';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileCard(user),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Tổng đơn',
                        '${userOrders.length}',
                        'Lần cuối $lastOrderTime',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Tổng chi tiêu',
                        _formatCurrency(totalSpent),
                        'Trung bình ${_formatCurrency(avgOrderValue)}/đơn',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionButton(),
                const SizedBox(height: 16),
                _buildContactInfo(user, address),
                const SizedBox(height: 16),
                _buildRecentOrders(userOrders),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    final isNewUser = user.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              _getInitials(user.name),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isNewUser)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'User mới',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.isActive ? Colors.blue.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.isActive ? 'Đang hoạt động' : 'Đã khóa',
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: user.isActive ? Colors.blue : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Implement contact logic
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: const Text('Liên hệ khách', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildContactInfo(UserModel user, String address) {
    return Container(
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
              const Text('Thông tin liên hệ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Chỉnh sửa', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Số điện thoại', user.phoneNumber.isEmpty ? 'Chưa cập nhật' : user.phoneNumber),
          const SizedBox(height: 12),
          _buildInfoRow('Địa chỉ', address),
          const SizedBox(height: 12),
          _buildInfoRow('Ngày tạo', DateFormat('dd/MM/yyyy').format(user.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildRecentOrders(List<Order> orders) {
    return Container(
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
              const Text('Đơn hàng gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Xem tất cả', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.grey)))
          else
            ...orders.take(3).map((order) => _buildOrderItem(order)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Order order) {
    // Determine status style
    String statusText = order.status;
    Color statusColor = Colors.grey;
    
    switch (order.status.toLowerCase()) {
      case 'delivered':
        statusText = 'Đã giao';
        statusColor = Colors.green;
        break;
      case 'processing':
        statusText = 'Đang xử lý';
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusText = 'Đã hủy';
        statusColor = Colors.red;
        break;
      case 'shipped':
        statusText = 'Đang giao';
        statusColor = Colors.blue;
        break;
    }

    // Summary text (e.g., "Áo thun basic x2 - Hôm nay, 10:12")
    final summary = '${order.products.first.productName} x${order.products.first.quantity}${order.products.length > 1 ? '...' : ''} - ${_formatTime(order.createdAt)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 10, color: statusColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(order.totalPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'NA';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year && time.month == now.month && time.day == now.day) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(time)}';
    } else if (time.year == now.year && time.month == now.month && time.day == now.day - 1) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(time)}';
    }
    return DateFormat('dd/MM, HH:mm').format(time);
  }
}
