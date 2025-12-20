import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final DateTime createdAt;
  final bool isActive;
  final String fullName;
  final String dob;
  final String? gender;
  final String? city;
  final List<String> preferences;
  final String? avatarUrl;
  final String address;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber = '',
    required this.createdAt,
    this.isActive = true,
    this.fullName = '',
    this.dob = '',
    this.gender,
    this.city,
    this.preferences = const [],
    this.avatarUrl,
    this.address = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'createAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'fullName': fullName,
      'dob': dob,
      'gender': gender,
      'city': city,
      'preferences': preferences,
      'avatarUrl': avatarUrl,
      'address': address,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'User',
      phoneNumber: json['phoneNumber'] ?? '',
      createdAt: (json['createAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      fullName: json['fullName'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'],
      city: json['city'],
      preferences: List<String>.from(json['preferences'] ?? []),
      avatarUrl: json['avatarUrl'],
      address: json['address'] ?? '',
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'User',
      phoneNumber: data['phoneNumber'] ?? '',
      createdAt: (data['createAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      fullName: data['fullName'] ?? '',
      dob: data['dob'] ?? '',
      gender: data['gender'],
      city: data['city'],
      preferences: List<String>.from(data['preferences'] ?? []),
      avatarUrl: data['avatarUrl'],
      address: data['address'] ?? '',
    );
  }
}
