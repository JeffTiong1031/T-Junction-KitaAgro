import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiApiService {
  final String apiKey;
  static DateTime? _quotaCooldownUntil;

  GeminiApiService(this.apiKey);

  bool get _isInQuotaCooldown {
    final until = _quotaCooldownUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _startQuotaCooldownFromBody(String responseBody) {
    final retrySeconds = _extractRetrySeconds(responseBody);
    final cooldownSeconds = retrySeconds > 0 ? retrySeconds : 60;
    _quotaCooldownUntil = DateTime.now().add(
      Duration(seconds: cooldownSeconds),
    );
  }

  int _extractRetrySeconds(String responseBody) {
    final match = RegExp(
      r'Please retry in\s+([0-9]+(?:\.[0-9]+)?)s',
      caseSensitive: false,
    ).firstMatch(responseBody);
    if (match == null) {
      return 0;
    }
    final value = double.tryParse(match.group(1) ?? '0') ?? 0;
    return value.ceil();
  }

  /// Returns the full language name for AI prompts
  String _languageName(String langCode) {
    switch (langCode) {
      case 'ms':
        return 'Bahasa Melayu';
      case 'zh':
        return 'Chinese (Simplified)';
      default:
        return 'English';
    }
  }

  String _buildPhotoFallback(String mode, {String languageCode = 'en'}) {
    // Always return English fallback — translation happens on the result page
    if (mode.contains("pest")) {
      return '**Pest Name:** Unable to analyze now\n\n**Threat:** Low\n\n**Symptoms:** AI quota is temporarily exceeded, so image diagnosis is paused.\n\n**Solutions:** Retry after about one minute. Meanwhile, isolate affected leaves and avoid overwatering.\n\n**Short Advice:** Retry soon; keep leaves dry.';
    }
    return '**Deficiency Name:** Unable to analyze now\n\n**Threat:** Low\n\n**Symptoms:** AI quota is temporarily exceeded, so nutrient diagnosis is paused.\n\n**Solutions:** Retry after about one minute. Meanwhile, check soil moisture and use balanced fertilizer carefully.\n\n**Short Advice:** Retry soon; monitor leaf color.';
  }

  Future<String?> analyzeImage(
    String imagePath,
    String mode, {
    String languageCode = 'en',
  }) async {
    if (_isInQuotaCooldown) {
      return _buildPhotoFallback(mode, languageCode: languageCode);
    }

    final String urlString =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final Uri url = Uri.parse(urlString);

    // 1. Prepare the Image
    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      return "Error: Image file not found.";
    }
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 2. Set the Prompt — always in English
    String prompt;
    if (mode.contains("pest")) {
      prompt =
          '''You are an expert Malaysian agricultural extension officer. Analyze this plant image for pests or diseases. 
Provide a detailed, highly informative analysis using Markdown formatting.

*IMPORTANT:* if you **do not** see any pests or diseases, do **not** guess at a nutrient
issue. Instead reply with a simple report indicating no pests were found – for example:

**Pest Name:** None detected

**Threat:** Low

**Symptoms:** No visible pest symptoms

**Solutions:** No treatment needed

You MUST otherwise strictly follow this exact template with double line breaks between sections:

**Pest Name:** [Insert exact pest or disease name]

**Threat:** [Low, Medium, or High]

**Symptoms:**
[Provide detailed symptoms using bullet points]

**Solutions:**
[Provide detailed treatment steps using bullet points. *CRITICAL: When recommending chemical or organic treatments, you MUST NOT just provide the generic active ingredient (like 'copper fungicide' or 'spinosad'). You MUST list 2-3 common local commercial brand names that a farmer would easily find in a typical Malaysian 'kedai baja' (agricultural supply shop). For example, if you recommend Glyphosate, mention 'Roundup' or 'Ecomax'. Highlight the brand names clearly.*]

At the VERY END of your response, on a new line, you MUST add this exact text:
**Short Advice:** [Insert exactly ONE short sentence (max 10 words) of advice for a mobile push notification]''';
    } else {
      prompt =
          '''You are an expert Malaysian agricultural extension officer. Analyze this plant image SPECIFICALLY for nutrient deficiencies. 
Provide a detailed, highly informative analysis using Markdown formatting.

*IMPORTANT:* Focus ONLY on nutrition. If the plant looks nutritionally healthy (even if there are pests, bugs, or insect damage visible), do **not** diagnose a pest issue. Instead reply with a simple report indicating no nutrient deficiencies were found – for example:

**Deficiency Name:** None detected

**Threat:** Low

**Symptoms:** Leaves appear nutritionally healthy. No visible nutrient deficiencies.

**Solutions:** Maintain current care routine.

You MUST otherwise strictly follow this exact template with double line breaks between sections:

**Deficiency Name:** [Insert exact nutrient deficiency name]

**Threat:** [Low, Medium, or High]

**Symptoms:**
[Provide detailed symptoms using bullet points]

**Solutions:**
[Provide detailed fertilizer recommendations using bullet points. *CRITICAL: When recommending fertilizers or treatments, you MUST NOT just provide generic advice (like 'apply NPK fertilizer' or 'add calcium'). You MUST list 2-3 common local commercial brand names or types that a farmer would easily find in a typical Malaysian 'kedai baja' (agricultural supply shop). Highlight the local Malaysian brand names clearly.*]

At the VERY END of your response, on a new line, you MUST add this exact text:
**Short Advice:** [Insert exactly ONE short sentence (max 10 words) of advice for a mobile push notification]''';
    }

    // 3. Build the JSON Body
    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
            },
          ],
        },
      ],
    };

    // 4. Send Request
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            "Error: No text in response.";
      } else {
        if (response.statusCode == 429) {
          _startQuotaCooldownFromBody(response.body);
          return _buildPhotoFallback(mode, languageCode: languageCode);
        }
        return "Server Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "Connection Error: $e";
    }
  }

  /// Generate location-aware plant growing advice using Gemini AI
  Future<Map<String, dynamic>?> getLocalizedAdvice({
    required String plantName,
    required String scientificName,
    required String category,
    required String location,
    required double temperature,
    required String weatherCondition,
    String languageCode = 'en',
  }) async {
    final String urlString =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final Uri url = Uri.parse(urlString);
    final String langName = _languageName(languageCode);

    final String prompt =
        '''
IMPORTANT: DO NOT TRANSLATE JSON KEYS. ONLY translate the text values inside the fields to $langName.

Growing conditions for $plantName ($scientificName) in $location. Temp: $temperature°C, Weather: $weatherCondition, Category: $category.

Return ONLY valid JSON with EXACTLY these English keys (be VERY concise, max 8 words per field, values in $langName):
{
  "localMatchScore": <0-100>,
  "growingContext": "<suitable or not, 1 short sentence in $langName>",
  "growthTime": "<e.g. 60-75 days>",
  "difficulty": "<e.g. Easy - tropical, in $langName>",
  "sunlight": "<e.g. Full sun 6-8 hours, in $langName>",
  "watering": "<e.g. Water daily in heat, in $langName>",
  "soil": "<e.g. Well-drained loamy soil, in $langName>",
  "carbonReduction": "<1 short phrase about CO2 benefit, in $langName>",
  "materialsNeeded": [{"item": "<material name in $langName>", "purpose": "<3-5 words in $langName>"}],
  "growthStages": [{"stage": "<name in $langName>", "startDay": <int>, "endDay": <int>, "description": "<under 6 words in $langName>"}]
}

Rules:
- DO NOT translate the JSON keys (e.g. keep "localMatchScore", "difficulty", etc. exact).
- materialsNeeded: 4-8 essential items (seeds, fertilizer, tools, pots, etc.).
- growthStages: 4-7 contiguous stages from day 1 to total growth days.
- ALL text fields: max 8 words. Be direct. Write in $langName.
''';

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 8192,
      },
    };

    try {
      print('📡 Sending request to Gemini API...');
      print(
        '🌿 Plant: ${plantName} | 📍 Location: ${location} | 🌡️ Temp: ${temperature}°C',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          final text =
              jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

          if (text == null) {
            print('⚠️ No text in Gemini response');
            print('📊 Full response structure: ${jsonResponse.toString()}');
            return null;
          }

          print('📝 Raw AI response length: ${text.length} characters');
          print(
            '📝 First 300 chars: ${text.substring(0, text.length > 300 ? 300 : text.length)}',
          );

          String jsonText = text.trim();
          if (jsonText.startsWith('```json')) {
            jsonText = jsonText.substring(7);
          } else if (jsonText.startsWith('```')) {
            jsonText = jsonText.substring(3);
          }
          if (jsonText.endsWith('```')) {
            jsonText = jsonText.substring(0, jsonText.length - 3);
          }
          jsonText = jsonText.trim();

          print('🔍 Extracted JSON length: ${jsonText.length} characters');

          final aiData = jsonDecode(jsonText);

          print('✅ Successfully parsed AI data');
          print('🎯 Match Score: ${aiData['localMatchScore']}');
          print('📖 Growth Time: ${aiData['growthTime']}');
          print('💪 Difficulty: ${aiData['difficulty']}');

          return {
            'localMatchScore': aiData['localMatchScore'],
            'growingContext': aiData['growingContext'],
            'growthTime': aiData['growthTime'],
            'difficulty': aiData['difficulty'],
            'sunlight': aiData['sunlight'],
            'watering': aiData['watering'],
            'soil': aiData['soil'],
            'carbonReduction': aiData['carbonReduction'],
            'materialsNeeded': aiData['materialsNeeded'],
            'growthStages': aiData['growthStages'],
          };
        } catch (parseError) {
          print('❌ JSON parsing error: $parseError');
          print('📊 Failed to parse text: ${response.body}');
          return null;
        }
      } else {
        print('❌ Gemini API Error ${response.statusCode}');
        print('📋 Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ AI Advice Error: $e');
      return null;
    }
  }

  /// Generate today's suggested tasks for a specific plant based on its growth stage
  Future<List<Map<String, String>>?> generateDailyTasks({
    required String plantName,
    required String scientificName,
    required String category,
    required int daysPlanted,
    required int totalDays,
    required String location,
    required double temperature,
    required String weatherCondition,
    String languageCode = 'en',
  }) async {
    final String urlString =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final Uri url = Uri.parse(urlString);
    final String langName = _languageName(languageCode);

    final String prompt =
        '''
You are a smart farming assistant. Generate 3-5 practical daily tasks for TODAY for a user growing $plantName ($scientificName).
IMPORTANT: DO NOT TRANSLATE JSON KEYS. ONLY translate the text values inside the fields to $langName.

Context:
- Category: $category
- Day $daysPlanted of $totalDays total growing days
- Location: $location
- Temperature: $temperature°C
- Weather: $weatherCondition

Respond ONLY with a valid JSON array. Each task object MUST HAVE EXACTLY THESE ENGLISH KEYS: "task" (under 10 words, value in $langName) and "icon" (one of exact english words: water, sun, fertilizer, prune, inspect, harvest, protect, soil).

Keep it SHORT. Return ONLY the JSON array.
''';

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      "generationConfig": {
        "temperature": 0.8,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 8192,
      },
    };

    try {
      print(
        '📋 Generating daily tasks for $plantName (day $daysPlanted/$totalDays)...',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          final text =
              jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];

          if (text == null) return null;

          String jsonText = text.trim();
          if (jsonText.startsWith('```json')) {
            jsonText = jsonText.substring(7);
          } else if (jsonText.startsWith('```')) {
            jsonText = jsonText.substring(3);
          }
          if (jsonText.endsWith('```')) {
            jsonText = jsonText.substring(0, jsonText.length - 3);
          }
          jsonText = jsonText.trim();

          if (!jsonText.endsWith(']')) {
            final lastBrace = jsonText.lastIndexOf('}');
            if (lastBrace > 0) {
              jsonText = '${jsonText.substring(0, lastBrace + 1)}]';
            } else {
              print('❌ Could not repair truncated JSON');
              return null;
            }
          }

          final List<dynamic> tasks = jsonDecode(jsonText);
          print('✅ Generated ${tasks.length} daily tasks');
          return tasks
              .where((t) => t is Map && t['task'] != null)
              .map<Map<String, String>>(
                (t) => {
                  'task': (t['task'] as String?) ?? '',
                  'icon': (t['icon'] as String?) ?? 'inspect',
                },
              )
              .toList();
        } catch (parseError) {
          print('❌ Task parsing error: $parseError');
          return null;
        }
      } else {
        print('❌ Task API Error ${response.statusCode}');
        if (response.statusCode == 429) {
          throw Exception('API limit reached. Please try again later.');
        }
        return null;
      }
    } catch (e) {
      print('❌ Task generation error: $e');
      if (e.toString().contains('API limit reached')) throw e;
      return null;
    }
  }

  /// Analyze a plant photo and return a diagnosis + concise task suggestions
  Future<Map<String, dynamic>?> analyzeAndSuggestTasks({
    required String imagePath,
    required String plantName,
    required int daysPlanted,
    required int totalDays,
    String languageCode = 'en',
  }) async {
    final String urlString =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    final Uri url = Uri.parse(urlString);
    final String langName = _languageName(languageCode);

    final File imageFile = File(imagePath);
    if (!await imageFile.exists()) return null;
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final String prompt =
        '''
You are a plant doctor. Analyze the photo of this $plantName (day $daysPlanted of $totalDays).
IMPORTANT: DO NOT TRANSLATE JSON KEYS. ONLY translate the text values inside the fields to $langName.

Return ONLY valid JSON with EXACTLY these English keys:
{
  "status": "<Healthy / Needs Attention / Critical, in $langName>",
  "diagnosis": "<1 sentence, max 15 words, what you see, in $langName>",
  "tasks": [{"task":"<under 10 words, in $langName>","icon":"<water|sun|fertilizer|prune|inspect|harvest|protect|soil>"}]
}

Rules:
- DO NOT translate the JSON keys. Keep "status", "diagnosis", "tasks", "task", and "icon" exact.
- Give 2-4 tasks based on what you SEE in the photo.
- Be specific to the visual condition (yellowing, wilting, pests, healthy growth, etc.).
- Return ONLY the JSON.
''';

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {"mime_type": "image/jpeg", "data": base64Image},
            },
          ],
        },
      ],
      "generationConfig": {"temperature": 0.7, "maxOutputTokens": 8192},
    };

    try {
      print('📸 Analyzing plant photo for $plantName...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(response.body);
          final text =
              jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text == null) return null;

          String jsonText = text.trim();
          if (jsonText.startsWith('```json'))
            jsonText = jsonText.substring(7);
          else if (jsonText.startsWith('```'))
            jsonText = jsonText.substring(3);
          if (jsonText.endsWith('```'))
            jsonText = jsonText.substring(0, jsonText.length - 3);
          jsonText = jsonText.trim();

          final data = jsonDecode(jsonText) as Map<String, dynamic>;
          print('✅ Photo analysis: ${data['status']}');
          return data;
        } catch (parseError) {
          print('❌ Photo analysis parse error: $parseError');
          return null;
        }
      } else {
        print('❌ Photo analysis API error: ${response.statusCode}');
        if (response.statusCode == 429) {
          throw Exception('API limit reached. Please try again later.');
        }
        return null;
      }
    } catch (e) {
      print('❌ Photo analysis error: $e');
      if (e.toString().contains('API limit reached')) throw e;
      return null;
    }
  }

  /// General chat response method
  Future<String> getChatResponse({
    required String prompt,
    String? systemInstruction,
    List<Map<String, dynamic>> history = const [],
  }) async {
    final String urlString =
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey';
    final Uri url = Uri.parse(urlString);

    final List<Map<String, dynamic>> contents = [];
    for (var msg in history) {
      contents.add(msg);
    }
    contents.add({
      "role": "user",
      "parts": [
        {"text": prompt},
      ],
    });

    final Map<String, dynamic> requestBody = {
      "contents": contents,
      "generationConfig": {
        "temperature": 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": 1024,
      },
    };

    if (systemInstruction != null) {
      requestBody["system_instruction"] = {
        "parts": [
          {"text": systemInstruction},
        ],
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
            "I couldn't generate a response.";
      } else {
        return "Error ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "Connection error: $e";
    }
  }

  static const String _model = 'gemini-2.5-flash';

  /// Translate analysis text to a target language using Gemini AI
  Future<String?> translateText({
    required String text,
    required String targetLanguageCode,
  }) async {
    if (_isInQuotaCooldown) return null;

    final String langName = _languageName(targetLanguageCode);
    final String urlString =
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey';

    final Uri url = Uri.parse(urlString);

    final String prompt =
        '''Translate the following agricultural diagnosis report into $langName.

Rules:
- Keep the EXACT same Markdown formatting (bold labels with **, bullet points, line breaks).
- Translate the label names too (e.g., "Pest Name" → the equivalent in $langName).
- Do NOT add any extra commentary or explanation.
- Return ONLY the translated text.

Original text:
$text''';

    final requestBody = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      "generationConfig": {"temperature": 0.3, "maxOutputTokens": 8192},
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['candidates']?[0]?['content']?['parts']?[0]?['text'];
      } else {
        if (response.statusCode == 429) {
          _startQuotaCooldownFromBody(response.body);
        }
        print('Translation API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Translation error: $e');
      return null;
    }
  }
}
