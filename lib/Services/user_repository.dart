import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/user_model.dart';
import 'package:do_an_quan_ao/Model/payment_method_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromSnapshot(doc)).toList();
    });
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return UserModel.fromSnapshot(doc);
    }
    return null;
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
    });
  }
  
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }
  
  // Payment Methods
  Stream<List<PaymentMethod>> getPaymentMethods(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return PaymentMethod.fromJson(data);
      }).toList();
    });
  }

  Future<void> addPaymentMethod(String userId, PaymentMethod method) async {
    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    final methodRef = userRef.collection('payment_methods').doc(); // Auto ID

    // If setting as default, unset others // Or just handle it in UI/separate call
    // Logic: if method.isDefault, update others. 
    // Simplification: just add. 
    // Actually, if it's the first method, make it default.
    final snapshot = await userRef.collection('payment_methods').get();
    bool isFirst = snapshot.docs.isEmpty;
    
    final newMethodData = method.toJson();
    newMethodData['id'] = methodRef.id;
    if (isFirst) {
      newMethodData['isDefault'] = true;
    }

    batch.set(methodRef, newMethodData);
    await batch.commit();
  }

  Future<void> deletePaymentMethod(String userId, String methodId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(methodId)
        .delete();
  }

  Future<void> setDefaultPaymentMethod(String userId, String methodId) async {
    final methodsRef = _firestore.collection('users').doc(userId).collection('payment_methods');
    final snapshot = await methodsRef.get();
    
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      if (doc.id == methodId) {
        batch.update(doc.reference, {'isDefault': true});
      } else {
        batch.update(doc.reference, {'isDefault': false});
      }
    }
    await batch.commit();
  }
  Future<void> updatePaymentMethod(String userId, PaymentMethod method) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('payment_methods')
        .doc(method.id)
        .update(method.toJson());
  }
}
