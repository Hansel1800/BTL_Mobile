import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:do_an_quan_ao/Model/order_model.dart';
import 'package:do_an_quan_ao/Services/order_repository.dart';
import 'package:do_an_quan_ao/View/Widgets/success_dialog.dart';

class UserOrderDetailScreen extends StatefulWidget {
  final Order order;
  const UserOrderDetailScreen({super.key, required this.order});

  @override
  State<UserOrderDetailScreen> createState() => _UserOrderDetailScreenState();
}

class _UserOrderDetailScreenState extends State<UserOrderDetailScreen> {
  late Order _order;
  final OrderRepository _orderRepo = OrderRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

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
      case 'đã hủy': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getMaskedPaymentMethod(String method) {
    if (method.toLowerCase().contains('visa ending')) {
       return method.replaceAll(RegExp(r'Visa ending', caseSensitive: false), '***');
    }
    return method;
  }

  Future<void> _cancelOrder() async {
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
      setState(() => _isLoading = true);
      try {
        await _orderRepo.updateOrderStatus(_order.id, 'Đã hủy');
        if (mounted) {
          await showDialog(
             context: context,
             barrierDismissible: false,
             builder: (context) => const SuccessDialog(title: 'Đã hủy đơn hàng thành công'),
           );
          Navigator.pop(context, true); // Return true to refresh list
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                   const Icon(Icons.info_outline, color: Colors.black54),
                   const SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Mã đơn hàng: #${_order.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                       Text('Trạng thái: ${_order.status}', style: TextStyle(color: _getStatusColor(_order.status), fontWeight: FontWeight.bold)),
                     ],
                   )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Address Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Địa chỉ nhận hàng', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${_order.customerName} · ${_order.customerPhone}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_order.customerAddress, style: const TextStyle(color: Colors.black87)),
                  if (_order.note != null && _order.note!.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: Text('Ghi chú: ${_order.note}', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                     ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Products
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ..._order.products.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: UniversalImage(
                            imageUrl: item.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('Phân loại: ${item.color ?? "N/A"}, ${item.size ?? "N/A"}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('x${item.quantity}', style: const TextStyle(fontSize: 12)),
                                  Text(_formatCurrency(item.price), style: const TextStyle(color: Color(0xFFD29062))),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thành tiền'),
                      Text(_formatCurrency(_order.totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFA07048))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Phương thức thanh toán', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(_getMaskedPaymentMethod(_order.paymentMethod), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),

             // Cancel Button
             if (_order.status.toLowerCase() == 'chờ xác nhận')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _cancelOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50], // Soft red
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.red)),
                    ),
                    child: _isLoading 
                       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                       : const Text('Hủy đơn hàng'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
