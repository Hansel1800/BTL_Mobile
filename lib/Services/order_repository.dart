import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/order_model.dart' as model;

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
      await docRef.set(newOrder.toJson());
      print('Order added to Firestore: ${docRef.id}');
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
