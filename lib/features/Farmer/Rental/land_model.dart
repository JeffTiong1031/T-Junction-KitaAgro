import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for Land listing backed by Firestore "lands" documents
class Land {
  final String id;
  final String title;
  final String state;
  final String location;
  final double price;
  final String sizeDisplay;
  final double sizeValue;
  final String imageUrl;
  final String ownerPhone;

  Land({
    required this.id,
    required this.title,
    required this.state,
    required this.location,
    required this.price,
    required this.sizeDisplay,
    required this.sizeValue,
    required this.imageUrl,
    required this.ownerPhone,
  });

  /// Construct a Land instance directly from a Firestore document snapshot
  factory Land.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    String parseString(dynamic value) {
      if (value is String) {
        return value.trim();
      }
      return value?.toString() ?? '';
    }

    return Land(
      id: doc.id,
      title: parseString(data['title']),
      state: parseString(data['state']),
      location: parseString(data['location']),
      price: parseDouble(data['price']),
      sizeDisplay: parseString(
        data.containsKey('sizeDisplay')
            ? data['sizeDisplay']
            : data['size_display'],
      ),
      sizeValue: parseDouble(
        data.containsKey('sizeValue') ? data['sizeValue'] : data['size_value'],
      ),
      imageUrl: parseString(data['imageUrl']),
      ownerPhone: parseString(data['ownerPhone']),
    );
  }

  @override
  String toString() =>
      'Land(id: $id, title: $title, state: $state, location: $location, price: $price)';
}
