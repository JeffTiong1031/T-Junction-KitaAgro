import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kita_agro/features/community/create_post_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expert Community')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPost("Leaf turning yellow?", "Asked by Ahmad • 2 mins ago"),
          _buildPost(
            "Best fertilizer for Chilies?",
            "Asked by Sarah • 1 hour ago",
          ),
          _buildPost(
            "Spider Mites spotted in KL!",
            "Asked by Tan • 3 hours ago",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickImageAndNavigate(context),
        backgroundColor: const Color(0xFF4CAF50), // Agro Green
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPost(String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
