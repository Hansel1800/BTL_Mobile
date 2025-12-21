import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:flutter/material.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:do_an_quan_ao/View/Widgets/success_dialog.dart';
import 'package:do_an_quan_ao/Services/notification_service.dart';
import 'package:do_an_quan_ao/Services/chat_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/admin_chat_detail_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isChatLoading = false;

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
                '#${widget.order.id.substring(0, widget.order.id.length > 12 ? 12 : widget.order.id.length)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.order.createdAt.hour.toString().padLeft(2, '0')}:${widget.order.createdAt.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          _buildInfoRow('Khách hàng', widget.order.customerName),
          const SizedBox(height: 8),
          _buildInfoRow('Tổng đơn', '₫${widget.order.totalPrice.toStringAsFixed(0)}', isBoldValue: true),
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
          Text(widget.order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Số điện thoại', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text(widget.order.customerPhone, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Địa chỉ giao hàng', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            widget.order.customerAddress,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('Ghi chú:  Giao trong giờ hành chính', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          if (widget.order.status == 'Đã hủy' || widget.order.status == 'Cancelled')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.red[50], // Light red background
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: const Text(
                'Đơn hàng đã hủy',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                       // 1. Send Message in Background
                       final chatService = ChatService();
                       final orderIdShort = widget.order.id.length > 8 ? widget.order.id.substring(0, 8).toUpperCase() : widget.order.id;
                       
                       chatService.sendAdminMessage(
                         widget.order.userId, 
                         'Thông tin về đơn hàng #$orderIdShort',
                         orderId: widget.order.id,
                         orderStatus: widget.order.status,
                         orderTotal: widget.order.totalPrice.toStringAsFixed(0),
                         productImage: widget.order.products.isNotEmpty ? widget.order.products.first.imageUrl : null,
                       ).ignore(); // Ignore result, just send

                       // 2. Navigate Immediately
                       Navigator.push(
                           context, 
                           MaterialPageRoute(
                             builder: (_) => AdminChatDetailScreen(
                               userId: widget.order.userId, 
                               userName: widget.order.customerName
                             )
                           )
                       );
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusUpdateDialog(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Cập nhật'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
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
          Text('Sản phẩm (${widget.order.products.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text('Đã bao gồm thuế', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          ...widget.order.products.map((item) {
             final detail = [
               if (item.size != null && item.size!.isNotEmpty) 'Size ${item.size}',
               if (item.color != null && item.color!.isNotEmpty) item.color
             ].join(' • ');
             
             return Padding(
               padding: const EdgeInsets.only(bottom: 16.0),
               child: _buildProductItem(
                 item.productName, 
                 detail.isEmpty ? 'Tiêu chuẩn' : detail, 
                 item.quantity.toString(), 
                 '₫${item.price.toStringAsFixed(0)}',
                 item.imageUrl
               ),
             );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(String name, String detail, String qty, String price, [String? imageUrl]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 50,
            height: 50,
            child: UniversalImage(
              imageUrl: imageUrl ?? '',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
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
    final formattedTotal = '₫${widget.order.totalPrice.toStringAsFixed(0)}';
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
          _buildInfoRow('Tạm tính', formattedTotal),
          const SizedBox(height: 8),
          _buildInfoRow('Giảm giá', '₫0'),
          const SizedBox(height: 8),
          _buildInfoRow('Phí vận chuyển', '₫0'),
          const SizedBox(height: 8),
          _buildInfoRow('Đã thu', widget.order.paymentMethod == 'COD' ? '₫0' : formattedTotal),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Còn phải thu', style: TextStyle(color: Colors.grey)),
              Text(
                widget.order.paymentMethod == 'COD' ? formattedTotal : '₫0',
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cập nhật trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) => ListTile(
            title: Text(status),
            leading: widget.order.status == status ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
               // Close selection dialog
               Navigator.pop(dialogContext); 
               
               // Trigger update
               _confirmUpdate(status);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _confirmUpdate(String status) async {
     // 1. Show 'Updating' feedback
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(
         content: Text('Đang cập nhật...'),
         duration: Duration(days: 1), 
         backgroundColor: Colors.black87,
       ),
     );
     
     try {
       // 2. Async Update
       await OrderRepository().updateOrderStatus(widget.order.id, status);

       // 2.5 Send Notification if Delivered
       if (status == 'Giao hàng thành công') {
          try {
             final notifService = NotificationService();
             final token = await notifService.getUserToken(widget.order.userId);
             
             if (token != null) {
               await notifService.sendPushNotification(
                 recipientToken: token,
                 title: 'Giao hàng thành công!',
                 body: 'Đơn hàng #${widget.order.id} đã được giao đến bạn. Cảm ơn bạn đã mua sắm!',
               );
             }
          } catch (e) {
             print("Notification Failed: $e");
          }
       }
       
       // 3. Check mounted property of STATE
       if (!mounted) return;

       // 4. Clear old SnackBar
       ScaffoldMessenger.of(context).hideCurrentSnackBar();
       
       // 5. Show Success
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Cập nhật thành công!'),
           backgroundColor: Colors.green,
           duration: Duration(seconds: 2),
         ),
       );
       
       // 6. Navigate if cancelled
       if (status == 'Đã hủy') {
          if (mounted) Navigator.pop(context); 
       }
     } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
        }
     }
  }
}
