import 'package:flutter/material.dart';
import 'grant_tutorial_screen.dart';
import 'package:kita_agro/main_layout.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

class GrantRequirementsScreen extends StatelessWidget {
  const GrantRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).programRequirements,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Home',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainLayout(initialIndex: 1),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[700],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).eligibilityRequirements,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).reviewCriteria,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Objectives Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: Colors.green[700],
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppLocalizations.of(context).programObjectives,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildObjectiveItem(
                        icon: Icons.people_outline,
                        text: AppLocalizations.of(context).objective1,
                      ),
                      const SizedBox(height: 12),
                      _buildObjectiveItem(
                        icon: Icons.psychology_outlined,
                        text: AppLocalizations.of(context).objective2,
                      ),
                      const SizedBox(height: 12),
                      _buildObjectiveItem(
                        icon: Icons.trending_up,
                        text: AppLocalizations.of(context).objective3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Requirements Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                AppLocalizations.of(context).eligibilityReqs,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),

            // Basic Requirements Expansion Tile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.person_outline, color: Colors.green[700]),
                  ),
                  title: Text(
                    AppLocalizations.of(context).basicRequirements,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).generalEligibility,
                    style: const TextStyle(fontSize: 13),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRequirementItem(
                            number: '1',
                            text: AppLocalizations.of(context).req1,
                          ),
                          const SizedBox(height: 12),
                          _buildRequirementItem(
                            number: '2',
                            text: AppLocalizations.of(context).req2,
                          ),
                          const SizedBox(height: 12),
                          _buildRequirementItem(
                            number: '3',
                            text: AppLocalizations.of(context).req3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Start-up Requirements Expansion Tile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange[100],
                    child: Icon(
                      Icons.rocket_launch_outlined,
                      color: Colors.orange[700],
                    ),
                  ),
                  title: Text(
                    AppLocalizations.of(context).startupRequirements,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).additionalCriteria,
                    style: const TextStyle(fontSize: 13),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRequirementItem(
                            number: '1',
                            text: AppLocalizations.of(context).startupReq1,
                          ),
                          const SizedBox(height: 12),
                          _buildRequirementItem(
                            number: '2',
                            text: AppLocalizations.of(context).startupReq2,
                          ),
                          const SizedBox(height: 12),
                          _buildRequirementItem(
                            number: '3',
                            text: AppLocalizations.of(context).startupReq3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GrantTutorialScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              AppLocalizations.of(context).startApplication,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildObjectiveItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementItem({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.green[700],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
