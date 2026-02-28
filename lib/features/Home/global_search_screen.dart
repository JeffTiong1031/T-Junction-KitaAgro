import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';
import '../Profile/single_post_screen.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim().toLowerCase();
      _isSearching = _searchQuery.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

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
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: loc.searchHint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 20, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : Icon(Icons.search, size: 20, color: Colors.grey[600]),
            ),
          ),
        ),
      ),
      body: !_isSearching
          ? _buildInitialState(loc)
          : _buildSearchResults(loc),
    );
  }

  Widget _buildInitialState(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            loc.searchHint, // Or a dedicated "Type to search community" string
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations loc) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(loc.noPostsYet));
        }

        // Filter results locally since Firestore startsWith/contains is limited 
        // and user wants to search community (posts).
        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final caption = (data['caption'] ?? '').toString().toLowerCase();
          final publisher = (data['publisherName'] ?? '').toString().toLowerCase();
          
          return caption.contains(_searchQuery) || publisher.contains(_searchQuery);
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text(
              'No results found for "$_searchQuery"',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          padding: const EdgeInsets.symmetric(vertical: 12),
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = results[index];
            final data = doc.data() as Map<String, dynamic>;
            final imageUrl = data['imageUrl'] as String?;
            final publisherName = data['publisherName'] ?? 'Unknown';
            final caption = data['caption'] ?? '';

            return ListTile(
              leading: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image_outlined, color: Colors.grey),
                    ),
              title: Text(
                publisherName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SinglePostScreen(postDoc: doc),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
