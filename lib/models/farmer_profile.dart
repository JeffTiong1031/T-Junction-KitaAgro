import 'package:cloud_firestore/cloud_firestore.dart';

class FarmerProfile {
  const FarmerProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.ownerId,
  });

  final String id;
  final String name;
  final String description;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String? ownerId;

  factory FarmerProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('FarmerProfile ${snapshot.id} missing data');
    }

    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw StateError('FarmerProfile ${snapshot.id} missing coordinates');
    }

    return FarmerProfile(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
      ownerId: data['ownerId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (ownerId != null) 'ownerId': ownerId,
    };
  }
}
