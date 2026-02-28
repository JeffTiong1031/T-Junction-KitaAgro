import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/user_model.dart';
import '../../features/auth/auth_service.dart';
import '../auth/welcome_screen.dart';
import '../../features/community/community_service.dart';
import '../../services/user_service.dart';
import 'edit_profile_screen.dart';
import '../community/create_post_screen.dart';
import 'single_post_screen.dart';
import '../community/comments_screen.dart';
import '../../core/services/language_service.dart';
import '../../core/services/app_localizations.dart';
import 'feedback_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final CommunityService _communityService = CommunityService();
  final UserService _userService = UserService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      UserModel? user = await _authService.getUserData(currentUser.uid);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfileScreen(user: _user!)),
    );

    if (result == true) {
      _fetchUserData();
    }
  }

  Future<void> _pickImageAndNavigate(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePostScreen(imageFile: pickedFile),
        ),
      );
    }
  }

  void _showLanguageSelector() {
    final languageService = LanguageServiceProvider.of(context);
    final loc = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.language, color: Colors.green, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        loc.selectLanguage,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ...AppLanguage.values.map((lang) {
                  final isSelected = languageService.currentLanguage == lang;
                  return ListTile(
                    leading: Text(
                      lang.flag,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: Text(
                      lang.displayName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.green : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      languageService.setLanguage(lang);
                      Navigator.pop(sheetContext);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final languageService = LanguageServiceProvider.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text(loc.userNotFound)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _communityService.getPostsStream(),
      builder: (context, snapshot) {
        int myPostsCount = 0;
        List<DocumentSnapshot> myPosts = [];

        if (snapshot.hasData) {
          myPosts = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['publisherId'] == _user!.uid;
          }).toList();
          myPostsCount = myPosts.length;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              _user!.username,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.feedback_outlined, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FeedbackScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView(
            children: [
              // Cover Photo & Avatar Header
              SizedBox(
                height: 250,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover photo placeholder
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        image: const DecorationImage(
                          image: NetworkImage(
                            "https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?q=80&w=2070&auto=format&fit=crop",
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      width: double.infinity,
                    ),
                    // Avatar
                    Positioned(
                      top: 100,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.green.shade100,
                          backgroundImage: _user!.profilePicUrl.isNotEmpty
                              ? NetworkImage(_user!.profilePicUrl)
                              : null,
                          child: _user!.profilePicUrl.isEmpty
                              ? Text(
                                  _user!.fullName.isNotEmpty
                                      ? _user!.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Name and Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      _user!.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loc.friendsAndPosts(_user!.friends.length, myPostsCount),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_user!.bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _user!.bio,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickImageAndNavigate(context),
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          loc.createAPost,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToEditProfile,
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.black87,
                          size: 20,
                        ),
                        label: Text(
                          loc.editProfile,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(thickness: 8, color: Colors.grey.shade300),

              // ─── Language Setting ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.language,
                    color: Colors.green,
                    size: 28,
                  ),
                  title: Text(
                    loc.languageSetting,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    languageService.currentLanguage.displayName,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        languageService.currentLanguage.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: _showLanguageSelector,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: Colors.grey.shade50,
                ),
              ),
              Divider(thickness: 8, color: Colors.grey.shade300),

              // Personal Details Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.personalDetails,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        Icon(Icons.edit, color: Colors.grey.shade700, size: 20),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      "${_user!.town}, ${_user!.state}",
                    ),
                    _buildDetailRow(Icons.home_outlined, "${_user!.country}"),
                    _buildDetailRow(
                      Icons.cake_outlined,
                      "${_user!.age} ${loc.yearsOld}",
                    ),
                    _buildDetailRow(
                      _user!.gender == 'Male'
                          ? Icons.male
                          : _user!.gender == 'Female'
                          ? Icons.female
                          : Icons.transgender,
                      _user!.gender,
                    ),
                  ],
                ),
              ),
              Divider(thickness: 8, color: Colors.grey.shade300),

              // Friends Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      loc.friends,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        loc.seeAll,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              StreamBuilder<List<UserModel>>(
                stream: _userService.streamFriends(),
                builder: (context, friendsSnapshot) {
                  if (!friendsSnapshot.hasData ||
                      friendsSnapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        loc.noFriendsYet,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final friends = friendsSnapshot.data!;
                  return Container(
                    height: 140,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  height: 100,
                                  width: 100,
                                  color: Colors.grey.shade300,
                                  child: friend.profilePicUrl.isNotEmpty
                                      ? Image.network(
                                          friend.profilePicUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(
                                            friend.fullName[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 40,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                friend.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Divider(thickness: 8, color: Colors.grey.shade300),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Text(
                  loc.posts,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ),

              // Posts List
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (myPosts.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(loc.noPostsFound),
                  ),
                )
              else
                ...myPosts.map((doc) => _buildRealCommunityPost(doc)).toList(),

              // Logout Button at Bottom
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(loc.logout),
                          content: Text(loc.logoutConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(loc.cancel),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(context); // Close dialog
                                await _authService.signOut();

                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const WelcomeScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              },
                              child: Text(
                                loc.logOut,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text(
                    loc.logOut,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Similar to HomeScreen implementation, but with Facebook styling
  Widget _buildRealCommunityPost(DocumentSnapshot postDoc) {
    final loc = AppLocalizations.of(context);
    final data = postDoc.data() as Map<String, dynamic>;
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
    final isLiked = currentUserId != null && likedBy.contains(currentUserId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SinglePostScreen(postDoc: postDoc),
          ),
        );
      },
      child: Container(
        color: Colors.white,
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
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                          ),
                          Row(
                            children: [
                              Text(
                                loc.justNow,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.public,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isMyPost)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _confirmDeletePost(context, postDoc.id);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            loc.deletePost,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_horiz,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                    )
                  else
                    Icon(
                      Icons.more_horiz,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                ],
              ),
            ),

            // Post Caption
            if (caption.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  caption,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Post Image
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.error_outline)),
                ),
              ),

            // Engagement Summary Row
            if (likesCount > 0 || commentsCount > 0)
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 12.0,
                  bottom: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (likesCount > 0)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.thumb_up,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            likesCount.toString(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(),

                    if (commentsCount > 0)
                      Text(
                        '$commentsCount ${loc.comments}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      )
                    else
                      const SizedBox(),
                  ],
                ),
              ),

            // Divider before action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade300,
              ),
            ),

            // Engagement Actions
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEngagementButton(
                    icon: isLiked
                        ? Icons.thumb_up
                        : Icons.thumb_up_alt_outlined,
                    label: loc.like,
                    iconColor: isLiked ? Colors.blue : Colors.grey.shade700,
                    onTap: () {
                      if (currentUserId != null) {
                        _communityService.toggleLike(
                          postDoc.id,
                          currentUserId,
                          likedBy,
                        );
                      }
                    },
                  ),
                  _buildEngagementButton(
                    icon: Icons.chat_bubble_outline,
                    label: loc.comment,
                    onTap: () {
                      showCommentsBottomSheet(context, postDoc.id);
                    },
                  ),
                  _buildEngagementButton(
                    icon: Icons.share_outlined,
                    label: loc.send,
                  ),
                ],
              ),
            ),
            Divider(
              thickness: 8,
              color: Colors.grey.shade300,
            ), // Thick divider between posts
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String label,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade700),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: iconColor ?? Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeletePost(BuildContext context, String postId) {
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deletePost),
        content: Text(loc.deletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _communityService.deletePost(postId); // Delete the post
            },
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
