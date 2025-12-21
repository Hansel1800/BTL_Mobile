import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/Model/user_model.dart';
import 'package:do_an_quan_ao/ViewModel/order_provider.dart';
import 'package:do_an_quan_ao/ViewModel/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/order_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/admin_chat_detail_screen.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';

class UserDetailScreen extends ConsumerWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(usersProvider);
    final ordersAsync = ref.watch(ordersProvider);

    return userAsync.when(
      data: (users) {
        // Find the specific user to get live updates
        final liveUser = users.firstWhere(
          (u) => u.id == user.id,
          orElse: () => user, // Fallback if not found (e.g. deleted or error)
        );

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
                  _getInitials(liveUser.name),
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
                if (liveUser.phoneNumber.isNotEmpty && o.customerPhone == liveUser.phoneNumber) {
                  return true;
                }
                if (liveUser.phoneNumber.isEmpty && o.customerName.toLowerCase() == liveUser.name.toLowerCase()) {
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
    
              // Try to get address from user profile first, then latest order
              final address = liveUser.address.isNotEmpty 
                  ? liveUser.address 
                  : (userOrders.isNotEmpty ? userOrders.first.customerAddress : 'Chưa cập nhật');
    
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileCard(liveUser),
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
                    _buildActionButton(context, ref, liveUser),
                    const SizedBox(height: 16),
                    _buildContactInfo(liveUser, address),
                    const SizedBox(height: 16),
                    if (liveUser.preferences.isNotEmpty) ...[
                      _buildPreferencesInfo(liveUser),
                      const SizedBox(height: 16),
                    ],
                    _buildRecentOrders(context, userOrders),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi: $e')),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Lỗi tải user: $e'))),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    final isNewUser = user.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    final displayName = user.fullName.isNotEmpty ? user.fullName : user.name;
    
    // Join year
    final joinYear = user.createdAt.year.toString();

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
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? Text(
                    _getInitials(displayName),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  'Thành viên từ $joinYear',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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

  // ... _buildStatCard and _buildActionButton remain same ...
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

  Widget _buildActionButton(BuildContext context, WidgetRef ref, UserModel user) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminChatDetailScreen(
                    userId: user.id,
                    userName: user.fullName.isNotEmpty ? user.fullName : user.name,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: const Text('Nhắn tin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              _confirmToggleUserStatus(context, ref, user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? Colors.red.shade50 : Colors.green.shade50,
              foregroundColor: user.isActive ? Colors.red : Colors.green,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: user.isActive ? Colors.red.shade200 : Colors.green.shade200),
              ),
            ),
            child: Text(
              user.isActive ? 'Khóa' : 'Mở khóa', 
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmToggleUserStatus(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?'),
        content: Text(user.isActive 
            ? 'Người dùng sẽ không thể đăng nhập hoặc mua hàng sau khi bị khóa.' 
            : 'Người dùng sẽ có thể đăng nhập và mua hàng bình thường.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog
              
              final userController = ref.read(userControllerProvider.notifier);
              await userController.toggleUserStatus(user.id, user.isActive);

              if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(user.isActive ? 'Đã khóa tài khoản thành công' : 'Đã mở khóa tài khoản'),
                      backgroundColor: user.isActive ? Colors.red : Colors.green,
                    ),
                  );
              }
            },
            child: Text(
              user.isActive ? 'Khóa ngay' : 'Mở khóa', 
              style: TextStyle(color: user.isActive ? Colors.red : Colors.green)
            ),
          ),
        ],
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
              const Text('Thông tin chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              //Text('Chỉnh sửa', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (user.fullName.isNotEmpty) ...[
            _buildInfoRow('Họ và tên', user.fullName),
            const SizedBox(height: 12),
          ],
          _buildInfoRow('Số điện thoại', user.phoneNumber.isEmpty ? 'Chưa cập nhật' : user.phoneNumber),
          const SizedBox(height: 12),
          if (user.dob.isNotEmpty) ...[
            _buildInfoRow('Ngày sinh', user.dob),
            const SizedBox(height: 12),
          ],
          if (user.gender != null) ...[
            _buildInfoRow('Giới tính', user.gender!),
            const SizedBox(height: 12),
          ],
          if (user.city != null) ...[
            _buildInfoRow('Thành phố', user.city!),
            const SizedBox(height: 12),
          ],
          _buildInfoRow('Địa chỉ', address),
          const SizedBox(height: 12),
          _buildInfoRow('Ngày tạo', DateFormat('dd/MM/yyyy').format(user.createdAt)),
        ],
      ),
    );
  }

  Widget _buildPreferencesInfo(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sở thích mua sắm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.preferences.map((pref) => Chip(
              label: Text(pref, style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey.shade100,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
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

  Widget _buildRecentOrders(BuildContext context, List<Order> orders) {
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
              //Text('Xem tất cả', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          if (orders.isEmpty)
            const Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: Colors.grey)))
          else
            ...orders.take(3).map((order) => _buildOrderItem(context, order)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order) {
    // Determine status style
    String statusText = order.status;
    Color statusColor = Colors.grey;
    Color statusBgColor = Colors.white; // Default bg
    
    // Normalize status for check
    String normalizedStatus = order.status.toLowerCase();
    
    if (normalizedStatus.contains('hủy') || normalizedStatus == 'cancelled') {
       statusText = 'Đã hủy';
       statusColor = Colors.red;
       statusBgColor = Colors.red.shade50;
    } else if (normalizedStatus == 'delivered' || normalizedStatus == 'giao hàng thành công') {
       statusText = 'Đã giao';
       statusColor = Colors.green;
    } else if (normalizedStatus == 'processing' || normalizedStatus.contains('chờ')) {
       statusText = 'Đang xử lý';
       statusColor = Colors.orange;
    } else if (normalizedStatus.contains('đang giao') || normalizedStatus == 'shipped') {
       statusText = 'Đang giao';
       statusColor = Colors.blue;
    }

    // Summary text
    final summary = '${order.products.first.productName} x${order.products.first.quantity}';
    final hasMore = order.products.length > 1;

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: UniversalImage(
                imageUrl: order.products.first.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
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
                    '$summary${hasMore ? '...' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    _formatTime(order.createdAt),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
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
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold),
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
