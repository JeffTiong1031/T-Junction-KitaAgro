import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Service that handles multimodal AI conversations by sending
/// camera frames + text (transcribed speech) to Gemini and getting
/// responses in the farmer's language.
class AiVideoCallService {
  final String apiKey;
  static const String _model = 'gemini-2.5-flash';

  AiVideoCallService(this.apiKey);

  /// Supported languages for the video call feature.
  static const Map<String, LanguageOption> supportedLanguages = {
    'zh': LanguageOption(
      code: 'zh',
      name: '中文',
      englishName: 'Chinese',
      speechLocale: 'zh-CN',
      ttsLanguage: 'zh-CN',
    ),
    'ms': LanguageOption(
      code: 'ms',
      name: 'Bahasa Melayu',
      englishName: 'Malay',
      speechLocale: 'ms-MY',
      ttsLanguage: 'ms-MY',
    ),
    'ta': LanguageOption(
      code: 'ta',
      name: 'தமிழ்',
      englishName: 'Tamil',
      speechLocale: 'ta-IN',
      ttsLanguage: 'ta-IN',
    ),
    'en': LanguageOption(
      code: 'en',
      name: 'English',
      englishName: 'English',
      speechLocale: 'en-US',
      ttsLanguage: 'en-US',
    ),
    'hi': LanguageOption(
      code: 'hi',
      name: 'हिन्दी',
      englishName: 'Hindi',
      speechLocale: 'hi-IN',
      ttsLanguage: 'hi-IN',
    ),
    'id': LanguageOption(
      code: 'id',
      name: 'Bahasa Indonesia',
      englishName: 'Indonesian',
      speechLocale: 'id-ID',
      ttsLanguage: 'id-ID',
    ),
  };

  /// Sends a camera frame (JPEG bytes) and the farmer's transcribed speech
  /// to Gemini for multimodal analysis. Returns the AI response text.
  ///
  /// [imageBytes] - JPEG-encoded camera frame
  /// [spokenText] - Transcribed speech from the farmer
  /// [languageCode] - The farmer's preferred language code (e.g. 'zh', 'ms')
  /// [conversationHistory] - Previous messages for context continuity
  Future<String> analyzeFrameWithSpeech({
    Uint8List? imageBytes,
    required String spokenText,
    required String languageCode,
    List<ConversationMessage> conversationHistory = const [],
  }) async {
    final lang = supportedLanguages[languageCode] ?? supportedLanguages['en']!;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    // Build the system instruction
    final systemInstruction = _buildSystemInstruction(lang);

    // Build content parts
    final List<Map<String, dynamic>> parts = [];

    // Add the text prompt
    final userPrompt = _buildUserPrompt(spokenText, lang, imageBytes != null);
    parts.add({'text': userPrompt});

    // Add the image if available
    if (imageBytes != null) {
      parts.add({
        'inline_data': {
          'mime_type': 'image/jpeg',
          'data': base64Encode(imageBytes),
        },
      });
    }

    // Build the full request with conversation history
    final List<Map<String, dynamic>> contents = [];

    // Add conversation history for context
    for (final msg in conversationHistory.take(10)) {
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text},
        ],
      });
    }

    // Add current user message
    contents.add({
      'role': 'user',
      'parts': parts,
    });

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topP': 0.9,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        },
      ],
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final responseParts = content['parts'] as List?;
          if (responseParts != null && responseParts.isNotEmpty) {
            return responseParts[0]['text'] ?? _getErrorMessage(lang);
          }
        }
        return _getErrorMessage(lang);
      } else if (response.statusCode == 429) {
        return _getQuotaMessage(lang);
      } else {
        return _getErrorMessage(lang);
      }
    } catch (e) {
      return _getNetworkErrorMessage(lang);
    }
  }

  String _buildSystemInstruction(LanguageOption lang) {
    return '''You are KitaAgro AI Assistant — an expert agricultural advisor designed to help farmers via live video calls.

CRITICAL RULES:
1. ALWAYS respond in ${lang.englishName} (${lang.name}). Never switch to English unless the user speaks English.
2. You are having a LIVE VIDEO CALL with a farmer. They may show you their crops, leaves, soil, or pests through the camera.
3. When you see an image, analyze it carefully for:
   - Plant health (leaf color, spots, wilting, etc.)
   - Pest damage or pest identification
   - Nutrient deficiencies (yellowing, browning patterns)
   - Disease symptoms (fungal, bacterial, viral)
   - Soil condition if visible
4. Provide practical, actionable advice that a farmer can immediately use.
5. Keep responses concise and conversational — this is a live call, not a written report.
6. Use simple, everyday language — the farmer may not know technical terms.
7. Be warm, supportive, and encouraging.
8. If the image is unclear, ask the farmer to show you more closely.
9. If you cannot identify a problem, suggest the farmer consult a local agricultural extension officer.

RESPONSE FORMAT:
- Keep responses SHORT (2-4 sentences for simple questions, up to a paragraph for diagnoses).
- Speak naturally as if in a conversation.
- Do NOT use markdown formatting (no **, no ##, no bullet points) — your response will be read aloud.''';
  }

  String _buildUserPrompt(
    String spokenText,
    LanguageOption lang,
    bool hasImage,
  ) {
    if (hasImage && spokenText.isNotEmpty) {
      return 'The farmer says: "$spokenText"\n\nPlease look at the camera image they are showing you and respond to their question/concern in ${lang.englishName}.';
    } else if (hasImage) {
      return 'The farmer is showing you something through the camera but hasn\'t said anything. Analyze what you see in the image and provide helpful feedback in ${lang.englishName}.';
    } else {
      return 'The farmer says: "$spokenText"\n\nRespond helpfully in ${lang.englishName}. No image is available right now.';
    }
  }

  String _getErrorMessage(LanguageOption lang) {
    const messages = {
      'zh': '抱歉，我暂时无法处理您的请求。请再试一次。',
      'ms': 'Maaf, saya tidak dapat memproses permintaan anda buat masa ini. Sila cuba lagi.',
      'ta': 'மன்னிக்கவும், உங்கள் கோரிக்கையை இப்போது செயல்படுத்த முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      'en': 'Sorry, I couldn\'t process your request right now. Please try again.',
      'hi': 'क्षमा करें, मैं अभी आपके अनुरोध को संसाधित नहीं कर सका। कृपया पुनः प्रयास करें।',
      'id': 'Maaf, saya tidak dapat memproses permintaan Anda saat ini. Silakan coba lagi.',
    };
    return messages[lang.code] ?? messages['en']!;
  }

  String _getQuotaMessage(LanguageOption lang) {
    const messages = {
      'zh': '系统繁忙，请稍后再试。',
      'ms': 'Sistem sibuk, sila cuba sebentar lagi.',
      'ta': 'அமைப்பு பிஸியாக உள்ளது, சிறிது நேரம் கழித்து முயற்சிக்கவும்.',
      'en': 'The system is busy, please try again shortly.',
      'hi': 'सिस्टम व्यस्त है, कृपया थोड़ी देर बाद पुनः प्रयास करें।',
      'id': 'Sistem sedang sibuk, silakan coba lagi nanti.',
    };
    return messages[lang.code] ?? messages['en']!;
  }

  String _getNetworkErrorMessage(LanguageOption lang) {
    const messages = {
      'zh': '网络连接出现问题。请检查您的网络连接后再试。',
      'ms': 'Masalah rangkaian. Sila semak sambungan internet anda dan cuba lagi.',
      'ta': 'நெட்வொர்க் பிரச்சனை. உங்கள் இணைய இணைப்பை சரிபார்த்து மீண்டும் முயற்சிக்கவும்.',
      'en': 'Network issue. Please check your internet connection and try again.',
      'hi': 'नेटवर्क समस्या। कृपया अपना इंटरनेट कनेक्शन जाँचें और पुनः प्रयास करें।',
      'id': 'Masalah jaringan. Silakan periksa koneksi internet Anda dan coba lagi.',
    };
    return messages[lang.code] ?? messages['en']!;
  }
}

/// Represents a language option for the video call.
class LanguageOption {
  final String code;
  final String name;
  final String englishName;
  final String speechLocale;
  final String ttsLanguage;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.englishName,
    required this.speechLocale,
    required this.ttsLanguage,
  });
}

/// Represents a message in the conversation history.
class ConversationMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ConversationMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
