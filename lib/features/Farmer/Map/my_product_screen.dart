import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/app_localizations.dart';

import 'package:kita_agro/data/plant_data.dart';
import 'package:kita_agro/models/product_listing.dart';

class MyProductScreen extends StatefulWidget {
  const MyProductScreen({super.key});

  @override
  State<MyProductScreen> createState() => _MyProductScreenState();
}

class _MyProductScreenState extends State<MyProductScreen> {
  final CollectionReference<Map<String, dynamic>> _productsCollection =
      FirebaseFirestore.instance.collection('products');

  static const String _placeholderImageUrl =
      'https://placehold.co/600x400?text=Crop';

  Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream(String userId) {
    return _productsCollection.where('userId', isEqualTo: userId).snapshots();
  }

  Future<void> _openProductForm({
    DocumentSnapshot<Map<String, dynamic>>? snapshot,
    ProductListing? initialProduct,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _ProductFormSheet(
            productsCollection: _productsCollection,
            placeholderImageUrl: _placeholderImageUrl,
            initialSnapshot: snapshot,
            initialProduct: initialProduct,
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext).deleteProductTitle),
          content: Text(
            AppLocalizations.of(dialogContext).actionCannotBeUndone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppLocalizations.of(dialogContext).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppLocalizations.of(dialogContext).delete),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await snapshot.reference.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).productDeleted)),
        );
      }
    }
  }

  Widget _buildProductImage(ProductListing product) {
    final imageUrl = product.imageUrl;
    Widget placeholder = Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image, size: 32, color: Colors.grey),
    );

    if (imageUrl.isEmpty) {
      return placeholder;
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final uriData = UriData.parse(imageUrl);
        final bytes = uriData.contentAsBytes();
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return placeholder;
      }
    }

    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    return placeholder;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).myProducts)),
        body: Center(
          child: Text(AppLocalizations.of(context).pleaseLoginProducts),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).myProducts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).addProduct),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _productsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }

          final docs =
              List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                snapshot.data?.docs ?? const [],
              )..sort((first, second) {
                final firstHarvest =
                    (first.data()['harvestDate'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final secondHarvest =
                    (second.data()['harvestDate'] as Timestamp?)?.toDate() ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return secondHarvest.compareTo(firstHarvest);
              });

          if (docs.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context).noProductsAddOne),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final product = ProductListing.fromFirestore(doc);
              final dateLabel = DateFormat.yMMMd().format(product.harvestDate);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: _buildProductImage(product),
                    ),
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
                          Text(
                            '${AppLocalizations.of(context).harvested}: $dateLabel',
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).contactLabel(product.contactNumber),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.address,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () => _openProductForm(
                                  snapshot: doc,
                                  initialProduct: product,
                                ),
                                icon: const Icon(Icons.edit),
                                label: Text(AppLocalizations.of(context).edit),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _confirmDelete(doc),
                                icon: const Icon(Icons.delete),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                label: Text(
                                  AppLocalizations.of(context).delete,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({
    required this.productsCollection,
    required this.placeholderImageUrl,
    this.initialSnapshot,
    this.initialProduct,
  });

  final CollectionReference<Map<String, dynamic>> productsCollection;
  final String placeholderImageUrl;
  final DocumentSnapshot<Map<String, dynamic>>? initialSnapshot;
  final ProductListing? initialProduct;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  Map<String, dynamic>? _selectedPlant;
  late final TextEditingController _weightController;
  late final TextEditingController _harvestDateController;
  late final TextEditingController _contactController;
  late final TextEditingController _addressController;

  double? _weight;
  DateTime? _harvestDate;
  Uint8List? _imagePreviewBytes;
  String? _imageDataUrl;
  bool _saving = false;
  bool _fetchingLocation = false;
  double? _latitude;
  double? _longitude;
  int? _colorValue;
  int? _iconCodePoint;
  String? _address;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final product = widget.initialProduct;

    _selectedPlant = product != null
        ? PlantData.allPlants.firstWhere(
            (plant) => plant['name'] == product.cropName,
            orElse: () => PlantData.allPlants.first,
          )
        : null;

    _colorValue = product?.colorValue;
    _iconCodePoint = product?.iconCodePoint;
    _weight = product?.weight;
    _harvestDate = product?.harvestDate;
    _imageDataUrl = product?.imageUrl;
    _latitude = product?.latitude;
    _longitude = product?.longitude;
    _address = product?.address;

    if (_imageDataUrl != null && _imageDataUrl!.startsWith('data:image')) {
      try {
        final bytes = UriData.parse(_imageDataUrl!).contentAsBytes();
        _imagePreviewBytes = bytes;
      } catch (_) {
        _imagePreviewBytes = null;
      }
    }

    _weightController = TextEditingController(
      text: _weight != null ? _weight!.toString() : '',
    );
    _harvestDateController = TextEditingController(
      text: _harvestDate != null
          ? DateFormat.yMMMd().format(_harvestDate!)
          : '',
    );
    _contactController = TextEditingController(
      text: product?.contactNumber ?? '',
    );
    _addressController = TextEditingController(text: _address ?? '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _harvestDateController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (pickedFile == null) {
      return;
    }

    final bytes = await pickedFile.readAsBytes();
    final mimeType = pickedFile.mimeType ?? 'image/jpeg';
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() {
      _imagePreviewBytes = bytes;
      _imageDataUrl = dataUrl;
    });
  }

  Future<void> _selectHarvestDate() async {
    final now = DateTime.now();
    final initialDate = _harvestDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        _harvestDate = picked;
        _harvestDateController.text = DateFormat.yMMMd().format(picked);
      });
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _fetchingLocation = true;
    });

    try {
      final hasService = await Geolocator.isLocationServiceEnabled();
      if (!hasService) {
        throw Exception('Enable location services.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final displayAddress = await _reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address =
            displayAddress ??
            'Lat: ${position.latitude.toStringAsFixed(5)}, '
                'Lng: ${position.longitude.toStringAsFixed(5)}';
        _addressController.text = _address ?? '';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _fetchingLocation = false;
        });
      }
    }
  }

  Future<String?> _reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude',
    );
    final response = await http.get(
      url,
      headers: const {'User-Agent': 'KitaAgroApp/1.0'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    }
    return null;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedPlant = _selectedPlant;
    if (selectedPlant == null && widget.initialProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).selectACrop)),
      );
      return;
    }

    if (_harvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pickHarvestDate)),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).fetchLocation)),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (currentUserId.isEmpty) {
        throw StateError('Please log in to save your product.');
      }

      final colorValue =
          _colorValue ??
          (selectedPlant != null
              ? (selectedPlant['color'] as Color).value
              : null) ??
          Colors.green.value;
      final iconCodePoint =
          _iconCodePoint ??
          (selectedPlant != null
              ? (selectedPlant['icon'] as IconData).codePoint
              : Icons.spa.codePoint);

      final cropName = selectedPlant != null
          ? selectedPlant['name'] as String
          : widget.initialProduct!.cropName;

      final harvestDate = _harvestDate!;
      final contactNumber = _contactController.text.trim();
      final parsedWeight = double.tryParse(_weightController.text.trim()) ?? 0;
      final imageUrl =
          _imageDataUrl ??
          widget.initialProduct?.imageUrl ??
          widget.placeholderImageUrl;

      final product = ProductListing(
        id: widget.initialSnapshot?.id ?? '',
        userId: currentUserId,
        cropName: cropName,
        weight: parsedWeight,
        harvestDate: harvestDate,
        contactNumber: contactNumber,
        imageUrl: imageUrl,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address ?? '',
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
      );

      final payload = product.toMap();

      if (widget.initialSnapshot != null) {
        await widget.initialSnapshot!.reference.update(payload);
      } else {
        await widget.productsCollection.add(payload);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).productSaved)),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $error')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.initialProduct == null
                    ? AppLocalizations.of(context).addProduct
                    : AppLocalizations.of(context).editProduct,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<Map<String, dynamic>>(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).crop,
                  border: const OutlineInputBorder(),
                ),
                initialValue: _selectedPlant,
                items: PlantData.allPlants
                    .map(
                      (plant) => DropdownMenuItem<Map<String, dynamic>>(
                        value: plant,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: (plant['color'] as Color)
                                  .withOpacity(0.8),
                              child: Icon(
                                plant['icon'] as IconData,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(plant['name'] as String),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedPlant = value;
                    _colorValue = (value['color'] as Color).value;
                    _iconCodePoint = (value['icon'] as IconData).codePoint;
                  });
                },
                validator: (value) {
                  if (value == null && widget.initialProduct == null) {
                    return AppLocalizations.of(context).selectCrop;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: _imagePreviewBytes != null
                        ? Image.memory(_imagePreviewBytes!, fit: BoxFit.cover)
                        : (widget.initialProduct?.imageUrl.startsWith('http') ??
                              false)
                        ? Image.network(
                            widget.initialProduct!.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ImagePlaceholder(label: 'Tap to add photo'),
                          )
                        : _imageDataUrl != null
                        ? _DataUrlImageView(dataUrl: _imageDataUrl!)
                        : _ImagePlaceholder(label: 'Tap to add photo'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).weightKgLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return AppLocalizations.of(context).enterValidWeight;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _harvestDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).harvestDate,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_month),
                ),
                onTap: _selectHarvestDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).contactNumber,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context).enterContactNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      readOnly: true,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).address,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _fetchingLocation
                        ? null
                        : () => _fetchCurrentLocation(),
                    icon: _fetchingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(AppLocalizations.of(context).useCurrent),
                  ),
                ],
              ),
              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_latitude!.toStringAsFixed(5)}, '
                  'Lng: ${_longitude!.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _saveProduct,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(AppLocalizations.of(context).productSaved),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.initialProduct != null)
                Text(
                  'Last harvested: ${dateFormat.format(widget.initialProduct!.harvestDate)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 36,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _DataUrlImageView extends StatelessWidget {
  const _DataUrlImageView({required this.dataUrl});

  final String dataUrl;

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = UriData.parse(dataUrl).contentAsBytes();
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return const _ImagePlaceholder(label: 'Tap to add photo');
    }
  }
}
