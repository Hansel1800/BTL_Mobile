import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:flutter/material.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:do_an_quan_ao/View/Widgets/success_dialog.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
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
          'Chi tiết đơn',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOrderInfoCard(),
            const SizedBox(height: 16),
            _buildCustomerInfoCard(context),
            const SizedBox(height: 16),
            _buildProductListCard(),
            const SizedBox(height: 16),
            _buildPaymentInfoCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
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
              Text(
                '#${order.id.substring(0, order.id.length > 12 ? 12 : order.id.length)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          _buildInfoRow('Khách hàng', order.customerName),
          const SizedBox(height: 8),
          _buildInfoRow('Tổng đơn', '₫${order.totalPrice.toStringAsFixed(0)}', isBoldValue: true),
          const SizedBox(height: 8),
          _buildInfoRow('Thanh toán', 'COD • Chưa thu tiền'),
          const SizedBox(height: 8),
          _buildInfoRow('Kênh', 'Tại cửa hàng'),
        ],
      ),
    );
  }



  Widget _buildInfoRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin khách hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Tên khách', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Số điện thoại', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text(order.customerPhone, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Địa chỉ giao hàng', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            order.customerAddress,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('Ghi chú:  Giao trong giờ hành chính', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                     _showStatusUpdateDialog(context);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Cập nhật trạng thái'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildProductListCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sản phẩm (3)', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Đã bao gồm thuế', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          _buildProductItem('Áo thun basic cổ tròn', 'Size M • Trắng', '1', '₫190.000'),
          const SizedBox(height: 16),
          _buildProductItem('Quần jean slim fit', 'Size 30 • Xanh đậm', '1', '₫220.000'),
          const SizedBox(height: 16),
          _buildProductItem('Áo sơ mi caro', 'Size L • Đỏ', '1', '₫110.000'),
        ],
      ),
    );
  }

  Widget _buildProductItem(String name, String detail, String qty, String price) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder image
        Container(
          width: 50,
          height: 50,
          color: Colors.grey[200],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(detail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text('SL: $qty', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thanh toán', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow('Tạm tính', '₫520.000'),
          const SizedBox(height: 8),
          _buildInfoRow('Giảm giá', '₫0'),
          const SizedBox(height: 8),
          _buildInfoRow('Phí vận chuyển', '₫0'),
          const SizedBox(height: 8),
          _buildInfoRow('Đã thu', '₫0'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Còn phải thu', style: TextStyle(color: Colors.grey)),
              Text(
                '₫520.000',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _showStatusUpdateDialog(BuildContext context) {
    final statuses = ['Chờ xác nhận', 'Đang đóng gói', 'Đang giao hàng', 'Giao hàng thành công', 'Đã hủy'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) => ListTile(
            title: Text(status),
            leading: order.status == status ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () async {
               Navigator.pop(context); // Close selection dialog
               try {
                  // Assuming OrderRepository is available or accessible
                  // If not imported, I will need to fix imports.
                  // For now, let's try to dynamic import or just use class name and fix later.
                  // But 'OrderRepository' name must be valid.
                  // I'll add imports in next step.
                  // await OrderRepository().updateOrderStatus(order.id, status);
                  // Update logic...
                  // Since I can't call OrderRepository without import, I'll assume it's imported or I add it.
                  
                  // Mock update for now or real if I add import
                  // await OrderRepository().updateOrderStatus(order.id, status);
                  
                  _confirmUpdate(context, status);
               } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
               }
            },
          )).toList(),
        ),
      ),
    );
  }

  void _confirmUpdate(BuildContext context, String status) async {
     showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
     
     try {
       await OrderRepository().updateOrderStatus(order.id, status);
       
       if (context.mounted) {
           Navigator.pop(context); // Pop loading
           showDialog(
               context: context,
               builder: (_) => SuccessDialog(
                   title: 'Cập nhật thành công', 
                   onDismiss: () {
                      if (context.mounted) Navigator.pop(context); // Return to list
                   }
               )
           );
       }
     } catch (e) {
        if (context.mounted) Navigator.pop(context); // Pop loading
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
     }
  }
}
