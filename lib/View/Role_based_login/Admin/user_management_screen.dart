import 'package:do_an_quan_ao/Model/user_model.dart';
import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/ViewModel/user_provider.dart';
import 'package:do_an_quan_ao/ViewModel/order_provider.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/user_detail_screen.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  const UserManagementScreen({super.key, this.showBackButton = true});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';
  String _selectedTab = 'Tất cả'; // 'Mới hôm nay', 'Tất cả'

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            )
          : null,
        title: const Text(
          'Quản lý user',
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
                // AuthStateHandler handles navigation
              }
            },
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          return ordersAsync.when(
            data: (orders) {
              return _buildBody(context, users, orders);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi tải đơn hàng: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Lỗi tải user: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<UserModel> users, List<Order> orders) {
    // Filter logic
    print('Total users: ${users.length}');
    final now = DateTime.now();
    final todayUsers = users.where((u) => 
      u.createdAt.year == now.year && 
      u.createdAt.month == now.month && 
      u.createdAt.day == now.day
    ).toList();

    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayUsersCount = users.where((u) => 
      u.createdAt.year == yesterday.year && 
      u.createdAt.month == yesterday.month && 
      u.createdAt.day == yesterday.day
    ).length;

    final newUsersGrowth = todayUsers.length - yesterdayUsersCount;
    final growthText = newUsersGrowth >= 0 ? '+$newUsersGrowth' : '$newUsersGrowth';

    // Search filter
    List<UserModel> filteredUsers = _selectedTab == 'Mới hôm nay' ? todayUsers : users;
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredUsers = filteredUsers.where((u) {
        return u.name.toLowerCase().contains(query) ||
               u.email.toLowerCase().contains(query) ||
               u.phoneNumber.contains(query);
      }).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User mới hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${todayUsers.length} user mới • $growthText so với hôm qua',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'User mới hôm nay', 
                  '${todayUsers.length}', 
                  '$growthText so với hôm qua'
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Tổng user', 
                  '${users.length}', 
                  '+${users.where((u) => u.createdAt.isAfter(now.subtract(const Duration(days: 30)))).length} trong 30 ngày'
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, số điện thoại, email',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              _buildTabButton('Mới hôm nay', Colors.blue),
              const SizedBox(width: 12),
              _buildTabButton('Tất cả', Colors.grey.shade200, textColor: Colors.black),
            ],
          ),
          const SizedBox(height: 16),

          // User List
          if (filteredUsers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Không tìm thấy user nào', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...filteredUsers.map((user) => _buildUserItem(context, user, orders)),
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, Color bgColor, {Color textColor = Colors.white}) {
    final isSelected = _selectedTab == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, UserModel user, List<Order> allOrders) {
    // Calculate user stats from orders
    // Matching by phone number if available, otherwise name (fallback)
    // Ideally we should have userId in Order, but for now we use what we have.
    final userOrders = allOrders.where((o) {
      if (user.phoneNumber.isNotEmpty && o.customerPhone == user.phoneNumber) {
        return true;
      }
      // Fallback to name match if phone is empty (less reliable)
      if (user.phoneNumber.isEmpty && o.customerName.toLowerCase() == user.name.toLowerCase()) {
        return true;
      }
      return false;
    }).toList();

    final totalSpent = userOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);
    final lastOrder = userOrders.isNotEmpty 
        ? userOrders.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b) 
        : null;
    
    final lastOrderTime = lastOrder != null 
        ? DateFormat('HH:mm hôm nay').format(lastOrder.createdAt) // Simplified for demo
        : 'Chưa có đơn';

    final isNewUser = user.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                        ? Text(
                            _getInitials(user.name),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              if (isNewUser)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'User mới',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${userOrders.length} đơn • Lần cuối $lastOrderTime',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                _formatCurrency(totalSpent),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: user.isActive ? Colors.grey.shade100 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.isActive ? 'Đang hoạt động' : 'Đã khóa',
                  style: TextStyle(
                    color: user.isActive ? Colors.black : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context, // context is available in _buildUserItem if passed or if widget is method of class
                    MaterialPageRoute(
                      builder: (context) => UserDetailScreen(user: user),
                    ),
                  );
                },
                child: Row(
                  children: const [
                    Text('Xem chi tiết', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right, color: Colors.blue, size: 16),
                  ],
                ),
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
    if (amount >= 1000000) {
      return '₫${(amount / 1000000).toStringAsFixed(1)}M';
    } else {
      return '₫${(amount / 1000).toStringAsFixed(0)}K';
    }
  }
}
