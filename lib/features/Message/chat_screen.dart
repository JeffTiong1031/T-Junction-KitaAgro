import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../core/models/user_model.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiverUser;

  const ChatScreen({super.key, required this.receiverUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _chatId;
  late StreamSubscription _messageSub;

  @override
  void initState() {
    super.initState();
    _chatId = _chatService.getChatId(
      _auth.currentUser!.uid,
      widget.receiverUser.uid,
    );
    _chatService.markChatAsRead(_chatId);

    _messageSub = _chatService.getMessagesStream(_chatId).listen((_) {
      _chatService.markChatAsRead(_chatId);
    });
  }

  @override
  void dispose() {
    _messageSub.cancel();
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    String text = _messageController.text;
    _messageController.clear();

    await _chatService.sendMessage(widget.receiverUser.uid, text);
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String? url = await _chatService.uploadFile(file, 'images');
      if (url != null) {
        await _chatService.sendMessage(
          widget.receiverUser.uid,
          '',
          imageUrl: url,
        );
      }
    }
  }

  void _showReactionMenu(String messageId, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy - 60,
        position.dx + 40,
        0,
      ),
      items: [
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildReactionButton(messageId, '❤️'),
              _buildReactionButton(messageId, '👍'),
              _buildReactionButton(messageId, '😂'),
              _buildReactionButton(messageId, '😮'),
              _buildReactionButton(messageId, '😢'),
            ],
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildReactionButton(String messageId, String emoji) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _chatService.reactToMessage(_chatId, messageId, emoji);
      },
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed to white
      appBar: AppBar(
        backgroundColor: Colors.white, // Changed to white
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87), // Make back button black
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.receiverUser.profilePicUrl.isNotEmpty
                  ? NetworkImage(widget.receiverUser.profilePicUrl)
                  : null,
              backgroundColor: Colors.grey[300], // Lighter grey avatar background
              child: widget.receiverUser.profilePicUrl.isEmpty
                  ? Text(
                      widget.receiverUser.fullName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.black87, fontSize: 14), // Black letter
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverUser.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // Changed to black
                    ),
                  ),
                  const Text(
                    'Active now',
                    style: TextStyle(fontSize: 12, color: Colors.black54), // Changed to darker grey
                  ),
                ],
              ),
            ),
            Icon(Icons.call, color: Colors.blueAccent[400]),
            const SizedBox(width: 16),
            Icon(Icons.videocam, color: Colors.blueAccent[400]),
            const SizedBox(width: 16),
            Icon(Icons.info, color: Colors.blueAccent[400]),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(
                    child: Text("Error", style: TextStyle(color: Colors.black54)), // Changed to dark grey
                  );
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;
                if (messages.isEmpty)
                  return const Center(
                    child: Text(
                      'Say hi!',
                      style: TextStyle(color: Colors.black54), // Changed to dark grey
                    ),
                  );

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final docId = messages[index].id;
                    final isSentByMe =
                        data['senderId'] == _auth.currentUser?.uid;

                    return _buildMessageItem(data, isSentByMe, docId);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    Map<String, dynamic> data,
    bool isSentByMe,
    String messageId,
  ) {
    final text = data['text'] ?? '';
    final imageUrl = data['imageUrl'];
    final List reactions = data['reactions'] ?? [];

    return GestureDetector(
      onLongPressStart: (details) {
        _showReactionMenu(messageId, details.globalPosition);
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isSentByMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),

            if (text.isNotEmpty)
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSentByMe ? Colors.blueAccent[700] : Colors.grey[200], // Sent=Blue, Received=Light Grey
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight: isSentByMe
                        ? const Radius.circular(4)
                        : const Radius.circular(20),
                    bottomLeft: !isSentByMe
                        ? const Radius.circular(4)
                        : const Radius.circular(20),
                  ),
                ),
                child: Text(
                  text,
                  // Sent text stays white, received text becomes black
                  style: TextStyle(fontSize: 16, color: isSentByMe ? Colors.white : Colors.black87), 
                ),
              ),

            // Reactions display
            if (reactions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white, // Changed to white
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5), // Lighter border
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: reactions
                      .map<Widget>(
                        (r) => Text(
                          r['emoji'],
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white, // Changed to white
      child: SafeArea(
        child: Row(
          children: [
            Icon(Icons.add_circle, color: Colors.blueAccent[400], size: 28),
            const SizedBox(width: 8),
            Icon(Icons.camera_alt, color: Colors.blueAccent[400], size: 28),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendImage,
              child: Icon(Icons.image, color: Colors.blueAccent[400], size: 28),
            ),
            const SizedBox(width: 8),
            Icon(Icons.mic, color: Colors.blueAccent[400], size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200], // Changed to light grey
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.black87), // Changed to black
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(color: Colors.grey[600]), // Changed to darker grey
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, child) {
                if (value.text.trim().isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: GestureDetector(
                    onTap: _sendMessage,
                    child: Icon(
                      Icons.send,
                      color: Colors.blueAccent[400],
                      size: 28,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
