import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:do_an_quan_ao/Model/product_model.dart';
import 'package:do_an_quan_ao/Model/chat_model.dart';
import 'package:do_an_quan_ao/Services/chat_service.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bubble/bubble.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

class UserChatScreen extends StatefulWidget {
  final Product? product;
  const UserChatScreen({super.key, this.product});

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _userId;
  String _userName = 'Khách';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser!.uid;
    _fetchUserInfo();
    
    if (widget.product != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
             _sendProductInfo(widget.product!);
        });
    }
  }

  void _sendProductInfo(Product product) {
      String msg = "Tôi đang quan tâm tới sản phẩm: ${product.name}\n${product.imageUrl}";
      _chatService.sendUserMessage(_userId, msg, _userName, _userEmail);
  }

  Future<void> _fetchUserInfo() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(_userId).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _userName = data['fullName'] ?? data['name'] ?? 'Khách';
        _userEmail = data['email'] ?? '';
      });
      // Initialize/Update session
      _chatService.createOrUpdateChatSession(_userId, _userName, _userEmail, userAvatar: data['avatarUrl']);
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    String msg = _messageController.text.trim();
    _messageController.clear();
    _chatService.sendUserMessage(_userId, msg, _userName, _userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Chat với Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Bắt đầu cuộc trò chuyện với Admin', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;
                // Mark Admin messages as read
                for(var msg in messages) {
                  if (msg.isAdmin && !msg.isRead) {
                    _chatService.markAsRead(_userId, isAdminReading: false);
                    break; 
                  }
                }

                return GroupedListView<ChatMessage, DateTime>(
                  padding: const EdgeInsets.all(8),
                  elements: messages,
                  groupBy: (message) => DateTime(
                    message.timestamp.year,
                    message.timestamp.month,
                    message.timestamp.day,
                  ),
                  groupHeaderBuilder: (ChatMessage message) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(message.timestamp),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                  itemBuilder: (context, ChatMessage message) {
                    String displayText = message.text;
                    String? imageUrl;
                    
                    if (message.text.contains('\nhttp')) {
                        final parts = message.text.split('\n');
                        if (parts.length > 1 && parts.last.startsWith('http')) {
                              imageUrl = parts.last;
                              displayText = parts.sublist(0, parts.length - 1).join('\n');
                        }
                    } else if (message.text.contains('\ndata:image')) {
                        final parts = message.text.split('\n');
                        if (parts.length > 1 && parts.last.startsWith('data:image')) {
                              imageUrl = parts.last;
                              displayText = parts.sublist(0, parts.length - 1).join('\n');
                        }
                    }

                    return Bubble(
                      margin: const BubbleEdges.only(top: 10),
                      alignment: message.isAdmin ? Alignment.topLeft : Alignment.topRight,
                      nip: message.isAdmin ? BubbleNip.leftTop : BubbleNip.rightTop,
                      color: message.isAdmin ? Colors.white : const Color(0xFFD29062),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null)
                             Padding(
                               padding: const EdgeInsets.only(bottom: 8.0),
                               child: ClipRRect(
                                 borderRadius: BorderRadius.circular(8),
                                 child: UniversalImage(imageUrl: imageUrl!, width: 200, height: 200, fit: BoxFit.cover)
                               ),
                             ),
                          Text(
                            displayText,
                            style: TextStyle(
                                color: message.isAdmin ? Colors.black : Colors.white,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: TextStyle(
                              color: message.isAdmin ? Colors.grey : Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  order: GroupedListOrder.ASC, // Show oldest first? No, list is DESC.
                  // Actually, generic ListView builder receives reversed list usually.
                  // Let's check stream sort order.
                  // Stream: orderBy('timestamp', descending: true) -> Newest first.
                  // GroupedListView: order ASC means it sorts GROUPS ascending (Oldest dates top).
                  // But elements inside?
                  // We should inverse list or change stream order.
                  // Let's use simple ListView.builder reverse: true
                  useStickyGroupSeparators: true, 
                  floatingHeader: true,
                  reverse: true, // IMPORTANT for chat
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFD29062),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
