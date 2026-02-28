import 'package:flutter/material.dart';
import 'package:kita_agro/features/Farmer/grant/grant_intro_screen.dart';
import 'package:kita_agro/features/Farmer/Rental/land_listing_screen.dart';
import 'package:kita_agro/features/Farmer/Map/map_market_main_screen.dart';
import 'package:kita_agro/features/Farmer/pest_distribution_map_screen.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

class FarmerScreen extends StatelessWidget {
  const FarmerScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.farmerHub)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          _buildFunctionCard(
            context,
            icon: Icons.school,
            title: loc.agropreneurGuideline,
            color: Colors.blue,
            onTap: () => _navigateTo(context, const GrantIntroScreen()),
          ),
          _buildFunctionCard(
            context,
            icon: Icons.agriculture,
            title: loc.farmLandRental,
            color: Colors.green,
            onTap: () => _navigateTo(context, const LandListingScreen()),
          ),
          _buildFunctionCard(
            context,
            icon: Icons.shopping_bag,
            title: loc.marketplaceAndMap,
            color: Colors.orange,
            onTap: () => _navigateTo(context, const MapMarketMainScreen()),
          ),
          _buildFunctionCard(
            context,
            icon: Icons.bug_report,
            title: loc.pestDistribution,
            color: Colors.red,
            onTap: () =>
                _navigateTo(context, const PestDistributionMapScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
