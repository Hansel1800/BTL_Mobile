import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/voucher_model.dart';

class VoucherRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Voucher>> getVouchers() {
    return _firestore.collection('vouchers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Voucher.fromJson(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addVoucher(Voucher voucher) async {
    await _firestore.collection('vouchers').add(voucher.toJson());
  }

  Future<void> updateVoucher(Voucher voucher) async {
    await _firestore.collection('vouchers').doc(voucher.id).update(voucher.toJson());
  }

  Future<void> deleteVoucher(String id) async {
    await _firestore.collection('vouchers').doc(id).delete();
  }

  Future<Voucher?> getVoucherByCode(String code) async {
    final snapshot = await _firestore
        .collection('vouchers')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      return Voucher.fromJson(snapshot.docs.first.data(), snapshot.docs.first.id);
    }
    return null;
  }
}
