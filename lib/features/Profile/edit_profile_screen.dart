import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/models/user_model.dart';
import '../auth/auth_service.dart';
import '../community/community_service.dart'; // Reusing image upload
import '../../core/services/app_localizations.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final CommunityService _communityService = CommunityService();

  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TextEditingController _townController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;

  String _selectedRole = "Farmer";
  XFile? _newProfileImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _bioController = TextEditingController(text: widget.user.bio);
    _ageController = TextEditingController(text: widget.user.age.toString());
    _townController = TextEditingController(text: widget.user.town);
    _stateController = TextEditingController(text: widget.user.state);
    _countryController = TextEditingController(text: widget.user.country);

    _selectedRole =
        widget.user.role.isNotEmpty &&
            [
              "Farmer",
              "Home Grower",
              "Agronomist",
              "Business Company",
            ].contains(widget.user.role)
        ? widget.user.role
        : "Farmer";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _townController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _newProfileImage = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    final loc = AppLocalizations.of(context);

    setState(() {
      _isSaving = true;
    });

    try {
      String finalProfilePicUrl = widget.user.profilePicUrl;

      // Upload new image if chosen
      if (_newProfileImage != null) {
        final uploadedUrl = await _communityService.uploadImage(
          _newProfileImage!,
        );
        if (uploadedUrl != null) {
          finalProfilePicUrl = uploadedUrl;
        }
      }

      // Create updated user model
      UserModel updatedUser = UserModel(
        uid: widget.user.uid,
        email: widget.user.email,
        username: widget.user.username,
        fullName: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? widget.user.age,
        gender: widget.user.gender,
        town: _townController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        role: _selectedRole,
        createdAt: widget.user.createdAt,
        bio: _bioController.text.trim(),
        profilePicUrl: finalProfilePicUrl,
      );

      // Save to Firebase
      await _authService.updateUserProfile(updatedUser);

      if (mounted) {
        Navigator.pop(context, true); // true indicates a refresh is needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorSavingProfile}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Colors matching the dark UI reference
    const bgColor = Color(0xFF121212); // Very dark gray/black
    const cardColor = Color(0xFF262626); // Slightly lighter gray for cards
    const textColor = Colors.white;
    const subTextColor = Colors.grey;
    const buttonBlue = Color(0xFF5C6BC0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: Text(
          loc.editProfileTitle,
          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 20.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                loc.save,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: _newProfileImage != null
                        ? (kIsWeb
                                  ? NetworkImage(_newProfileImage!.path)
                                  : FileImage(File(_newProfileImage!.path)))
                              as ImageProvider
                        : (widget.user.profilePicUrl.isNotEmpty
                              ? NetworkImage(widget.user.profilePicUrl)
                              : null),
                    child:
                        _newProfileImage == null &&
                            widget.user.profilePicUrl.isEmpty
                        ? Text(
                            widget.user.fullName.isNotEmpty
                                ? widget.user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.username,
                          style: const TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.user.fullName,
                          style: const TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      loc.changePhoto,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            _buildSectionLabel(loc.name),
            _buildTextFieldCard(
              controller: _nameController,
              hint: loc.name,
              cardColor: cardColor,
            ),
            const SizedBox(height: 20),

            // Bio Field
            _buildSectionLabel(loc.bio),
            _buildTextFieldCard(
              controller: _bioController,
              hint: loc.bio,
              cardColor: cardColor,
              maxLines: 3,
              maxLength: 150,
            ),
            const SizedBox(height: 20),

            // Age Field
            _buildSectionLabel(loc.age),
            _buildTextFieldCard(
              controller: _ageController,
              hint: loc.age,
              cardColor: cardColor,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),

            // Town Field
            _buildSectionLabel(loc.town),
            _buildTextFieldCard(
              controller: _townController,
              hint: loc.town,
              cardColor: cardColor,
            ),
            const SizedBox(height: 20),

            // State Field
            _buildSectionLabel(loc.state),
            _buildTextFieldCard(
              controller: _stateController,
              hint: loc.state,
              cardColor: cardColor,
            ),
            const SizedBox(height: 20),

            // Country Field
            _buildSectionLabel(loc.country),
            _buildTextFieldCard(
              controller: _countryController,
              hint: loc.country,
              cardColor: cardColor,
            ),
            const SizedBox(height: 20),

            // Role Field
            _buildSectionLabel(loc.role),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  isExpanded: true,
                  dropdownColor: cardColor,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: subTextColor,
                  ),
                  style: const TextStyle(color: textColor, fontSize: 16),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRole = val;
                      });
                    }
                  },
                  items:
                      [
                            "Farmer",
                            "Home Grower",
                            "Agronomist",
                            "Business Company",
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextFieldCard({
    required TextEditingController controller,
    required String hint,
    required Color cardColor,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          counterStyle: const TextStyle(
            color: Colors.grey,
          ), // For max length text color
        ),
      ),
    );
  }
}
