import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final int position;
  final bool isActive;
  final int clickCount;
  final double conversionRate;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.position,
    required this.isActive,
    this.clickCount = 0,
    this.conversionRate = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'position': position,
      'isActive': isActive,
      'clickCount': clickCount,
      'conversionRate': conversionRate,
    };
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      position: json['position'] ?? 0,
      isActive: json['isActive'] ?? true,
      clickCount: json['clickCount'] ?? 0,
      conversionRate: (json['conversionRate'] ?? 0).toDouble(),
    );
  }

  factory BannerModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel.fromJson(data);
  }
}

class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountType; // 'percent', 'amount'
  final double discountValue;
  final double minOrderValue;
  final DateTime startDate;
  final DateTime endDate;
  final int usageLimit;
  final int usageCount;
  final bool isActive;

  VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.startDate,
    required this.endDate,
    required this.usageLimit,
    required this.usageCount,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'isActive': isActive,
    };
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'amount',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      usageLimit: json['usageLimit'] ?? 0,
      usageCount: json['usageCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  factory VoucherModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoucherModel.fromJson(data);
  }
}
