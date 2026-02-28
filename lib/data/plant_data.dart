import 'package:flutter/material.dart';

class PlantData {
  static const List<Map<String, dynamic>> allPlants = [
    // Vegetables
    {
      'name': 'Tomato',
      'icon': Icons.circle,
      'color': Color(0xFFE53935),
    },
    {
      'name': 'Chili',
      'icon': Icons.local_fire_department,
      'color': Color(0xFFD32F2F),
    },
    // Fruits
    {
      'name': 'Papaya',
      'icon': Icons.spa,
      'color': Color(0xFFFFB300),
    },
    {
      'name': 'Banana',
      'icon': Icons.nature,
      'color': Color(0xFFFFEB3B),
    },
    {
      'name': 'Strawberry',
      'icon': Icons.local_florist,
      'color': Color(0xFFE91E63),
    },
    {
      'name': 'Apple',
      'icon': Icons.apple,
      'color': Color(0xFFEF5350),
    },
    // Herbs
    {
      'name': 'Pandan',
      'icon': Icons.grass,
      'color': Color(0xFF388E3C),
    },
  ];

  static IconData getIconForCrop(String cropName) {
    for (final plant in allPlants) {
      if (plant['name'] == cropName) {
        return plant['icon'] as IconData;
      }
    }
    return Icons.spa; // Default fallback icon
  }
}
