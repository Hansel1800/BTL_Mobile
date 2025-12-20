import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/promotion_model.dart';

class PromotionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Banners
  Stream<List<BannerModel>> getBanners() {
    return _firestore.collection('banners').orderBy('position').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BannerModel.fromSnapshot(doc)).toList();
    });
  }

  Future<void> addBanner(BannerModel banner) async {
    await _firestore.collection('banners').doc(banner.id).set(banner.toJson());
  }

  Future<void> updateBanner(BannerModel banner) async {
    await _firestore.collection('banners').doc(banner.id).update(banner.toJson());
  }

  Future<void> deleteBanner(String id) async {
    await _firestore.collection('banners').doc(id).delete();
  }

  // Vouchers
  Stream<List<VoucherModel>> getVouchers() {
    return _firestore.collection('vouchers').orderBy('startDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => VoucherModel.fromSnapshot(doc)).toList();
    });
  }

  Future<void> addVoucher(VoucherModel voucher) async {
    await _firestore.collection('vouchers').doc(voucher.id).set(voucher.toJson());
  }

  Future<void> updateVoucher(VoucherModel voucher) async {
    await _firestore.collection('vouchers').doc(voucher.id).update(voucher.toJson());
  }

  Future<void> deleteVoucher(String id) async {
    await _firestore.collection('vouchers').doc(id).delete();
  }

  Future<VoucherModel?> getVoucherByCode(String code) async {
    final snapshot = await _firestore
        .collection('vouchers')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
        
    if (snapshot.docs.isNotEmpty) {
      return VoucherModel.fromSnapshot(snapshot.docs.first);
    }
    return null;
  }
}
