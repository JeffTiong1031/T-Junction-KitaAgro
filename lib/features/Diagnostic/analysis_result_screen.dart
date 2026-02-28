import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:kita_agro/core/services/pest_report_service.dart';
import 'package:kita_agro/core/services/app_localizations.dart';
import 'package:kita_agro/core/services/gemini_api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AnalysisResultScreen extends StatefulWidget {
  final File imageFile;
  final String analysisText; // Always in English from the AI
  final bool isPestMode;

  const AnalysisResultScreen({
    super.key,
    required this.imageFile,
    required this.analysisText,
    required this.isPestMode,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _isReporting = false;
  bool _isTranslating = false;

  // The original English text is always preserved for pest reporting
  late final String _originalEnglishText;

  // The text currently displayed (could be English or translated)
  late String _displayText;

  // Currently selected language: 'en', 'ms', or 'zh'
  String _selectedLang = 'en';

  // Cache translations so we don't re-call the API
  final Map<String, String> _translationCache = {};

  final GeminiApiService _apiService = GeminiApiService(
    dotenv.env['GEMINI_API_KEY_DIAGNOSTIC_ANALYSIS'] ?? '',
  );

  @override
  void initState() {
    super.initState();
    _originalEnglishText = widget.analysisText;
    _displayText = widget.analysisText;
    _translationCache['en'] = widget.analysisText;
  }

  // ─── Translation Logic ───────────────────────────────────────────
  Future<void> _switchLanguage(String langCode) async {
    if (langCode == _selectedLang) return;

    // If switching back to English, use cached original
    if (langCode == 'en') {
      setState(() {
        _selectedLang = 'en';
        _displayText = _originalEnglishText;
      });
      return;
    }

    // Check if we already have a cached translation
    if (_translationCache.containsKey(langCode)) {
      setState(() {
        _selectedLang = langCode;
        _displayText = _translationCache[langCode]!;
      });
      return;
    }

    // Call Gemini to translate
    setState(() {
      _isTranslating = true;
    });

    final translated = await _apiService.translateText(
      text: _originalEnglishText,
      targetLanguageCode: langCode,
    );

    if (mounted) {
      if (translated != null) {
        _translationCache[langCode] = translated;
        setState(() {
          _selectedLang = langCode;
          _displayText = translated;
          _isTranslating = false;
        });
      } else {
        setState(() {
          _isTranslating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translationFailed),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  // ─── Parsers ─────────────────────────────────────────────────────
  String _extractPestName(String text) {
    try {
      final lines = text.split('\n');
      for (var line in lines) {
        if (line.toLowerCase().contains("name:")) {
          String rawName = line
              .replaceAll(
                RegExp(
                  r'\*\*|\*|Pest Name:|Deficiency Name:',
                  caseSensitive: false,
                ),
                '',
              )
              .trim();

          if (rawName.contains('(')) {
            rawName = rawName.split('(')[0].trim();
          }
          if (rawName.contains(',')) {
            rawName = rawName.split(',')[0].trim();
          }

          final words = rawName.split(' ');
          if (words.length > 4) {
            return words.sublist(0, 4).join(' ');
          }

          return rawName;
        }
      }
    } catch (e) {
      print("Parsing error: $e");
    }
    return "Unknown Issue";
  }

  String _extractShortAdvice(String text) {
    try {
      final lines = text.split('\n');
      for (var line in lines) {
        if (line.toLowerCase().contains("short advice:")) {
          return line
              .replaceAll(
                RegExp(r'\*\*|\*|Short Advice:', caseSensitive: false),
                '',
              )
              .trim();
        }
      }
    } catch (e) {
      print("Parsing error: $e");
    }
    return "Take standard precautionary measures.";
  }

  String _extractThreat(String text) {
    try {
      final lines = text.split('\n');
      for (var line in lines) {
        if (line.toLowerCase().contains("threat:")) {
          String raw = line
              .replaceAll(RegExp(r'\*\*|\*|Threat:', caseSensitive: false), '')
              .trim();
          final words = raw.split(RegExp(r'\s+'));
          if (words.isNotEmpty) return words[0];
          return raw;
        }
      }
    } catch (e) {
      print("Parsing error: $e");
    }
    return "High";
  }

  // Always use the ENGLISH original text for pest reporting to Firebase
  void _handleReportOutbreak() async {
    setState(() {
      _isReporting = true;
    });

    try {
      // IMPORTANT: Always extract from the English original for Firebase
      final pestName = _extractPestName(_originalEnglishText);
      final shortAiAdvice = _extractShortAdvice(_originalEnglishText);
      final String threatLevel = _extractThreat(_originalEnglishText);
      final PestReportService reportService = PestReportService();

      await reportService.reportPestOutbreak(
        pestName,
        threatLevel,
        shortAiAdvice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).outbreakReported),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to report: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReporting = false;
        });
      }
    }
  }

  // Hides "Short Advice" from the visible UI
  String _getVisibleAnalysisText(String fullText) {
    int cutIndex = fullText.toLowerCase().indexOf('short advice:');
    String visibleText = fullText;

    if (cutIndex != -1) {
      int lineStart = fullText.lastIndexOf('\n', cutIndex);
      if (lineStart != -1) {
        visibleText = fullText.substring(0, lineStart).trim();
      } else {
        visibleText = fullText
            .substring(0, cutIndex)
            .replaceAll('**', '')
            .trim();
      }
    }

    return visibleText;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPestMode
              ? loc.pestAnalysisResult
              : loc.nutrientAnalysisResult,
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SECTION 1: The Image ---
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      image: DecorationImage(
                        image: FileImage(widget.imageFile),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // --- SECTION 2: Language Selector ---
                  _buildLanguageSelector(loc),

                  // --- SECTION 3: The AI Analysis ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loc.diagnosisReport,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            if (_selectedLang != 'en')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.translate,
                                      size: 14,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      loc.viewingTranslation,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 10),

                        MarkdownBody(
                          data: _getVisibleAnalysisText(_displayText),
                          styleSheet:
                              MarkdownStyleSheet.fromTheme(
                                Theme.of(context),
                              ).copyWith(
                                h2: const TextStyle(
                                  color: Colors.teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                p: const TextStyle(fontSize: 16, height: 1.5),
                              ),
                        ),
                      ],
                    ),
                  ),

                  // --- SECTION 4: Report Outbreak Button (Pests only) ---
                  if (widget.isPestMode &&
                      !_originalEnglishText.toLowerCase().contains(
                        'none detected',
                      )) ...[
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10,
                      ),
                      child: Text(
                        loc.reportOutbreakHelp,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: ElevatedButton.icon(
                        onPressed: _isReporting ? null : _handleReportOutbreak,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: _isReporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.warning_amber_rounded),
                        label: Text(
                          _isReporting
                              ? loc.reportingLocation
                              : loc.reportOutbreak,
                        ),
                      ),
                    ),
                  ],

                  // Back Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(loc.backToScan),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Translating overlay
          if (_isTranslating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        loc.translating,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Language Selector Bar ───────────────────────────────────────
  Widget _buildLanguageSelector(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Icon(Icons.translate, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                _buildLangChip('EN', 'en'),
                const SizedBox(width: 8),
                _buildLangChip('BM', 'ms'),
                const SizedBox(width: 8),
                _buildLangChip('中文', 'zh'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String label, String langCode) {
    final isSelected = _selectedLang == langCode;

    return GestureDetector(
      onTap: _isTranslating ? null : () => _switchLanguage(langCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
