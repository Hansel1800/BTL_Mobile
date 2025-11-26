import 'package:do_an_quan_ao/Model/promotion_model.dart';
import 'package:do_an_quan_ao/Services/promotion_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final promotionRepositoryProvider = Provider((ref) => PromotionRepository());

final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(promotionRepositoryProvider).getBanners();
});

final vouchersProvider = StreamProvider<List<VoucherModel>>((ref) {
  return ref.watch(promotionRepositoryProvider).getVouchers();
});

final promotionControllerProvider = NotifierProvider<PromotionController, void>(PromotionController.new);

class PromotionController extends Notifier<void> {
  @override
  void build() {}

  Future<void> addBanner(BannerModel banner) async {
    final repository = ref.read(promotionRepositoryProvider);
    await repository.addBanner(banner);
  }

  Future<void> updateBanner(BannerModel banner) async {
    final repository = ref.read(promotionRepositoryProvider);
    await repository.updateBanner(banner);
  }

  Future<void> deleteBanner(String id) async {
    final repository = ref.read(promotionRepositoryProvider);
    await repository.deleteBanner(id);
  }

  Future<void> addVoucher(VoucherModel voucher) async {
    final repository = ref.read(promotionRepositoryProvider);
    await repository.addVoucher(voucher);
  }

  Future<void> updateVoucher(VoucherModel voucher) async {
    final repository = ref.read(promotionRepositoryProvider);
    await repository.updateVoucher(voucher);
  }

  Future<void> deleteVoucher(String id) async {
    final repository = ref.read(promotionRepositoryProvider);
    await repository.deleteVoucher(id);
  }
}
