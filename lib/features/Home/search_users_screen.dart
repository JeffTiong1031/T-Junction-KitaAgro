import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';
import '../../core/models/user_model.dart';
import '../../services/user_service.dart';
import '../Profile/other_user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    final results = await _userService.searchUsers(query.toLowerCase());

    // Remove current user from results
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    results.removeWhere((u) => u.uid == currentUserId);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: _performSearch,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).searchPeople,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                  _performSearch('');
                },
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
          ? Center(
              child: Text(
                _searchController.text.isEmpty
                    ? AppLocalizations.of(context).typeToSearch
                    : AppLocalizations.of(context).noUsersFound,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    backgroundImage: user.profilePicUrl.isNotEmpty
                        ? NetworkImage(user.profilePicUrl)
                        : null,
                    child: user.profilePicUrl.isEmpty
                        ? Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.fullName),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OtherUserProfileScreen(user: user),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
