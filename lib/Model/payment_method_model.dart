import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethod {
  final String id;
  final String type; // 'VISA', 'MOMO', 'COD'
  final String title;
  final String subtitle;
  final bool isDefault;
  final Map<String, dynamic> details; // e.g., cardNumber, phoneNumber

  PaymentMethod({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.isDefault = false,
    this.details = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'isDefault': isDefault,
      'details': details,
    };
  }

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      type: json['type'] ?? 'COD',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      isDefault: json['isDefault'] ?? false,
      details: json['details'] ?? {},
    );
  }
}
