import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

// Tutorial Step Model
class TutorialStep {
  final List<String> imagePaths;
  final String title;
  final String description;
  final String? link;
  final String? linkLabel;

  TutorialStep({
    List<String>? imagePaths,
    required this.title,
    required this.description,
    this.link,
    this.linkLabel,
  }) : imagePaths = imagePaths ?? const [];
}

class GrantTutorialScreen extends StatefulWidget {
  const GrantTutorialScreen({super.key});

  @override
  State<GrantTutorialScreen> createState() => _GrantTutorialScreenState();
}

class _GrantTutorialScreenState extends State<GrantTutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Tutorial Steps Data
  late final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      imagePaths: ['assets/images/Step1_createAccount.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(0),
      description: AppLocalizations.of(context).tutorialStepDescription(0),
      link: 'https://app-egam.kpkm.gov.my/user/register/create',
      linkLabel: AppLocalizations.of(context).openPortal,
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step2_verifyEmail.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(1),
      description: AppLocalizations.of(context).tutorialStepDescription(1),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step3_loginEGam.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(2),
      description: AppLocalizations.of(context).tutorialStepDescription(2),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step4_chooseProgram&ApplyNow.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(3),
      description: AppLocalizations.of(context).tutorialStepDescription(3),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step5_selectRequirement.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(4),
      description: AppLocalizations.of(context).tutorialStepDescription(4),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step6a_fillInformation.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(5),
      description: AppLocalizations.of(context).tutorialStepDescription(5),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step6b_ProjectDetails.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(6),
      description: AppLocalizations.of(context).tutorialStepDescription(6),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step6c_updateListNeeded.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(7),
      description: AppLocalizations.of(context).tutorialStepDescription(7),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step6d_fillBusinessDetails.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(8),
      description: AppLocalizations.of(context).tutorialStepDescription(8),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step6e_updateBudgetPlan.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(9),
      description: AppLocalizations.of(context).tutorialStepDescription(9),
    ),
    TutorialStep(
      imagePaths: ['assets/images/Step6f_fillDeclaration.jpg'],
      title: AppLocalizations.of(context).tutorialStepTitle(10),
      description: AppLocalizations.of(context).tutorialStepDescription(10),
    ),
    TutorialStep(
      imagePaths: [
        'assets/images/Step6g_saveDraft.jpg',
        'assets/images/Step6h_checkDraft&allInformation.jpg',
        'assets/images/Step6i_submitApplication.jpg',
      ],
      title: AppLocalizations.of(context).tutorialStepTitle(11),
      description: AppLocalizations.of(context).tutorialStepDescription(11),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _tutorialSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildStyledDescription(String text) {
    // Split by newline to handle sections
    final lines = text.split('\n\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        // Check if line contains Pro Tip or Important
        if (line.contains('💡 Pro Tip:')) {
          return _buildHighlightCard(
            line.replaceAll('💡 Pro Tip:', '').trim(),
            Colors.blue[50]!,
            Colors.blue[700]!,
            Icons.lightbulb_outline,
          );
        } else if (line.contains('⚠️ Important:')) {
          return _buildHighlightCard(
            line.replaceAll('⚠️ Important:', '').trim(),
            Colors.orange[50]!,
            Colors.orange[700]!,
            Icons.warning_amber_outlined,
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          );
        }
      }).toList(),
    );
  }

  Widget _buildHighlightCard(
    String text,
    Color bgColor,
    Color iconColor,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: iconColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).grantTutorial,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(bottom: BorderSide(color: Colors.green[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  ).stepOf(_currentPage + 1, _tutorialSteps.length),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(width: 16),
                // Progress indicators
                Row(
                  children: List.generate(
                    _tutorialSteps.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PageView with Tutorial Steps
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _tutorialSteps.length,
              itemBuilder: (context, index) {
                final step = _tutorialSteps[index];
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Image Section (supports multiple images)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: step.imagePaths.map((path) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  path,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Fallback placeholder if image is missing
                                    return Container(
                                      color: Colors.grey[200],
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 32,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 64,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image placeholder\n${path.split('/').last}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      // Text Content Section (55%)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description with styled tips
                            _buildStyledDescription(step.description),

                            // Link Button (if available)
                            if (step.link != null) ...[
                              const SizedBox(height: 16),
                              _buildLinkButton(
                                step.link!,
                                step.linkLabel ?? 'Open Link',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom Navigation Bar
          Container(
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
              child: Row(
                children: [
                  // Previous Button
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _goToPreviousPage,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  const Spacer(),

                  // Next Button
                  ElevatedButton.icon(
                    onPressed: _goToNextPage,
                    icon: Text(
                      _currentPage == _tutorialSteps.length - 1
                          ? AppLocalizations.of(context).finishButton
                          : AppLocalizations.of(context).nextButton,
                    ),
                    label: Icon(
                      _currentPage == _tutorialSteps.length - 1
                          ? Icons.check
                          : Icons.arrow_forward,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Could not open link: $url')),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildLinkButton(String url, String label) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: () => _launchURL(url),
        icon: const Icon(Icons.open_in_new, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
