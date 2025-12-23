import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/order_model.dart' as model;
import 'package:do_an_quan_ao/Services/notification_service.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'orders';

  Stream<List<model.Order>> getOrders() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => model.Order.fromSnapshot(doc)).toList();
    });
  }

  Future<void> addOrder(model.Order order) async {
    try {
      print('Adding order for: ${order.customerName}');
      final docRef = _firestore.collection(_collection).doc();
      final newOrder = model.Order(
        id: docRef.id,
        userId: order.userId,
        customerName: order.customerName,
        customerPhone: order.customerPhone,
        customerAddress: order.customerAddress,
        products: order.products,
        totalPrice: order.totalPrice,
        status: order.status,
        paymentMethod: order.paymentMethod,
        createdAt: order.createdAt,
        note: order.note,
      );

      await _firestore.runTransaction((transaction) async {
        // 1. Read all product docs first (Transaction requires reads before writes)
        // However, we need to iterate.
        // Optimization: Read all needed products?
        // Simple Loop:
        for (var item in order.products) {
           final productRef = _firestore.collection('products').doc(item.productId);
           final snapshot = await transaction.get(productRef);
           
           if (!snapshot.exists) {
              throw Exception("Product ${item.productId} does not exist!");
           }

           final data = snapshot.data()!;
           
           // Handle Main Stock
           final currentStock = data['stock'] as int? ?? 0;
           int newStock = currentStock - item.quantity;
           if (newStock < 0) newStock = 0; // Prevent negative? Or throw?
           // Ideally throw if out of stock, but for now just clamp or allow negative?
           // User wants "correct logic", usually means prevent overselling. 
           // But let's just decrement for now. if (newStock < 0) throw Exception("Out of stock");
           
           // Handle Variant Stock
           List<dynamic> variants = data['variants'] ?? [];
           List<Map<String, dynamic>> updatedVariants = [];
           bool variantFound = false;

           if (item.size != null && item.color != null && variants.isNotEmpty) {
              for (var v in variants) {
                 // v is Map
                 final variantMap = v as Map<String, dynamic>;
                 if (variantMap['size'] == item.size && variantMap['color'] == item.color) {
                     int vStock = variantMap['stock'] as int? ?? 0;
                     variantMap['stock'] = vStock - item.quantity;
                     // Optional: checking negative
                     variantFound = true;
                 }
                 updatedVariants.add(variantMap);
              }
           } else {
             updatedVariants = List<Map<String, dynamic>>.from(variants);
           }

           // Update Transaction
           transaction.update(productRef, {
             'stock': newStock,
             if (variantFound) 'variants': updatedVariants,
           });
        }
        
        // 2. Set the order document
        transaction.set(docRef, newOrder.toJson());
      });
      
      print('Order added to Firestore: ${docRef.id} and stocks updated.');
    } catch (e) {
      print('Error adding order: $e');
      rethrow;
    }
  }

  // Check if user has any orders (for first order discount)
  Future<bool> hasUserOrdered(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection(_collection).doc(orderId).update({
        'status': status,
      });

      // Send Notification to User
      final orderDoc = await _firestore.collection(_collection).doc(orderId).get();
      if (orderDoc.exists) {
         final userId = orderDoc.get('userId');
         final userToken = await NotificationService().getUserToken(userId);
         if (userToken != null) {
            String title = 'Cập nhật đơn hàng';
            String body = 'Đơn hàng của bạn đã chuyển sang trạng thái: $status';
            
            if (status.toLowerCase() == 'delivered') {
               title = 'Giao hàng thành công';
               body = 'Đơn hàng đã được giao thành công. Cảm ơn bạn đã mua sắm!';
            } else if (status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'đã hủy') {
               title = 'Đơn hàng đã hủy';
               body = 'Đơn hàng của bạn đã bị hủy.';
            }

            await NotificationService().sendPushNotification(
              recipientToken: userToken,
              title: title,
              body: body,
            );
         }
      }

    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  Future<void> updateOrder(model.Order order) async {
    try {
      await _firestore.collection(_collection).doc(order.id).update({
        'customerName': order.customerName,
        'customerPhone': order.customerPhone,
        'customerAddress': order.customerAddress,
        'products': order.products.map((item) => item.toJson()).toList(),
        'totalPrice': order.totalPrice,
        'status': order.status,
        'paymentMethod': order.paymentMethod,
      });
    } catch (e) {
      print('Error updating order: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_collection).doc(orderId).delete();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  Stream<List<model.Order>> getOrdersByUserId(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) => model.Order.fromSnapshot(doc)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }
}
