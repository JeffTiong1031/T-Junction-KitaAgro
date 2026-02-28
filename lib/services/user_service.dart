import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Search users by username or fullName
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    // Convert to lowercase to make search case-insensitive if needed,
    // but Firestore simple queries require exact matches or startswith
    final result = await _firestore
        .collection('users')
        // Simple startsWith query (Case Sensitive usually, unless structured otherwise)
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return result.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // Get User by ID
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Send a Friend Request
  Future<void> sendFriendRequest(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Add current user to the target's friendRequests array
    await _firestore.collection('users').doc(targetUserId).update({
      'friendRequests': FieldValue.arrayUnion([currentUserId]),
    });

    final senderDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    final senderName = senderDoc.data()?['fullName'] ?? 'Someone';

    await _notificationService.sendNotification(
      targetUserId: targetUserId,
      title: 'New Friend Request',
      body: '$senderName sent you a friend request.',
      type: 'friend_request',
    );
  }

  // Accept a Friend Request
  Future<void> acceptFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Remove from friendRequests, Add to friends for current user
    await _firestore.collection('users').doc(currentUserId).update({
      'friendRequests': FieldValue.arrayRemove([senderId]),
      'friends': FieldValue.arrayUnion([senderId]),
    });

    // Add to friends for sender
    await _firestore.collection('users').doc(senderId).update({
      'friends': FieldValue.arrayUnion([currentUserId]),
    });
  }

  // Reject a Friend Request
  Future<void> rejectFriendRequest(String senderId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Remove from friendRequests
    await _firestore.collection('users').doc(currentUserId).update({
      'friendRequests': FieldValue.arrayRemove([senderId]),
    });
  }

  // Stream friend requests
  Stream<List<UserModel>> streamFriendRequests() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) return [];
          final user = UserModel.fromMap(doc.data()!);
          List<UserModel> requesters = [];
          for (var reqId in user.friendRequests) {
            final reqDoc = await _firestore
                .collection('users')
                .doc(reqId)
                .get();
            if (reqDoc.exists) {
              requesters.add(UserModel.fromMap(reqDoc.data()!));
            }
          }
          return requesters;
        });
  }

  // Stream friends
  Stream<List<UserModel>> streamFriends() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .asyncMap((doc) async {
          if (!doc.exists) return [];
          final user = UserModel.fromMap(doc.data()!);
          List<UserModel> friendsList = [];
          for (var friendId in user.friends) {
            final friendDoc = await _firestore
                .collection('users')
                .doc(friendId)
                .get();
            if (friendDoc.exists) {
              friendsList.add(UserModel.fromMap(friendDoc.data()!));
            }
          }
          return friendsList;
        });
  }

  // Stream current user to get friend statuses dynamically
  Stream<UserModel?> streamCurrentUser() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return const Stream.empty();

    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }
}
