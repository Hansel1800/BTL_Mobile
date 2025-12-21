import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isAdmin;
  final bool isRead;
  // Order attachment fields
  final String? orderId;
  final String? orderStatus;
  final String? orderTotal; // Store as formatted string or double? String is easier for display here
  final String? productImage;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isAdmin,
    this.isRead = false,
    this.orderId,
    this.orderStatus,
    this.orderTotal,
    this.productImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAdmin': isAdmin,
      'isRead': isRead,
      if (orderId != null) 'orderId': orderId,
      if (orderStatus != null) 'orderStatus': orderStatus,
      if (orderTotal != null) 'orderTotal': orderTotal,
      if (productImage != null) 'productImage': productImage,
    };
  }

  factory ChatMessage.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAdmin: data['isAdmin'] ?? false,
      isRead: data['isRead'] ?? false,
      orderId: data['orderId'],
      orderStatus: data['orderStatus'],
      orderTotal: data['orderTotal'],
      productImage: data['productImage'],
    );
  }
}

class ChatSession {
  final String userId;
  final String userName;
  final String userEmail;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool isReadByAdmin;
  final bool isReadByUser;
  final String? userAvatar;

  ChatSession({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.lastMessage,
    required this.lastMessageTime,
    this.isReadByAdmin = false,
    this.isReadByUser = false,
    this.userAvatar,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'isReadByAdmin': isReadByAdmin,
      'isReadByUser': isReadByUser,
      'userAvatar': userAvatar,
    };
  }

  factory ChatSession.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      userId: doc.id,
      userName: data['userName'] ?? 'Unknown User',
      userEmail: data['userEmail'] ?? '',
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isReadByAdmin: data['isReadByAdmin'] ?? true,
      isReadByUser: data['isReadByUser'] ?? true,
      userAvatar: data['userAvatar'],
    );
  }
}
