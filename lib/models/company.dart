import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  const Company({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String type;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;

  factory Company.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Company ${snapshot.id} missing data');
    }

    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      throw StateError('Company ${snapshot.id} missing coordinates');
    }

    return Company(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      latitude: latitude,
      longitude: longitude,
    );
  }
}
