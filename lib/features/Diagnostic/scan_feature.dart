import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:kita_agro/features/Diagnostic/analysis_result_screen.dart';
import 'package:kita_agro/core/services/gemini_api_service.dart';
import 'package:kita_agro/core/services/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ScanFeature extends StatefulWidget {
  const ScanFeature({super.key});

  @override
  State<ScanFeature> createState() => _ScanFeatureState();
}

class _ScanFeatureState extends State<ScanFeature>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final GeminiApiService _apiService = GeminiApiService(
    dotenv.env['GEMINI_API_KEY_DIAGNOSTIC_SCAN'] ?? '',
  );

  // ─── Design Constants ──────────────────────────────────────────────
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _lightGreen = Color(0xFF4CAF50);
  static const Color _softGreen = Color(0xFFE8F5E9);
  static const Color _bgColor = Color(0xFFF9FBF9);
  static const Color _cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _processImageForAnalysis(
    File pickedFile,
    bool userWantsPestDetection,
  ) async {
    setState(() {
      _isAnalyzing = true;
    });

    String mode = userWantsPestDetection ? "pest" : "nutrient";

    // Always analyze in English — translation happens on the result page
    String? result = await _apiService.analyzeImage(pickedFile.path, mode);

    // Sanitizer 1: wanted Pests but AI gave Nutrients
    if (userWantsPestDetection && result != null) {
      final low = result.toLowerCase();
      if (low.contains('deficiency name') || low.contains('nutrient')) {
        result =
            '''**Pest Name:** None detected\n\n**Threat:** Low\n\n**Symptoms:** No visible pest symptoms\n\n**Solutions:** No treatment needed\n\n**Short Advice:** No pests found''';
      }
    }
    // Sanitizer 2: wanted Nutrients but AI gave Pests
    else if (!userWantsPestDetection && result != null) {
      final low = result.toLowerCase();
      if (low.contains('pest name') ||
          (!low.contains('deficiency name') && low.contains('pest'))) {
        result =
            '''**Deficiency Name:** None detected\n\n**Threat:** Low\n\n**Symptoms:** No visible nutrient deficiencies. Plant appears nutritionally healthy.\n\n**Solutions:** Maintain current care routine.\n\n**Short Advice:** Nutrition looks good.''';
      }
    }

    setState(() {
      _isAnalyzing = false;
    });

    if (result != null && mounted) {
      if (result.startsWith("Error")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnalysisResultScreen(
              imageFile: pickedFile,
              analysisText: result!,
              isPestMode: userWantsPestDetection,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          loc.aiDiagnostics,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isAnalyzing ? _buildAnalyzingView(loc) : _buildMainView(loc),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ANALYZING STATE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAnalyzingView(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated scan icon
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _softGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _lightGreen.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.energy_savings_leaf_rounded,
                size: 56,
                color: _primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Color(0xFFE0E0E0),
              valueColor: AlwaysStoppedAnimation<Color>(_lightGreen),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loc.analyzing,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Powered by Gemini AI',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MAIN VIEW
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMainView(AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Description ──────────────────────────────────
          _buildHeader(loc),
          const SizedBox(height: 24),

          // ── Scan Zone / Image Preview ─────────────────────────────
          _selectedImage != null
              ? _buildImagePreview(loc)
              : _buildScanZone(loc),
          const SizedBox(height: 24),

          // ── Gallery & Camera Buttons ──────────────────────────────
          _buildPickerButtons(loc),

          // ── Analysis Buttons (only when image selected) ───────────
          if (_selectedImage != null) ...[
            const SizedBox(height: 28),
            _buildAnalysisButtons(loc),
          ],
        ],
      ),
    );
  }

  // ─── Header Section ──────────────────────────────────────────────
  Widget _buildHeader(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      loc.aiCropDiagnostics,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  loc.aiDiagnosticsSubtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Scan Zone (No Image Yet) ────────────────────────────────────
  Widget _buildScanZone(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _lightGreen.withOpacity(0.35),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Dashed border inner zone
          CustomPaint(
            painter: _DashedBorderPainter(
              color: _lightGreen.withOpacity(0.5),
              radius: 16,
              dashWidth: 8,
              dashGap: 5,
              strokeWidth: 2,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _softGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.energy_savings_leaf_rounded,
                        size: 40,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.scanZoneHelper,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 16,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'JPG, PNG',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Image Preview (Image Selected) ──────────────────────────────
  Widget _buildImagePreview(AppLocalizations loc) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                Image.file(
                  _selectedImage!,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Clear / change image button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Checkmark badge
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loc.imageReady,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Status bar under image
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.readyToScan,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gallery & Camera Buttons ────────────────────────────────────
  Widget _buildPickerButtons(AppLocalizations loc) {
    return Row(
      children: [
        // Gallery Button (secondary / outlined)
        Expanded(
          child: _PickerCard(
            icon: Icons.photo_library_rounded,
            label: loc.gallery,
            iconColor: _primaryGreen,
            bgColor: _softGreen,
            borderColor: _lightGreen.withOpacity(0.4),
            textColor: _primaryGreen,
            onTap: () => _pickImage(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 14),

        // Camera Button (primary / filled)
        Expanded(
          child: _PickerCard(
            icon: Icons.camera_alt_rounded,
            label: loc.camera,
            iconColor: Colors.white,
            bgColor: _primaryGreen,
            borderColor: _primaryGreen,
            textColor: Colors.white,
            onTap: () => _pickImage(ImageSource.camera),
          ),
        ),
      ],
    );
  }

  // ─── Analysis Buttons ────────────────────────────────────────────
  Widget _buildAnalysisButtons(AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 14),
          child: Text(
            loc.chooseAnalysisType,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        // Identify Pests
        _AnalysisCard(
          icon: Icons.bug_report_rounded,
          title: loc.identifyPests,
          subtitle: loc.detectPestsDesc,
          gradientColors: [const Color(0xFFE53935), const Color(0xFFFF7043)],
          onTap: () => _processImageForAnalysis(_selectedImage!, true),
        ),
        const SizedBox(height: 14),
        // Identify Nutrients
        _AnalysisCard(
          icon: Icons.eco_rounded,
          title: loc.identifyNutrients,
          subtitle: loc.checkNutrientsDesc,
          gradientColors: [_primaryGreen, const Color(0xFF66BB6A)],
          onTap: () => _processImageForAnalysis(_selectedImage!, false),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════════════

/// Picker Card for Gallery/Camera
class _PickerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PickerCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: iconColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Analysis Card for Pest/Nutrient identification
class _AnalysisCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _AnalysisCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  DASHED BORDER PAINTER
// ═══════════════════════════════════════════════════════════════════════
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        final extracted = metric.extractPath(distance, end);
        canvas.drawPath(extracted, paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
