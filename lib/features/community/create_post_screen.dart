import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/services/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kita_agro/features/community/community_service.dart';
import 'package:kita_agro/features/auth/auth_service.dart';

class CreatePostScreen extends StatefulWidget {
  final XFile imageFile;

  const CreatePostScreen({super.key, required this.imageFile});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final CommunityService _communityService = CommunityService();
  bool _isLoading = false;

  final Color _accentColor = const Color(0xFF4CAF50); // Agro Green

  Future<void> _createPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception("You must be logged in to post");
      }

      final userData = await authService.getUserData(currentUser.uid);
      final String currentUid = currentUser.uid;
      final String username = userData?.username ?? "New User";
      final String userProfilePic = username.isNotEmpty
          ? username[0].toUpperCase()
          : "?";

      await _communityService.createPost(
        uid: currentUid,
        username: username,
        userProfilePic: userProfilePic,
        caption: _captionController.text.trim(),
        imageFile: widget.imageFile,
      );

      if (mounted) {
        Navigator.pop(context); // Go back after successful posting
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).errorCreatingPost}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).newPostTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          _isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _createPost,
                  child: Text(
                    AppLocalizations.of(context).sharePost,
                    style: TextStyle(
                      color: Colors
                          .blueAccent[400], // Instagram uses a distinct blue for 'Share'
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section: Image + Caption Input
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                            widget.imageFile.path,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(widget.imageFile.path),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: TextField(
                        controller: _captionController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: AppLocalizations.of(context).writeACaption,
                          hintStyle: const TextStyle(color: Colors.black45),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),

            // Tag people
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.person_add_alt_1_outlined,
                color: Colors.black87,
              ),
              title: Text(
                AppLocalizations.of(context).tagPeople,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.person_add, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${AppLocalizations.of(context).tagPeople} feature coming soon!',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 0.5),

            // Add location
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.location_on_outlined,
                color: Colors.black87,
              ),
              title: Text(
                AppLocalizations.of(context).addLocation,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${AppLocalizations.of(context).addLocation} feature coming soon!',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 0.5),

            // Add music / audio
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.music_note_outlined,
                color: Colors.black87,
              ),
              title: Text(
                AppLocalizations.of(context).addAudio,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.audiotrack, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '${AppLocalizations.of(context).addAudio} feature coming soon!',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, thickness: 0.5),
          ],
        ),
      ),
    );
  }
}
