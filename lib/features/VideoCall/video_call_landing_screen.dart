import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';
import '../../core/services/ai_video_call_service.dart';
import 'ai_video_call_screen.dart';

/// A pre-call screen where farmers select their preferred language
/// before starting the AI video call.
class VideoCallLandingScreen extends StatefulWidget {
  const VideoCallLandingScreen({super.key});

  @override
  State<VideoCallLandingScreen> createState() => _VideoCallLandingScreenState();
}

class _VideoCallLandingScreenState extends State<VideoCallLandingScreen> {
  String _selectedLanguage = 'zh';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).aiVideoCall),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Hero illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam,
                size: 56,
                color: Colors.green.shade700,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              AppLocalizations.of(context).talkToAiInYourLanguage,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              AppLocalizations.of(context).videoCallDescription,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Language selection
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context).selectYourLanguage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            ...AiVideoCallService.supportedLanguages.entries.map(
              (entry) => _buildLanguageTile(entry.key, entry.value),
            ),

            const SizedBox(height: 32),

            // Features list
            _buildFeatureItem(
              Icons.camera_alt,
              AppLocalizations.of(context).showCrops,
              AppLocalizations.of(context).showCropsDesc,
            ),
            _buildFeatureItem(
              Icons.mic,
              AppLocalizations.of(context).speakNaturally,
              AppLocalizations.of(context).speakNaturallyDesc,
            ),
            _buildFeatureItem(
              Icons.smart_toy,
              AppLocalizations.of(context).aiAnalysis,
              AppLocalizations.of(context).aiAnalysisDesc,
            ),
            _buildFeatureItem(
              Icons.volume_up,
              AppLocalizations.of(context).voiceResponse,
              AppLocalizations.of(context).voiceResponseDesc,
            ),

            const SizedBox(height: 32),

            // Start call button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startVideoCall,
                icon: const Icon(Icons.videocam, size: 24),
                label: Text(
                  AppLocalizations.of(context).startVideoCall,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              AppLocalizations.of(context).requiresCameraMic,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String code, LanguageOption lang) {
    final isSelected = code == _selectedLanguage;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  lang.name.substring(0, 1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.green.shade700 : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.green.shade700
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    lang.englishName,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 24)
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey.shade300,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startVideoCall() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AiVideoCallScreen(initialLanguage: _selectedLanguage),
      ),
    );
  }
}
