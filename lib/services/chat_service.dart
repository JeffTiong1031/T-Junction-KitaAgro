import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Generate Chat ID from two user IDs to ensure a single chat
  String getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  // Get stream of chats for current user
  Stream<QuerySnapshot> getChatsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  // Get stream of messages for a chat
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Send message
  Future<void> sendMessage(
    String receiverId,
    String text, {
    String? imageUrl,
    String? voiceUrl,
    String? fileUrl,
    String? fileName,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final chatId = getChatId(currentUserId, receiverId);
    final timestamp = Timestamp.now();

    final message = {
      'senderId': currentUserId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'reactions': [],
    };

    // Make sure chat document exists
    await _firestore.collection('chats').doc(chatId).set({
      'participants': [currentUserId, receiverId],
      'lastMessage': text.isEmpty
          ? (imageUrl != null
                ? 'Sent an image'
                : (voiceUrl != null
                      ? 'Sent a voice message'
                      : (fileUrl != null ? 'Sent a file' : 'Attachment')))
          : text,
      'lastUpdated': timestamp,
      'lastSenderId': currentUserId,
      'unreadCount': {receiverId: FieldValue.increment(1), currentUserId: 0},
    }, SetOptions(merge: true));

    // Add to messages subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message);
  }

  // Upload file to storage and return url
  Future<String?> uploadFile(File file, String pathPattern) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final destination = 'chats/$pathPattern/$fileName';
      final ref = _storage.ref(destination);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // React to a message
  Future<void> reactToMessage(
    String chatId,
    String messageId,
    String emoji,
  ) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final docRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    final doc = await docRef.get();

    if (doc.exists) {
      List reactions = doc.data()?['reactions'] ?? [];

      // Find existing reaction from this user and remove it
      reactions.removeWhere((r) => r['uid'] == currentUserId);

      // Add new reaction
      reactions.add({'uid': currentUserId, 'emoji': emoji});

      await docRef.update({'reactions': reactions});
    }
  }

  // Mark chat as read
  Future<void> markChatAsRead(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // We update using merge: true to avoid losing other fields
    await _firestore.collection('chats').doc(chatId).set({
      'unreadCount': {currentUserId: 0},
    }, SetOptions(merge: true));
  }

  // Stream for total unread chats count
  Stream<int> getUnreadChatsCountStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          int count = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadData = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadData != null && (unreadData[currentUserId] ?? 0) > 0) {
              count++;
            }
          }
          return count;
        });
  }
}
