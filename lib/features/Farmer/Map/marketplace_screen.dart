import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/app_localizations.dart';

import 'package:kita_agro/data/plant_data.dart';
import 'package:kita_agro/models/product_listing.dart';
import 'package:kita_agro/widgets/dynamic_contact_button.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference<Map<String, dynamic>> _productsCollection =
      FirebaseFirestore.instance.collection('products');

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  bool _matchesSearch(ProductListing product) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final cropName = product.cropName.toLowerCase();
    final address = product.address.toLowerCase();
    return cropName.contains(_searchQuery) || address.contains(_searchQuery);
  }

  Widget _buildProductCard(ProductListing product) {
    final dateLabel = DateFormat.yMMMd().format(product.harvestDate);
    final placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.landscape, size: 40, color: Colors.grey),
    );

    Widget image;
    if (product.imageUrl.isEmpty) {
      image = placeholder;
    } else if (product.imageUrl.startsWith('http')) {
      image = Image.network(
        product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (product.imageUrl.startsWith('data:image')) {
      try {
        final bytes = UriData.parse(product.imageUrl).contentAsBytes();
        image = Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        image = placeholder;
      }
    } else {
      image = placeholder;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 180, width: double.infinity, child: image),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(product.colorValue),
                      child: Icon(
                        PlantData.getIconForCrop(product.cropName),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        product.cropName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  ).weightKg(product.weight.toStringAsFixed(2)),
                ),
                Text(AppLocalizations.of(context).harvestDateLabel(dateLabel)),
                Text(
                  AppLocalizations.of(
                    context,
                  ).contactLabel(product.contactNumber),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DynamicContactButton(ownerId: product.userId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).marketplace),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchByCropOrLocation,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _productsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final filteredProducts = docs
              .map(ProductListing.fromFirestore)
              .where(_matchesSearch)
              .toList();

          if (filteredProducts.isEmpty) {
            return Center(
              child: Text(
                _searchQuery.isEmpty
                    ? AppLocalizations.of(context).noProductsYet
                    : AppLocalizations.of(context).noResultsFor(_searchQuery),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(product);
            },
          );
        },
      ),
    );
  }
}
