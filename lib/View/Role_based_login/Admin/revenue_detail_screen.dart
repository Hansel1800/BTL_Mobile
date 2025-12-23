import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/ViewModel/order_provider.dart';
import 'package:do_an_quan_ao/View/Role_based_login/User/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class RevenueDetailScreen extends ConsumerStatefulWidget {
  const RevenueDetailScreen({super.key});

  @override
  ConsumerState<RevenueDetailScreen> createState() => _RevenueDetailScreenState();
}

class _RevenueDetailScreenState extends ConsumerState<RevenueDetailScreen> {
  String _selectedTab = 'Ngày';

  @override
  Widget build(BuildContext context) {
    final ordersAsyncValue = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Doanh thu',
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
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ordersAsyncValue.when(
        data: (orders) {
          final data = _calculateData(orders, _selectedTab);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(data),
                const SizedBox(height: 16),
                _buildChartSection(data),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildInfoCard('Đơn hoàn tất', data['orders'], data['ordersGrowth'])),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoCard('Giá trị trung bình', data['avgValue'], data['avgGrowth'])),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTopCategoriesSection(data['categories']),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Lỗi: $error')),
      ),
    );
  }

  Map<String, dynamic> _calculateData(List<Order> orders, String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime previousStartDate;
    DateTime previousEndDate;
    String comparisonText;
    String chartTitle;
    List<double> chartValues = [];
    List<String> chartLabels = [];

    // 1. Determine Date Ranges
    if (period == 'Ngày') {
      startDate = DateTime(now.year, now.month, now.day);
      previousStartDate = startDate.subtract(const Duration(days: 1));
      previousEndDate = startDate;
      comparisonText = 'So với hôm qua';
      chartTitle = 'Khung giờ hôm nay';
      chartLabels = ['9h', '11h', '13h', '15h', '17h', '19h', '21h'];
      
      // Init buckets
      chartValues = List.filled(7, 0.0); 

    } else if (period == 'Tuần') {
      // Find Monday of this week
      startDate = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(startDate.year, startDate.month, startDate.day);
      previousStartDate = startDate.subtract(const Duration(days: 7));
      previousEndDate = startDate;
      comparisonText = 'So với tuần trước';
      chartTitle = '7 ngày gần nhất';
      chartLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      
      chartValues = List.filled(7, 0.0);

    } else { // Tháng
      startDate = DateTime(now.year, now.month, 1);
      previousStartDate = DateTime(now.year, now.month - 1, 1);
      previousEndDate = startDate;
      comparisonText = 'So với tháng trước';
      chartTitle = '4 tuần gần nhất';
      chartLabels = ['Tuần 1', 'Tuần 2', 'Tuần 3', 'Tuần 4'];
      
      chartValues = List.filled(4, 0.0);
    }

    // 2. Filter Orders
    final currentOrders = orders.where((o) => o.createdAt.isAfter(startDate)).toList();
    final previousOrders = orders.where((o) => 
      o.createdAt.isAfter(previousStartDate) && o.createdAt.isBefore(previousEndDate)
    ).toList();

    // 3. Calculate Metrics
    final currentRevenue = currentOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);
    final previousRevenue = previousOrders.fold<double>(0, (sum, o) => sum + o.totalPrice);

    final revenueGrowth = previousRevenue > 0 
        ? ((currentRevenue - previousRevenue) / previousRevenue * 100)
        : 100.0; // Assume 100% growth if previous was 0 and current > 0

    final currentCount = currentOrders.length;
    final previousCount = previousOrders.length;
    final countGrowth = currentCount - previousCount;

    final currentAvg = currentCount > 0 ? currentRevenue / currentCount : 0.0;
    final previousAvg = previousCount > 0 ? previousRevenue / previousCount : 0.0;
    final avgGrowth = previousAvg > 0 
        ? ((currentAvg - previousAvg) / previousAvg * 100)
        : 0.0;

    // 4. Top Products (using product name as category proxy)
    final productMap = <String, double>{};
    final productCountMap = <String, int>{};

    for (var order in currentOrders) {
      // Create chart data
      if (period == 'Ngày') {
         final h = order.createdAt.hour;
         // Buckets: 9h (starts 0), 11h (1), 13h (2), 15h (3), 17h (4), 19h (5), 21h (6)
         // Map roughly: <10 -> 0, 10-12 -> 1, 12-14 -> 2...
         // Simple: (h - 8) / 2. NO.
         // Let's use if/else for safety
         int index = -1;
         if (h <= 10) index = 0;
         else if (h <= 12) index = 1;
         else if (h <= 14) index = 2;
         else if (h <= 16) index = 3;
         else if (h <= 18) index = 4;
         else if (h <= 20) index = 5;
         else index = 6;
         
         if (index >= 0 && index < 7) chartValues[index] += order.totalPrice;
         
      } else if (period == 'Tuần') {
         // weekday: 1 (Mon) -> 7 (Sun). Index = weekday - 1.
         int index = order.createdAt.weekday - 1;
         if (index >= 0 && index < 7) chartValues[index] += order.totalPrice;
         
      } else { // Tháng
         // Weeks: 1-7, 8-14, 15-21, 22+
         final d = order.createdAt.day;
         int index = 0;
         if (d <= 7) index = 0;
         else if (d <= 14) index = 1;
         else if (d <= 21) index = 2;
         else index = 3; // Rest
         
         if (index >= 0 && index < 4) chartValues[index] += order.totalPrice;
      }

      for (var item in order.products) {
        productMap[item.productName] = (productMap[item.productName] ?? 0) + (item.price * item.quantity);
        productCountMap[item.productName] = (productCountMap[item.productName] ?? 0) + 1; // Count orders containing this product
      }
    }

    final sortedProducts = productMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topProducts = sortedProducts.take(3).map((e) {
      final percent = currentRevenue > 0 ? (e.value / currentRevenue * 100).toStringAsFixed(0) : '0';
      return {
        'name': e.key,
        'count': '${productCountMap[e.key]} đơn',
        'value': _formatCurrencyCompact(e.value),
        'percent': '$percent%',
      };
    }).toList();

    return {
      'title': period == 'Ngày' ? 'Hôm nay' : (period == 'Tuần' ? 'Tuần này' : 'Tháng này'),
      'revenue': _formatCurrencyCompact(currentRevenue),
      'growth': '${revenueGrowth >= 0 ? '+' : ''}${revenueGrowth.toStringAsFixed(0)}%',
      'comparison': '$comparisonText (${_formatCurrencyCompact(previousRevenue)})',
      'chartTitle': chartTitle,
      'chartLabels': chartLabels,
      'orders': '$currentCount',
      'ordersGrowth': '${countGrowth >= 0 ? '+' : ''}$countGrowth $comparisonText',
      'avgValue': _formatCurrencyCompact(currentAvg),
      'avgGrowth': '${avgGrowth >= 0 ? '+' : ''}${avgGrowth.toStringAsFixed(0)}% AOV',
      'categories': topProducts,
      'chartValues': chartValues,
    };
  }

  String _formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '₫${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₫${(amount / 1000).toStringAsFixed(0)}K';
    } else {
      return '₫${amount.toStringAsFixed(0)}';
    }
  }

  Widget _buildHeaderSection(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['title'], style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data['revenue'],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                _buildTabButton('Ngày'),
                _buildTabButton('Tuần'),
                _buildTabButton('Tháng'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (data['growth'] as String).startsWith('-') ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                data['growth'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data['comparison'],
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabButton(String text) {
    bool isSelected = _selectedTab == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = text;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection(Map<String, dynamic> data) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Biểu đồ chi tiết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(data['chartTitle'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('Doanh thu', Colors.blue),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
            Container(
              height: 150,
              alignment: Alignment.bottomCenter,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: () {
                    // Generate data points
                    // We need to map data['chartLabels'] to actual values.
                    // This requires passing the dataset or calculating it here.
                    // Since _calculateData returns aggregate, we need to pass the breakdowns too.
                    // For now, let's create a simple simulation based on the aggregate to avoid big refactor,
                    // OR better: Update _calculateData to return 'chartValues'.
                    
                    List<double> values = data['chartValues'] ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
                    double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
                    if (maxVal == 0) maxVal = 1;

                    return values.asMap().entries.map((entry) {
                       final height = (entry.value / maxVal) * 120; // Max height 120
                       return Column(
                         mainAxisAlignment: MainAxisAlignment.end,
                         children: [
                           if (entry.value > 0)
                             Text(_formatCurrencyCompact(entry.value).replaceAll('₫', ''), style: const TextStyle(fontSize: 8, color: Colors.blue)),
                           const SizedBox(height: 4),
                           Container(
                             width: 20,
                             height: height > 0 ? height : 4, // Min height 4
                             decoration: BoxDecoration(
                               color: entry.value > 0 ? Colors.blue : Colors.blue.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(4),
                             ),
                           ),
                         ],
                       );
                    }).toList();
                }(),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (data['chartLabels'] as List<String>).map((label) => 
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10))
            ).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, String subtitle) {
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

  Widget _buildTopCategoriesSection(List<dynamic> categories) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sản phẩm bán chạy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Top 3 theo doanh thu (${_selectedTab.toLowerCase()})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey))),
            )
          else
            ...categories.asMap().entries.map((entry) {
              final item = entry.value;
              final index = entry.key;
              return Column(
                children: [
                  _buildCategoryItem(item['name'], item['count'], item['value'], item['percent']),
                  if (index < categories.length - 1) const Divider(),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String name, String count, String value, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(count, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(percentage, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
