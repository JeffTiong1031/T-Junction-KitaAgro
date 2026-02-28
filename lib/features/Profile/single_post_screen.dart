import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kita_agro/features/community/community_service.dart';
import 'package:kita_agro/features/community/comments_screen.dart';
import 'package:kita_agro/services/user_service.dart';
import 'package:kita_agro/core/models/user_model.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

class SinglePostScreen extends StatefulWidget {
  final DocumentSnapshot postDoc;

  const SinglePostScreen({super.key, required this.postDoc});

  @override
  State<SinglePostScreen> createState() => _SinglePostScreenState();
}

class _SinglePostScreenState extends State<SinglePostScreen> {
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postDoc.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snapshot.data!;
        if (!doc.exists) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Post', style: TextStyle(color: Colors.black)),
            ),
            body: const Center(child: Text('Post has been deleted.')),
          );
        }

        final data = doc.data() as Map<String, dynamic>;
        final publisherId = data['publisherId'] as String?;
        final username = data['publisherName'] ?? 'Unknown User';
        final userProfilePic = data['publisherProfilePic'] ?? '?';
        final caption = data['caption'] ?? '';
        final imageUrl = data['imageUrl'] ?? '';
        final likesCount = data['likesCount'] ?? 0;
        final commentsCount = data['commentsCount'] ?? 0;
        final likedBy = data['likedBy'] as List<dynamic>? ?? [];

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final isMyPost = publisherId == currentUserId;
        final isLiked =
            currentUserId != null && likedBy.contains(currentUserId);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Posts',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.teal[300],
                            backgroundImage: userProfilePic.length > 5
                                ? NetworkImage(userProfilePic)
                                : null,
                            radius: 20,
                            child: userProfilePic.length <= 5
                                ? Text(
                                    userProfilePic.isNotEmpty
                                        ? userProfilePic[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (!isMyPost && publisherId != null)
                            StreamBuilder<UserModel?>(
                              stream: _userService.streamCurrentUser(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData)
                                  return const SizedBox();
                                final currentUserData = userSnapshot.data!;

                                final isFriend = currentUserData.friends
                                    .contains(publisherId!);
                                final hasRequested = currentUserData
                                    .friendRequests
                                    .contains(publisherId!);

                                if (isFriend || hasRequested)
                                  return const SizedBox();

                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await _userService.sendFriendRequest(
                                        publisherId!,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Friend request sent!',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      '• Add Friend',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      if (isMyPost)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _confirmDeletePost(context, doc.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete Post',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.black,
                            size: 24,
                          ),
                        )
                      else
                        const Icon(
                          Icons.more_vert,
                          color: Colors.black,
                          size: 24,
                        ),
                    ],
                  ),
                ),

                // Post Image
                if (imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[200],
                      child: const Center(child: Icon(Icons.error_outline)),
                    ),
                  ),

                // Engagement Metrics
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (currentUserId != null) {
                            _communityService.toggleLike(
                              doc.id,
                              currentUserId,
                              likedBy,
                            );
                          }
                        },
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 28,
                          color: isLiked ? Colors.red : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => showCommentsBottomSheet(context, doc.id),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 26,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.send_outlined,
                        size: 26,
                        color: Colors.black,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.bookmark_border,
                        size: 28,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),

                // Likes Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '$likesCount likes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                // Caption
                if (caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        children: [
                          TextSpan(
                            text: '$username ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: caption),
                        ],
                      ),
                    ),
                  ),

                // Comments count
                if (commentsCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () => showCommentsBottomSheet(context, doc.id),
                      child: Text(
                        '${AppLocalizations.of(context).viewAllComments} $commentsCount ${AppLocalizations.of(context).comments.toLowerCase()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () => showCommentsBottomSheet(context, doc.id),
                      child: Text(
                        AppLocalizations.of(context).writeAComment,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _communityService.deletePost(postId); // Delete the post
              Navigator.pop(context); // Go back to profile screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
