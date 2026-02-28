import 'package:cloud_firestore/cloud_firestore.dart';

class CompanySeeder {
  CompanySeeder({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  final List<Map<String, dynamic>> _mockCompanies = [
    {
      'name': 'Bernas Grain Hub',
      'type': 'Rice Distributor',
      'address': 'Lot 12, Jalan Padi, Kuala Lumpur',
      'phone': '+60 3-1234 5678',
      'latitude': 3.139003,
      'longitude': 101.686855,
    },
    {
      'name': 'Farm Fresh HQ',
      'type': 'Dairy Processing',
      'address': 'No. 18, Jalan Susu Segar, Serdang',
      'phone': '+60 3-8765 4321',
      'latitude': 3.0255,
      'longitude': 101.7037,
    },
    {
      'name': 'AgroMart Shah Alam',
      'type': 'Agri Supply Store',
      'address': 'Persiaran Kayangan, Shah Alam',
      'phone': '+60 3-3344 5566',
      'latitude': 3.0738,
      'longitude': 101.5183,
    },
    {
      'name': 'Green Valley Co.',
      'type': 'Fresh Produce Exporter',
      'address': 'Jalan Pertanian 2, Klang',
      'phone': '+60 3-7788 9900',
      'latitude': 3.0338,
      'longitude': 101.4475,
    },
    {
      'name': 'Tropika Fruits',
      'type': 'Fruit Aggregator',
      'address': 'Jalan Tropika 8, Kajang',
      'phone': '+60 3-9988 7766',
      'latitude': 2.9925,
      'longitude': 101.7871,
    },
    {
      'name': 'North Agro Supply',
      'type': 'Agri Logistics',
      'address': 'Jalan Utara 5, Petaling Jaya',
      'phone': '+60 3-2145 8877',
      'latitude': 3.1245,
      'longitude': 101.6525,
    },
    {
      'name': 'Harvest Link',
      'type': 'Wholesale Market',
      'address': 'Jalan Pasar Besar, Kuala Lumpur',
      'phone': '+60 3-2266 4411',
      'latitude': 3.144,
      'longitude': 101.692,
    },
    {
      'name': 'Kebun Kita Cooperative',
      'type': 'Farming Cooperative',
      'address': 'Jalan Kebun 3, Puchong',
      'phone': '+60 3-6123 7788',
      'latitude': 3.0124,
      'longitude': 101.6171,
    },
    {
      'name': 'AquaFresh Seafood',
      'type': 'Aquaculture Supplier',
      'address': 'Jalan Lautan 2, Port Klang',
      'phone': '+60 3-3211 4455',
      'latitude': 2.999,
      'longitude': 101.392,
    },
    {
      'name': 'Highland Harvesters',
      'type': 'Vegetable Grower',
      'address': 'Jalan Tanah Tinggi, Genting',
      'phone': '+60 3-5554 2211',
      'latitude': 3.4213,
      'longitude': 101.7933,
    },
  ];

  Future<void> seed() async {
    final batch = _firestore.batch();
    final collection = _firestore.collection('companies');

    for (final company in _mockCompanies) {
      final doc = collection.doc();
      batch.set(doc, company);
    }

    await batch.commit();
  }
}
