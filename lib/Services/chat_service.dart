import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- USER METHODS ---

  // Check if chat session exists, if not create one
  Future<void> createOrUpdateChatSession(String userId, String userName, String userEmail, {String? userAvatar}) async {
    final docRef = _firestore.collection('chats').doc(userId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isReadByAdmin': false,
        'isReadByUser': true,
        'userAvatar': userAvatar,
      });
    } else {
      // Just update user details if changed? Not priority now.
    }
  }

  // User sends a message
  Future<void> sendUserMessage(String userId, String text, String userName, String userEmail) async {
    // 1. Ensure Session Exists
    final docRef = _firestore.collection('chats').doc(userId);
    
    // 2. Add Message to Subcollection
    await docRef.collection('messages').add({
      'senderId': userId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isAdmin': false,
      'isRead': false,
    });

    // 3. Update Session Summary
    await docRef.set({
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isReadByAdmin': false, // Admin hasn't read it yet
      'isReadByUser': true,
    }, SetOptions(merge: true));
  }

  // --- ADMIN METHODS ---

  // Admin sends a message
  Future<void> sendAdminMessage(String userId, String text, {
    String? orderId,
    String? orderStatus,
    String? orderTotal,
    String? productImage,
  }) async {
    final docRef = _firestore.collection('chats').doc(userId);
    
    await docRef.collection('messages').add({
      'senderId': 'ADMIN',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isAdmin': true,
      'isRead': false,
      if (orderId != null) 'orderId': orderId,
      if (orderStatus != null) 'orderStatus': orderStatus,
      if (orderTotal != null) 'orderTotal': orderTotal,
      if (productImage != null) 'productImage': productImage,
    });

    await docRef.update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'isReadByAdmin': true,
      'isReadByUser': false, // User hasn't read it yet
    });
  }

  // Mark messages as read
  Future<void> markAsRead(String userId, {required bool isAdminReading}) async {
    final docRef = _firestore.collection('chats').doc(userId);
    final batch = _firestore.batch();
    
    // 1. Update Session Status
    if (isAdminReading) {
      batch.update(docRef, {'isReadByAdmin': true});
    } else {
      batch.update(docRef, {'isReadByUser': true});
    }

    // 2. Update Unread Messages
    final messagesQuery = docRef.collection('messages')
        .where('isAdmin', isEqualTo: !isAdminReading) 
        .where('isRead', isEqualTo: false);

    final unreadDocs = await messagesQuery.get();
    for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // --- STREAMS ---

  // Get all messages for a specific chat (Used by both)
  Stream<List<ChatMessage>> getMessages(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromSnapshot(doc))
            .toList());
  }

  // Get all chat sessions (Admin only) - Ordered by latest message
  Stream<List<ChatSession>> getChatSessions() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSession.fromSnapshot(doc))
            .toList());
  }
}
