import 'package:cloud_firestore/cloud_firestore.dart';

class Voucher {
  final String id;
  final String code;
  final String type; 
  final double value;
  final double minOrderValue;
  final double maxDiscount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int usageLimit;
  final int usedCount;

  Voucher({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.minOrderValue,
    required this.maxDiscount,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.usageLimit = 0,
    this.usedCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type,
      'value': value,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
    };
  }

  factory Voucher.fromJson(Map<String, dynamic> json, String id) {
    return Voucher(
      id: id,
      code: json['code'] ?? '',
      type: json['type'] ?? 'percent',
      value: (json['value'] ?? 0).toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      maxDiscount: (json['maxDiscount'] ?? 0).toDouble(),
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      isActive: json['isActive'] ?? true,
      usageLimit: json['usageLimit'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
    );
  }
}
