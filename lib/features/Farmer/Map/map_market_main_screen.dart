import 'package:flutter/material.dart';
import '../../../core/services/app_localizations.dart';

import 'map_screen.dart';
import 'marketplace_screen.dart';
import 'my_product_screen.dart';

class MapMarketMainScreen extends StatefulWidget {
  const MapMarketMainScreen({super.key});

  @override
  State<MapMarketMainScreen> createState() => _MapMarketMainScreenState();
}

class _MapMarketMainScreenState extends State<MapMarketMainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = const <Widget>[
    MapScreen(),
    MarketplaceScreen(),
    MyProductScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            label: AppLocalizations.of(context).map,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.storefront_outlined),
            label: AppLocalizations.of(context).marketplace,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            label: AppLocalizations.of(context).myProduct,
          ),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
