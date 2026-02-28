import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/services/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:kita_agro/data/plant_data.dart';
import 'package:kita_agro/models/company.dart';
import 'package:kita_agro/models/farmer_profile.dart';
import 'package:kita_agro/models/product_listing.dart';

enum MapMode { business, product }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final CollectionReference<Map<String, dynamic>> _farmersCollection =
      FirebaseFirestore.instance.collection('farmers');
  final CollectionReference<Map<String, dynamic>> _companiesCollection =
      FirebaseFirestore.instance.collection('companies');
  final CollectionReference<Map<String, dynamic>> _productsCollection =
      FirebaseFirestore.instance.collection('products');

  MapMode _mode = MapMode.business;
  // Default focus on Malaysia so users see regional data immediately.
  LatLng _currentCenter = const LatLng(3.1390, 101.6869);
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _searching = true;
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'KitaAgroApp/1.0'},
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List<dynamic>;
        if (results.isNotEmpty) {
          final first = results.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat'] as String? ?? '');
          final lon = double.tryParse(first['lon'] as String? ?? '');
          if (lat != null && lon != null) {
            final target = LatLng(lat, lon);
            _mapController.move(target, _mapController.camera.zoom);
            setState(() {
              _currentCenter = target;
            });
          }
        } else {
          _showSnack('No results for "$query"');
        }
      } else {
        _showSnack('Search failed (${response.statusCode})');
      }
    } catch (error) {
      _showSnack('Search error: $error');
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  Future<Position?> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Enable location services');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      _showSnack('Location permission denied');
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _goToCurrentLocation() async {
    final position = await _getCurrentPosition();
    if (position == null) return;
    final target = LatLng(position.latitude, position.longitude);
    _mapController.move(target, 15);
    setState(() {
      _currentCenter = target;
    });
  }

  Future<LatLng?> _forwardGeocode(String query) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1',
    );
    try {
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'KitaAgroApp/1.0'},
      );
      if (response.statusCode != 200) {
        return null;
      }
      final results = jsonDecode(response.body) as List<dynamic>;
      if (results.isEmpty) {
        return null;
      }
      final first = results.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat'] as String? ?? '');
      final lon = double.tryParse(first['lon'] as String? ?? '');
      if (lat == null || lon == null) {
        return null;
      }
      return LatLng(lat, lon);
    } catch (_) {
      return null;
    }
  }

  Future<void> _showFarmerDetails(FarmerProfile farmer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = userId != null && userId == farmer.ownerId;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmer.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(farmer.description),
                const SizedBox(height: 8),
                Text('${AppLocalizations.of(context).phone}: ${farmer.phone}'),
                Text(
                  '${AppLocalizations.of(context).address}: ${farmer.address}',
                ),
                if (isOwner) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _onEditFarmerProfile(farmer);
                          },
                          icon: const Icon(Icons.edit),
                          label: Text(AppLocalizations.of(context).edit),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteFarmerProfile(farmer);
                          },
                          icon: const Icon(Icons.delete),
                          label: Text(AppLocalizations.of(context).delete),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCompanyDetails(Company company) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Type: ${company.type}'),
                const SizedBox(height: 8),
                Text('${AppLocalizations.of(context).phone}: ${company.phone}'),
                Text(
                  '${AppLocalizations.of(context).address}: ${company.address}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showProductDetails(ProductListing product) async {
    final dateLabel = DateFormat.yMMMd().format(product.harvestDate);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(
                    context,
                  ).weightKg(product.weight.toStringAsFixed(2)),
                ),
                Text('${AppLocalizations.of(context).harvested}: $dateLabel'),
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context).contactLabel(product.contactNumber)}',
                ),
                Text(
                  '${AppLocalizations.of(context).address}: ${product.address}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusinessMarkers() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _farmersCollection.snapshots(),
      builder: (context, farmerSnapshot) {
        if (farmerSnapshot.hasError) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _companiesCollection.snapshots(),
          builder: (context, companySnapshot) {
            if (farmerSnapshot.connectionState == ConnectionState.waiting ||
                companySnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final farmerDocs = farmerSnapshot.data?.docs ?? [];
            final companyDocs = companySnapshot.data?.docs ?? [];

            final markers = <Marker>[];

            for (final doc in farmerDocs) {
              final data = doc.data();
              final lat = (data['latitude'] as num?)?.toDouble();
              final lon = (data['longitude'] as num?)?.toDouble();
              if (lat == null || lon == null) {
                continue;
              }
              markers.add(
                Marker(
                  point: LatLng(lat, lon),
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () =>
                        _showFarmerDetails(FarmerProfile.fromFirestore(doc)),
                    child: const _MarkerIcon(
                      color: Colors.green,
                      icon: Icons.agriculture,
                    ),
                  ),
                ),
              );
            }

            for (final doc in companyDocs) {
              final data = doc.data();
              final lat = (data['latitude'] as num?)?.toDouble();
              final lon = (data['longitude'] as num?)?.toDouble();
              if (lat == null || lon == null) {
                continue;
              }
              markers.add(
                Marker(
                  point: LatLng(lat, lon),
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () =>
                        _showCompanyDetails(Company.fromFirestore(doc)),
                    child: const _MarkerIcon(
                      color: Colors.red,
                      icon: Icons.business,
                    ),
                  ),
                ),
              );
            }

            return MarkerLayer(markers: markers);
          },
        );
      },
    );
  }

  Widget _buildProductMarkers() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _productsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        final markers = docs
            .map(ProductListing.fromFirestore)
            .map(
              (product) => Marker(
                point: LatLng(product.latitude, product.longitude),
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => _showProductDetails(product),
                  child: _ProductMarkerIcon(
                    color: Color(product.colorValue),
                    iconData: PlantData.getIconForCrop(product.cropName),
                  ),
                ),
              ),
            )
            .toList();

        return MarkerLayer(markers: markers);
      },
    );
  }

  Future<void> _deleteFarmerProfile(FarmerProfile farmer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId != farmer.ownerId) {
      _showSnack('You can only delete your own profile.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).removeProfileTitle),
          content: Text(AppLocalizations.of(context).removeProfileContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context).delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _farmersCollection.doc(farmer.id).delete();
      _showSnack(AppLocalizations.of(context).profileRemoved);
    } catch (error) {
      _showSnack('Failed to delete profile: $error');
    }
  }

  Future<void> _onEditFarmerProfile(FarmerProfile farmer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId != farmer.ownerId) {
      _showSnack('You can only edit your own profile.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: farmer.name);
    final phoneController = TextEditingController(text: farmer.phone);
    final descriptionController = TextEditingController(
      text: farmer.description,
    );
    final addressController = TextEditingController(text: farmer.address);
    bool saving = false;
    bool fetchingLocation = false;
    String? resolvedAddress = farmer.address;
    double? latitude = farmer.latitude;
    double? longitude = farmer.longitude;

    Future<String?> reverseGeocode(double lat, double lon) async {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon',
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'KitaAgroApp/1.0'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['display_name'] as String?;
      }
      return null;
    }

    Future<void> populateWithCurrentLocation(StateSetter setDialogState) async {
      try {
        final position = await _getCurrentPosition();
        if (position == null) {
          setDialogState(() => fetchingLocation = false);
          return;
        }
        final fetchedAddress = await reverseGeocode(
          position.latitude,
          position.longitude,
        );
        setDialogState(() {
          resolvedAddress = fetchedAddress;
          latitude = position.latitude;
          longitude = position.longitude;
          addressController.text =
              fetchedAddress ??
              'Lat: ${position.latitude.toStringAsFixed(5)}, '
                  'Lng: ${position.longitude.toStringAsFixed(5)}';
          fetchingLocation = false;
        });
      } catch (error) {
        setDialogState(() => fetchingLocation = false);
        _showSnack('Failed to fetch location: $error');
      }
    }

    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveProfile() async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              setDialogState(() => saving = true);
              try {
                final manualAddress = addressController.text.trim();
                double? latValue = latitude;
                double? lonValue = longitude;
                String? finalAddress = resolvedAddress;

                if (manualAddress.isNotEmpty) {
                  finalAddress = manualAddress;
                  if (latValue == null || lonValue == null) {
                    final geocoded = await _forwardGeocode(manualAddress);
                    if (geocoded == null) {
                      setDialogState(() => saving = false);
                      _showSnack(
                        'Unable to locate that address. Try a full address or use current location.',
                      );
                      return;
                    }
                    latValue = geocoded.latitude;
                    lonValue = geocoded.longitude;
                  }
                } else {
                  if (latValue == null || lonValue == null) {
                    setDialogState(() => saving = false);
                    _showSnack('Provide an address or use current location.');
                    return;
                  }
                }

                final double latToStore = latValue;
                final double lonToStore = lonValue;
                final addressToStore =
                    finalAddress ??
                    'Lat: ${latToStore.toStringAsFixed(5)}, '
                        'Lng: ${lonToStore.toStringAsFixed(5)}';

                await _farmersCollection.doc(farmer.id).update({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'address': addressToStore,
                  'latitude': latToStore,
                  'longitude': lonToStore,
                });
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (error) {
                _showSnack('Failed to update: $error');
              } finally {
                if (mounted) {
                  setDialogState(() => saving = false);
                }
              }
            }

            return AlertDialog(
              title: Text(AppLocalizations.of(context).updateProfile),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).nameLabel,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context).enterYourName;
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).contactNumber,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(
                            context,
                          ).enterContactNumber;
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).description,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).address,
                        hintText: AppLocalizations.of(context).streetCityState,
                      ),
                      onChanged: (_) {
                        setDialogState(() {
                          resolvedAddress = null;
                          latitude = null;
                          longitude = null;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: fetchingLocation
                            ? null
                            : () {
                                setDialogState(() => fetchingLocation = true);
                                populateWithCurrentLocation(setDialogState);
                              },
                        icon: fetchingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          AppLocalizations.of(context).useCurrentLocation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                FilledButton(
                  onPressed: saving ? null : saveProfile,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context).save),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == true) {
      _showSnack(AppLocalizations.of(context).profilePublished);
    }
  }

  Future<void> _onAddFarmerProfile() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final descriptionController = TextEditingController();
    final addressController = TextEditingController();
    bool saving = false;
    bool fetchingLocation = false;
    String? resolvedAddress;
    double? latitude;
    double? longitude;

    Future<String?> reverseGeocode(double lat, double lon) async {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon',
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'KitaAgroApp/1.0'},
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json['display_name'] as String?;
      }
      return null;
    }

    Future<void> populateWithCurrentLocation(StateSetter setDialogState) async {
      try {
        final position = await _getCurrentPosition();
        if (position == null) {
          setDialogState(() => fetchingLocation = false);
          return;
        }
        final fetchedAddress = await reverseGeocode(
          position.latitude,
          position.longitude,
        );
        setDialogState(() {
          resolvedAddress = fetchedAddress;
          latitude = position.latitude;
          longitude = position.longitude;
          addressController.text =
              fetchedAddress ??
              'Lat: ${position.latitude.toStringAsFixed(5)}, '
                  'Lng: ${position.longitude.toStringAsFixed(5)}';
          fetchingLocation = false;
        });
      } catch (error) {
        setDialogState(() => fetchingLocation = false);
        _showSnack('Failed to fetch location: $error');
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveProfile() async {
              if (!formKey.currentState!.validate()) {
                return;
              }
              setDialogState(() => saving = true);
              try {
                final manualAddress = addressController.text.trim();
                double? latValue = latitude;
                double? lonValue = longitude;
                String? finalAddress = resolvedAddress;

                if (manualAddress.isNotEmpty) {
                  finalAddress = manualAddress;
                  if (latValue == null || lonValue == null) {
                    final geocoded = await _forwardGeocode(manualAddress);
                    if (geocoded == null) {
                      setDialogState(() => saving = false);
                      _showSnack(
                        'Unable to locate that address. Try a full address or use current location.',
                      );
                      return;
                    }
                    latValue = geocoded.latitude;
                    lonValue = geocoded.longitude;
                  }
                } else {
                  if (latValue == null || lonValue == null) {
                    setDialogState(() => saving = false);
                    _showSnack('Provide an address or use current location.');
                    return;
                  }
                }

                final double latToStore = latValue;
                final double lonToStore = lonValue;
                final addressToStore =
                    finalAddress ??
                    'Lat: ${latToStore.toStringAsFixed(5)}, '
                        'Lng: ${lonToStore.toStringAsFixed(5)}';

                await _farmersCollection.add({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'address': addressToStore,
                  'latitude': latToStore,
                  'longitude': lonToStore,
                  if (FirebaseAuth.instance.currentUser != null)
                    'ownerId': FirebaseAuth.instance.currentUser!.uid,
                });
                if (mounted) {
                  Navigator.of(context).pop(true);
                }
              } catch (error) {
                _showSnack('Failed to register: $error');
              } finally {
                if (mounted) {
                  setDialogState(() => saving = false);
                }
              }
            }

            return AlertDialog(
              title: Text(AppLocalizations.of(context).makeProfilePublic),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).nameLabel,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context).enterYourName;
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).contactNumber,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(
                            context,
                          ).enterContactNumber;
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).description,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).address,
                        hintText: AppLocalizations.of(context).streetCityState,
                      ),
                      onChanged: (_) {
                        setDialogState(() {
                          resolvedAddress = null;
                          latitude = null;
                          longitude = null;
                        });
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: fetchingLocation
                            ? null
                            : () {
                                setDialogState(() => fetchingLocation = true);
                                populateWithCurrentLocation(setDialogState);
                              },
                        icon: fetchingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          AppLocalizations.of(context).useCurrentLocation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                FilledButton(
                  onPressed: saving ? null : saveProfile,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context).save),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      _showSnack(AppLocalizations.of(context).profilePublished);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final markerLayer = _mode == MapMode.business
        ? _buildBusinessMarkers()
        : _buildProductMarkers();

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 12,
                onPositionChanged: (position, hasGesture) {
                  if (position.center != null) {
                    _currentCenter = position.center!;
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.kita.agro',
                ),
                markerLayer,
              ],
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Material(
                        elevation: 4,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        color: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.of(context).maybePop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(32),
                          clipBehavior: Clip.antiAlias,
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _searchLocation,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              ).searchByCropOrLocation,
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(20),
                    isSelected: [
                      _mode == MapMode.business,
                      _mode == MapMode.product,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _mode = MapMode.values[index];
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(AppLocalizations.of(context).business),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(AppLocalizations.of(context).product),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'currentLocationBtn',
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'addFarmerBtn',
              onPressed: _onAddFarmerProfile,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerIcon extends StatelessWidget {
  const _MarkerIcon({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _ProductMarkerIcon extends StatelessWidget {
  const _ProductMarkerIcon({required this.color, required this.iconData});

  final Color color;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.9),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(iconData, color: Colors.white, size: 24),
    );
  }
}
