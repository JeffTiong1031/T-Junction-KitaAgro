import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/services/ai_video_call_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A video-call-style screen where farmers can show their crops via camera
/// and speak in their preferred language. The AI sees the camera feed,
/// understands the speech, and responds in the same language.
class AiVideoCallScreen extends StatefulWidget {
  final String initialLanguage;

  const AiVideoCallScreen({super.key, this.initialLanguage = 'zh'});

  @override
  State<AiVideoCallScreen> createState() => _AiVideoCallScreenState();
}

class _AiVideoCallScreenState extends State<AiVideoCallScreen>
    with WidgetsBindingObserver {
  // ── Services ──────────────────────────────────────────────────────────
  late AiVideoCallService _aiService;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  // ── Camera ────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isUsingFrontCamera = false;

  // ── State ─────────────────────────────────────────────────────────────
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isMicAvailable = false;
  bool _permissionsGranted = false;
  String _currentTranscription = '';
  late String _selectedLanguage;
  final List<ConversationMessage> _conversationHistory = [];
  final List<_ChatBubble> _chatMessages = [];
  final ScrollController _chatScrollController = ScrollController();

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedLanguage = widget.initialLanguage;
    _aiService = AiVideoCallService(
      dotenv.env['GEMINI_API_KEY_AI_ASSISTANT_AND_VIDEO'] ?? '',
    );
    _initializeAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // ── Initialization ────────────────────────────────────────────────────

  Future<void> _initializeAll() async {
    await _requestPermissions();
    if (_permissionsGranted) {
      await Future.wait([
        _initializeCamera(),
        _initializeSpeech(),
        _initializeTts(),
      ]);
    }
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    setState(() {
      _permissionsGranted = cameraStatus.isGranted && micStatus.isGranted;
    });

    if (!_permissionsGranted && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Camera and microphone permissions are required for the AI Video Call feature. '
          'Please grant them in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final cameraIndex = _isUsingFrontCamera
          ? _cameras.indexWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
            )
          : _cameras.indexWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
            );

      final camera = _cameras[cameraIndex == -1 ? 0 : cameraIndex];

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      _isMicAvailable = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
              // Process the transcription when speech stops
              if (_currentTranscription.isNotEmpty) {
                _processConversation(_currentTranscription);
              }
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _initializeTts() async {
    // Android requires specific engine setup
    await _flutterTts.setEngine('com.google.android.tts');

    final lang = AiVideoCallService.supportedLanguages[_selectedLanguage]!;

    // Check if the language is available
    final isAvailable = await _flutterTts.isLanguageAvailable(lang.ttsLanguage);
    debugPrint('TTS language ${lang.ttsLanguage} available: $isAvailable');

    await _flutterTts.setLanguage(lang.ttsLanguage);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      debugPrint('TTS started speaking');
    });

    _flutterTts.setCompletionHandler(() {
      debugPrint('TTS completed');
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  // ── Camera Actions ────────────────────────────────────────────────────

  Future<Uint8List?> _captureFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }
    try {
      final XFile photo = await _cameraController!.takePicture();
      return await photo.readAsBytes();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  Future<void> _switchCamera() async {
    setState(() {
      _isUsingFrontCamera = !_isUsingFrontCamera;
      _isCameraInitialized = false;
    });
    await _cameraController?.dispose();
    await _initializeCamera();
  }

  // ── Speech Actions ────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_isMicAvailable || _isProcessing) return;

    // Stop TTS if currently speaking
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    }

    final lang = AiVideoCallService.supportedLanguages[_selectedLanguage]!;

    setState(() {
      _isListening = true;
      _currentTranscription = '';
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _currentTranscription = result.recognizedWords;
        });
      },
      localeId: lang.speechLocale,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: false, // Don't stop on minor glitches
      partialResults: true,
      listenFor: const Duration(
        minutes: 1,
      ), // Keep listening for up to 5 minutes
      pauseFor: const Duration(seconds: 30), // Allow 30 seconds of silence
    );
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);

    if (_currentTranscription.isNotEmpty) {
      _processConversation(_currentTranscription);
    }
  }

  // ── AI Processing ─────────────────────────────────────────────────────

  Future<void> _processConversation(String spokenText) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Add user message to chat
    _addChatMessage(spokenText, true);

    // Capture current camera frame
    final imageBytes = await _captureFrame();

    // Add to conversation history
    _conversationHistory.add(
      ConversationMessage(text: spokenText, isUser: true),
    );

    try {
      final response = await _aiService.analyzeFrameWithSpeech(
        imageBytes: imageBytes,
        spokenText: spokenText,
        languageCode: _selectedLanguage,
        conversationHistory: _conversationHistory,
      );

      // Add AI response to history
      _conversationHistory.add(
        ConversationMessage(text: response, isUser: false),
      );

      // Add AI message to chat
      _addChatMessage(response, false);

      // Speak the response
      await _speakResponse(response);
    } catch (e) {
      final errorMsg =
          AiVideoCallService.supportedLanguages[_selectedLanguage]?.name ??
          'Error processing your request.';
      _addChatMessage('Error: $errorMsg', false);
    } finally {
      setState(() {
        _isProcessing = false;
        _currentTranscription = '';
      });
    }
  }

  Future<void> _speakResponse(String text) async {
    if (text.isEmpty) return;

    setState(() => _isSpeaking = true);
    final lang = AiVideoCallService.supportedLanguages[_selectedLanguage]!;

    try {
      await _flutterTts.setLanguage(lang.ttsLanguage);
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      debugPrint(
        'TTS speaking in ${lang.ttsLanguage}: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
      );
      var result = await _flutterTts.speak(text);
      debugPrint('TTS speak result: $result');

      if (result != 1) {
        debugPrint('TTS failed, trying fallback language en-US');
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  // ── Chat UI Helpers ───────────────────────────────────────────────────

  void _addChatMessage(String text, bool isUser) {
    setState(() {
      _chatMessages.add(
        _ChatBubble(text: text, isUser: isUser, timestamp: DateTime.now()),
      );
    });
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _changeLanguage(String langCode) {
    setState(() {
      _selectedLanguage = langCode;
    });
    _initializeTts();
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      return _buildPermissionScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview (full screen background)
            _buildCameraPreview(),

            // Top bar (back, language, switch camera)
            _buildTopBar(),

            // Chat overlay (bottom half, semi-transparent)
            _buildChatOverlay(),

            // Current transcription indicator
            if (_currentTranscription.isNotEmpty) _buildTranscriptionBanner(),

            // Processing indicator
            if (_isProcessing) _buildProcessingIndicator(),

            // Bottom controls (mic button)
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('AI Video Call'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 80, color: Colors.white54),
              const SizedBox(height: 24),
              const Text(
                'Camera & Microphone access is required',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize?.height ?? 1,
          height: _cameraController!.value.previewSize?.width ?? 1,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final lang = AiVideoCallService.supportedLanguages[_selectedLanguage]!;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Back button
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),

            // AI label
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KitaAgro AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Live Video Call',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Language selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: PopupMenuButton<String>(
                onSelected: _changeLanguage,
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (_) => AiVideoCallService
                    .supportedLanguages
                    .entries
                    .map(
                      (e) => PopupMenuItem(
                        value: e.key,
                        child: Row(
                          children: [
                            if (e.key == _selectedLanguage)
                              const Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 18,
                              )
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: 8),
                            Text('${e.value.name} (${e.value.englishName})'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      lang.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 4),

            // Switch camera
            IconButton(
              onPressed: _switchCamera,
              icon: const Icon(Icons.cameraswitch, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOverlay() {
    if (_chatMessages.isEmpty) {
      return Positioned(
        bottom: 120,
        left: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.mic, color: Colors.green, size: 40),
              const SizedBox(height: 12),
              Text(
                _getWelcomeMessage(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: ListView.builder(
          controller: _chatScrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _chatMessages.length,
          itemBuilder: (context, index) {
            final msg = _chatMessages[index];
            return _buildMessageBubble(msg);
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatBubble msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? Colors.green.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.smart_toy,
                      size: 14,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'KitaAgro AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionBanner() {
    return Positioned(
      bottom: 130 + (_chatMessages.isEmpty ? 0 : 10),
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _currentTranscription,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getAnalyzingMessage(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Stop TTS button
            _buildControlButton(
              icon: _isSpeaking ? Icons.volume_off : Icons.volume_up,
              label: _isSpeaking ? 'Mute' : 'Sound',
              color: _isSpeaking ? Colors.orange : Colors.white54,
              onTap: () async {
                if (_isSpeaking) {
                  await _flutterTts.stop();
                  setState(() => _isSpeaking = false);
                }
              },
            ),

            // Main mic button
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isListening ? 80 : 70,
                height: _isListening ? 80 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.red : Colors.green,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              label: 'End',
              color: Colors.red,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.3),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Localized UI Strings ──────────────────────────────────────────────

  String _getWelcomeMessage() {
    const messages = {
      'zh': '按下麦克风按钮，向我展示您的农作物并用中文与我交流。',
      'ms':
          'Tekan butang mikrofon, tunjukkan tanaman anda dan bercakap dengan saya dalam Bahasa Melayu.',
      'ta':
          'மைக்ரோஃபோன் பொத்தானை அழுத்தி, உங்கள் பயிர்களைக் காட்டி தமிழில் என்னிடம் பேசுங்கள்.',
      'en': 'Press the microphone button, show me your crops, and talk to me.',
      'hi':
          'माइक्रोफ़ोन बटन दबाएं, मुझे अपनी फसलें दिखाएं और हिंदी में बात करें।',
      'id':
          'Tekan tombol mikrofon, tunjukkan tanaman Anda, dan bicara dengan saya dalam Bahasa Indonesia.',
    };
    return messages[_selectedLanguage] ?? messages['en']!;
  }

  String _getAnalyzingMessage() {
    const messages = {
      'zh': '正在分析中...',
      'ms': 'Sedang menganalisis...',
      'ta': 'பகுப்பாய்வு செய்கிறது...',
      'en': 'Analyzing...',
      'hi': 'विश्लेषण कर रहा है...',
      'id': 'Sedang menganalisis...',
    };
    return messages[_selectedLanguage] ?? messages['en']!;
  }
}

// ── Internal Chat Bubble Model ────────────────────────────────────────────

class _ChatBubble {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatBubble({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
