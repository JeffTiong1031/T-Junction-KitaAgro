import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'like', 'friend_request', 'bot_reminder'
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.timestamp,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? 'info',
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Stream for current user notifications
  Stream<List<NotificationModel>> getNotificationsStream() {
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Stream unseen count
  Stream<int> getUnseenCountStream() {
    if (currentUserId == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    if (currentUserId == null) return;

    final unreadDocs = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadDocs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Mark single as read
  Future<void> markAsRead(String notificationId) async {
    if (currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // General internal method to send notification
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
  }) async {
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
