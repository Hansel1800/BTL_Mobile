import 'package:do_an_quan_ao/Model/chat_model.dart';
import 'package:do_an_quan_ao/Services/chat_service.dart';
import 'package:do_an_quan_ao/View/Role_based_login/Admin/admin_chat_detail_screen.dart';
import 'package:do_an_quan_ao/View/Widgets/universal_image.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Tin nhắn khách hàng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<ChatSession>>(
        stream: _chatService.getChatSessions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Chưa có tin nhắn nào', style: TextStyle(color: Colors.grey)));
          }

          final sessions = snapshot.data!;

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        child: session.userAvatar != null && session.userAvatar!.isNotEmpty
                            ? ClipOval(
                                child: UniversalImage(
                                  imageUrl: session.userAvatar!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Text(
                                session.userName.isNotEmpty ? session.userName[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                      ),
                      if (!session.isReadByAdmin)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    session.userName,
                    style: TextStyle(
                      fontWeight: !session.isReadByAdmin ? FontWeight.bold : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        (session.lastMessage.contains('\nhttp') || session.lastMessage.contains('\ndata:image'))
                            ? (session.lastMessage.contains('Tôi đang quan tâm') ? 'Khách hàng quan tâm sản phẩm' : '[Hình ảnh]')
                            : session.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: !session.isReadByAdmin ? Colors.black87 : Colors.grey,
                          fontWeight: !session.isReadByAdmin ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    timeago.format(session.lastMessageTime, locale: 'vi'),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminChatDetailScreen(
                          userId: session.userId,
                          userName: session.userName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
