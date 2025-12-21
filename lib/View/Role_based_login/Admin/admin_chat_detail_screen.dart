import 'package:bubble/bubble.dart';
import 'package:do_an_quan_ao/Model/chat_model.dart';
import 'package:do_an_quan_ao/Services/chat_service.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:flutter/material.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:intl/intl.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    String msg = _messageController.text.trim();
    _messageController.clear();
    _chatService.sendAdminMessage(widget.userId, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
              stream: _chatService.getMessages(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return const Center(child: Text('Chưa có tin nhắn nào', style: TextStyle(color: Colors.grey)));
                }

                final messages = snapshot.data!;
                // Mark user messages as read by admin when viewing
                 for(var msg in messages) {
                  if (!msg.isAdmin && !msg.isRead) {
                    _chatService.markAsRead(widget.userId, isAdminReading: true);
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
                      alignment: !message.isAdmin ? Alignment.topLeft : Alignment.topRight,
                      nip: !message.isAdmin ? BubbleNip.leftTop : BubbleNip.rightTop,
                      color: !message.isAdmin ? Colors.white : const Color(0xFFD29062),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (message.orderId != null)
                             _buildOrderAttachment(message),
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
                                color: !message.isAdmin ? Colors.black : Colors.white,
                                fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: TextStyle(
                              color: !message.isAdmin ? Colors.grey : Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  order: GroupedListOrder.ASC,
                  useStickyGroupSeparators: true,
                  floatingHeader: true,
                  reverse: true,
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
                      hintText: 'Nhập tin nhắn trả lời...',
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

  Widget _buildOrderAttachment(ChatMessage message) {
      return Container(
          width: 200,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
              children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: UniversalImage(
                          imageUrl: message.productImage ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                      )
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(
                                  '#${message.orderId!.length > 8 ? message.orderId!.substring(0,8).toUpperCase() : message.orderId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  message.orderStatus ?? '',
                                  style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  '₫${message.orderTotal}',
                                  style: const TextStyle(color: Colors.black87, fontSize: 11)
                              ),
                          ]
                      )
                  )
              ]
          )
      );
  }
}
