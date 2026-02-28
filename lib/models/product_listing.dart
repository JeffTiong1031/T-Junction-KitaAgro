import 'package:cloud_firestore/cloud_firestore.dart';

class ProductListing {
  const ProductListing({
    required this.id,
    required this.userId,
    required this.cropName,
    required this.weight,
    required this.harvestDate,
    required this.contactNumber,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.colorValue,
    required this.iconCodePoint,
  });

  final String id;
  final String userId;
  final String cropName;
  final double weight;
  final DateTime harvestDate;
  final String contactNumber;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String address;
  final int colorValue;
  final int iconCodePoint;

  factory ProductListing.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('ProductListing ${snapshot.id} missing data');
    }

    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();
    final weight = (data['weight'] as num?)?.toDouble();
    if (latitude == null || longitude == null || weight == null) {
      throw StateError(
        'ProductListing ${snapshot.id} has invalid numeric fields',
      );
    }

    final rawHarvestDate = data['harvestDate'];
    DateTime? harvestDate;
    if (rawHarvestDate is Timestamp) {
      harvestDate = rawHarvestDate.toDate();
    } else if (rawHarvestDate is String) {
      harvestDate = DateTime.tryParse(rawHarvestDate);
    }

    if (harvestDate == null) {
      throw StateError('ProductListing ${snapshot.id} missing harvestDate');
    }

    return ProductListing(
      id: snapshot.id,
      userId: data['userId'] as String? ?? '',
      cropName: data['cropName'] as String? ?? '',
      weight: weight,
      harvestDate: harvestDate,
      contactNumber: data['contactNumber'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      address: data['address'] as String? ?? '',
      colorValue: data['colorValue'] as int? ?? 0,
      iconCodePoint: data['iconCodePoint'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'cropName': cropName,
      'weight': weight,
      'harvestDate': Timestamp.fromDate(harvestDate),
      'contactNumber': contactNumber,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
    };
  }
}
