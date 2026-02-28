import 'package:flutter/material.dart';
import 'grant_requirements_screen.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

class GrantIntroScreen extends StatelessWidget {
  const GrantIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Upper Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Image.asset(
              'assets/images/ArgiPic.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black12,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 64,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),

          // Top-left Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Material(
              color: Colors.black.withValues(alpha: 0.4),
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
            ),
          ),

          // Header Text Overlaid on Image
          Positioned(
            top: MediaQuery.of(context).padding.top + 72,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).youngAgropreneurGrant,
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 12,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _outlinedText(
                  AppLocalizations.of(context).acceleratingCareer,
                  const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  strokeWidth: 2,
                ),
              ],
            ),
          ),

          // Content Body with Rounded Top Corners
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Decorative indicator
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Intro Title
                          Text(
                            AppLocalizations.of(context).programOverview,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Intro Description
                          Text(
                            AppLocalizations.of(context).programOverviewDesc,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Highlight Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.green[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.green[700],
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).empoweringNextGen,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80), // Space for button
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GrantRequirementsScreen(),
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
                    AppLocalizations.of(context).viewRequirements,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlinedText(String text, TextStyle style, {double strokeWidth = 2}) {
    return Stack(
      children: [
        Text(
          text,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = Colors.black.withValues(alpha: 0.75),
          ),
        ),
        Text(text, style: style),
      ],
    );
  }
}
