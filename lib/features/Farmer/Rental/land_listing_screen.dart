import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'land_model.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

class LandListingScreen extends StatefulWidget {
  const LandListingScreen({super.key});

  @override
  State<LandListingScreen> createState() => _LandListingScreenState();
}

class _LandListingScreenState extends State<LandListingScreen> {
  static const String _allStatesLabel = 'All States';
  static const String _anyPriceLabel = 'Any Price';
  static const String _allSizeLabel = 'All';
  static const List<String> _priceOptions = [
    _anyPriceLabel,
    'Budget (< RM 1,000)',
    'Standard (RM 1,000 - 3,000)',
    'Premium (> RM 3,000)',
  ];
  static const List<String> _sizeOptions = [
    _allSizeLabel,
    'Small (< 1 Acre)',
    'Medium (1-5 Acres)',
    'Large (> 5 Acres)',
  ];

  /// Stream of land listings.
  ///
  /// Security note:
  /// This direct Firestore access assumes that Firestore security rules
  /// are configured to protect the `lands` collection. At minimum, rules
  /// should:
  /// - Allow read access to `lands` only for the intended audience
  ///   (e.g. `allow read: if request.auth != null;` or a suitably
  ///   constrained public-read rule).
  /// - Restrict write/update/delete operations to authorized users or
  ///   server-side processes (e.g. using role/claim checks).
  /// - Validate the structure and types of `lands` documents on writes
  ///   (e.g. required fields, correct data types, and value ranges).
  ///
  /// Ensure the Firestore rules file (e.g. `firestore.rules`) enforces
  /// these constraints to prevent unauthorized access or data exposure.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _landsStream;

  @override
  void initState() {
    super.initState();
    // Enable Firestore local persistence so previously loaded listings
    // remain available when the device is offline.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
    // Use metadata-aware snapshots so cached data is surfaced even
    // when offline or before the server is reached.
    _landsStream = FirebaseFirestore.instance
        .collection('lands')
        .snapshots(includeMetadataChanges: true);
  }

  String _searchText = '';
  String _selectedState = _allStatesLabel;
  String _selectedPrice = _anyPriceLabel;
  String _selectedSize = _allSizeLabel;

  /// Handle search text changes
  void _onSearchChanged(String value) {
    setState(() {
      _searchText = value;
    });
  }

  /// Handle state/location filter changes
  void _onStateChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedState = value;
      });
    }
  }

  /// Handle price range filter changes
  void _onPriceChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedPrice = value;
      });
    }
  }

  /// Handle size filter changes
  void _onSizeSelected(String size) {
    setState(() {
      _selectedSize = size;
    });
  }

  /// Show contact dialog with owner phone
  void _showContactDialog(String ownerPhone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).contactOwner),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).contactOwnerInfo,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).ownerPhoneNumber),
            const SizedBox(height: 12),
            Text(
              ownerPhone,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).farmLandRentalTitle),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _landsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load land listings right now.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs =
              snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          final lands = docs.map(Land.fromFirestore).toList();
          final stateOptions = _buildStateOptions(lands);
          final filteredLands = _filterLands(lands);

          final currentStateValue = stateOptions.contains(_selectedState)
              ? _selectedState
              : _allStatesLabel;

          if (currentStateValue != _selectedState) {
            // Update the selected state directly during this build instead of
            // scheduling a post-frame setState, to avoid unnecessary rebuilds.
            _selectedState = currentStateValue;
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    ).searchByTitleOrLocation,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: currentStateValue,
                            isExpanded: true,
                            onChanged: _onStateChanged,
                            items: stateOptions
                                .map(
                                  (state) => DropdownMenuItem(
                                    value: state,
                                    child: Text(
                                      state == _allStatesLabel
                                          ? AppLocalizations.of(
                                              context,
                                            ).allStates
                                          : state,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedPrice,
                            isExpanded: true,
                            onChanged: _onPriceChanged,
                            selectedItemBuilder: (context) {
                              return _priceOptions
                                  .map(
                                    (price) => Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _shortPriceLabel(price),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList();
                            },
                            items: _priceOptions
                                .map(
                                  (price) => DropdownMenuItem(
                                    value: price,
                                    child: Text(
                                      _getLocalizedPriceLabel(price),
                                      softWrap: true,
                                      maxLines: 2,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _sizeOptions
                            .map(
                              (size) => Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(_getLocalizedSizeLabel(size)),
                                  selected: _selectedSize == size,
                                  onSelected: (_) => _onSizeSelected(size),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filteredLands.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).noLandsFound,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLands.length,
                        itemBuilder: (ctx, index) {
                          final land = filteredLands[index];
                          return _buildLandCard(land);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Land> _filterLands(List<Land> lands) {
    return lands.where((land) {
      final searchable = '${land.title} ${land.location}'.toLowerCase();
      final searchMatch =
          _searchText.isEmpty || searchable.contains(_searchText.toLowerCase());

      final stateMatch =
          _selectedState == _allStatesLabel || land.state == _selectedState;

      bool priceMatch;
      switch (_selectedPrice) {
        case 'Budget (< RM 1,000)':
          priceMatch = land.price < 1000;
          break;
        case 'Standard (RM 1,000 - 3,000)':
          priceMatch = land.price >= 1000 && land.price <= 3000;
          break;
        case 'Premium (> RM 3,000)':
          priceMatch = land.price > 3000;
          break;
        default:
          priceMatch = true;
      }

      bool sizeMatch;
      switch (_selectedSize) {
        case 'Small (< 1 Acre)':
          sizeMatch = land.sizeValue < 1;
          break;
        case 'Medium (1-5 Acres)':
          sizeMatch = land.sizeValue >= 1 && land.sizeValue <= 5;
          break;
        case 'Large (> 5 Acres)':
          sizeMatch = land.sizeValue > 5;
          break;
        default:
          sizeMatch = true;
      }

      return searchMatch && stateMatch && priceMatch && sizeMatch;
    }).toList();
  }

  List<String> _buildStateOptions(List<Land> lands) {
    final stateSet = <String>{};
    for (final land in lands) {
      if (land.state.isNotEmpty) {
        stateSet.add(land.state);
      }
    }
    final sortedStates = stateSet.toList()..sort();
    return [_allStatesLabel, ...sortedStates];
  }

  String _shortPriceLabel(String price) {
    final loc = AppLocalizations.of(context);
    switch (price) {
      case 'Budget (< RM 1,000)':
        return loc.budgetPriceShort;
      case 'Standard (RM 1,000 - 3,000)':
        return loc.standardPriceShort;
      case 'Premium (> RM 3,000)':
        return loc.premiumPriceShort;
      case _anyPriceLabel:
        return loc.anyPrice;
      default:
        return price;
    }
  }

  String _getLocalizedPriceLabel(String price) {
    final loc = AppLocalizations.of(context);
    switch (price) {
      case 'Budget (< RM 1,000)':
        return loc.budgetPrice;
      case 'Standard (RM 1,000 - 3,000)':
        return loc.standardPrice;
      case 'Premium (> RM 3,000)':
        return loc.premiumPrice;
      case _anyPriceLabel:
        return loc.anyPrice;
      default:
        return price;
    }
  }

  String _getLocalizedSizeLabel(String size) {
    final loc = AppLocalizations.of(context);
    switch (size) {
      case 'Small (< 1 Acre)':
        return loc.smallSize;
      case 'Medium (1-5 Acres)':
        return loc.mediumSize;
      case 'Large (> 5 Acres)':
        return loc.largeSize;
      case _allSizeLabel:
        return loc.allSize;
      default:
        return size;
    }
  }

  String _formatPrice(double price) {
    final rounded = price.toStringAsFixed(0);
    return rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  /// Build individual land card
  Widget _buildLandCard(Land land) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Section: Image with "For Rent" Badge
          Stack(
            children: [
              // Land Image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  land.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              // "For Rent" Badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppLocalizations.of(context).forRent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Middle Section: Information
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Price & Size Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price
                    Text(
                      'RM ${_formatPrice(land.price)} /mo',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    // Size Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        land.sizeDisplay,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 2: Title
                Text(
                  land.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Row 3: Location
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 18,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${land.location}, ${land.state}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Section: Contact Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => _showContactDialog(land.ownerPhone),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).contactOwner,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
