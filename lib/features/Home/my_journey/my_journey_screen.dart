import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kita_agro/core/services/gemini_api_service.dart';
import 'package:kita_agro/core/services/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyJourneyScreen extends StatefulWidget {
  const MyJourneyScreen({super.key});

  @override
  State<MyJourneyScreen> createState() => _MyJourneyScreenState();
}

class _MyJourneyScreenState extends State<MyJourneyScreen> {
  static const String _googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  final GeminiApiService _geminiApi = GeminiApiService(
    dotenv.env['GEMINI_API_KEY_DICTIONARY_AND_JOURNEY'] ?? '',
  );

  String _sortBy = 'newest'; // 'newest', 'name', 'daysPlanted', 'health'
  bool _gardenLocationLoading = false;
  String? _gardenAddress;
  double? _gardenLatitude;
  double? _gardenLongitude;
  String? _gardenPlaceId;

  // Expandable task dropdown state
  String? _expandedPlantId;
  final Map<String, List<Map<String, String>>> _plantTasks = {};
  final ValueNotifier<Map<String, Set<int>>> _completedTasksNotifier =
      ValueNotifier({});
  final Map<String, bool> _taskLoading = {};
  // Cache key: plantId + date string to avoid re-fetching same day
  final Map<String, String> _taskCacheDate = {};

  // Helper getter for backward compatibility
  Map<String, Set<int>> get _completedTasks => _completedTasksNotifier.value;

  // Photo analysis state
  final ImagePicker _imagePicker = ImagePicker();
  final Map<String, Map<String, dynamic>> _photoAnalysis = {};
  final Map<String, bool> _photoAnalyzing = {};

  // Photo timeline state: plantId -> list of {url, day, date, status, diagnosis}
  final Map<String, List<Map<String, dynamic>>> _photoTimeline = {};

  static const Map<String, int> _plantDetailDays = {
    'Tomato': 100,
    'Chili': 120,
    'Papaya': 330,
    'Banana': 360,
    'Strawberry': 120,
    'Apple': 1825,
    'Pandan': 180,
  };

  @override
  void initState() {
    super.initState();
    _loadGardenLocation();
    _loadCompletedTasks();
    _backfillPlantingDates();
    _backfillLatestPhotoStatus();
    _backfillPlantTotalDays();
    _backfillCarbonReduction();
    // Preload tasks for all plants after a short delay
    Future.delayed(const Duration(milliseconds: 500), _preloadAllTasks);
  }

  @override
  void dispose() {
    _completedTasksNotifier.dispose();
    super.dispose();
  }

  Future<void> _backfillLatestPhotoStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final plantations = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .get();

      for (final plantDoc in plantations.docs) {
        final data = plantDoc.data();
        final latestStatus = (data['latestPhotoStatus'] as String?)?.trim();
        if (latestStatus != null && latestStatus.isNotEmpty) {
          continue;
        }

        final photoSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('plantations')
            .doc(plantDoc.id)
            .collection('photos')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (photoSnap.docs.isEmpty) continue;

        final latestPhoto = photoSnap.docs.first.data();
        final status = (latestPhoto['status'] as String?) ?? 'Unknown';
        final diagnosis = (latestPhoto['diagnosis'] as String?) ?? '';
        final date = (latestPhoto['date'] as String?) ?? _todayKey;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('plantations')
            .doc(plantDoc.id)
            .set({
              'latestPhotoStatus': status,
              'latestPhotoDiagnosis': diagnosis,
              'latestPhotoDate': date,
            }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error backfilling latest photo status: $e');
    }
  }

  Future<void> _backfillPlantTotalDays() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final plantationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations');

      final snapshot = await plantationsRef.get();
      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] as String?)?.trim() ?? 'Unnamed Plant';
        final storedTotalDays = (data['totalDays'] as num?)?.toInt() ?? 0;
        final resolvedTotalDays = _resolvePlantTotalDays(
          name: name,
          storedTotalDays: storedTotalDays,
        );

        if (resolvedTotalDays != storedTotalDays) {
          batch.set(doc.reference, {
            'totalDays': resolvedTotalDays,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        print('✅ Backfilled totalDays for $updatedCount plant(s)');
      }
    } catch (e) {
      print('Error backfilling plant totalDays: $e');
    }
  }

  Future<void> _backfillCarbonReduction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final plantationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations');

      final snapshot = await plantationsRef.get();
      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final existingCarbon = data['carbonReduction'];

        // Skip if carbonReduction already exists
        if (existingCarbon != null) continue;

        final name = (data['name'] as String?)?.trim() ?? 'Unnamed Plant';
        final category = (data['category'] as String?)?.trim() ?? 'Unknown';
        final totalDays = (data['totalDays'] as num?)?.toInt() ?? 90;

        final carbonReduction = _estimateCarbonReduction(
          name,
          category,
          totalDays,
        );

        batch.set(doc.reference, {
          'carbonReduction': carbonReduction,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        updatedCount++;
      }

      if (updatedCount > 0) {
        await batch.commit();
        print('✅ Backfilled carbonReduction for $updatedCount plant(s)');
      }
    } catch (e) {
      print('Error backfilling carbonReduction: $e');
    }
  }

  Future<void> _backfillPlantingDates() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final plantationsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations');

      final snapshot = await plantationsRef.get();
      final batch = FirebaseFirestore.instance.batch();
      int updatedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final plantedAt = data['plantedAt'];
        final storedDays = (data['daysPlanted'] as num?)?.toInt() ?? 0;

        Timestamp resolvedPlantedAt;
        if (plantedAt is Timestamp) {
          resolvedPlantedAt = plantedAt;
        } else {
          final safeDays = storedDays < 0 ? 0 : storedDays;
          final inferredDate = DateTime.now().subtract(
            Duration(days: safeDays),
          );
          resolvedPlantedAt = Timestamp.fromDate(
            DateTime(inferredDate.year, inferredDate.month, inferredDate.day),
          );
        }

        final syncedDays =
            (DateTime.now().difference(resolvedPlantedAt.toDate()).inDays + 1)
                .clamp(1, 99999);

        final needsPlantedAt = plantedAt is! Timestamp;
        final needsDaysSync = syncedDays != storedDays;
        if (!needsPlantedAt && !needsDaysSync) {
          continue;
        }

        batch.set(doc.reference, {
          'plantedAt': resolvedPlantedAt,
          'daysPlanted': syncedDays,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        updatedCount++;
      }

      if (updatedCount > 0) {
        await batch.commit();
        print('✅ Backfilled planting dates for $updatedCount plant(s)');
      }
    } catch (e) {
      print('Error backfilling planting dates: $e');
    }
  }

  /// Estimate annual carbon reduction in kg CO2 per year based on plant type
  double _estimateCarbonReduction(String name, String category, int totalDays) {
    final nameLower = name.toLowerCase();

    // Trees absorb the most CO2
    if (nameLower.contains('apple') || nameLower.contains('tree')) {
      return 25.0; // Large trees: ~25kg CO2/year
    }

    // Medium plants
    if (nameLower.contains('papaya') || nameLower.contains('banana')) {
      return 12.0; // Medium plants: ~12kg CO2/year
    }

    // Vegetables and herbs based on category
    switch (category.toLowerCase()) {
      case 'vegetable':
        return 2.5; // Small vegetables: ~2.5kg CO2/year
      case 'herb':
        return 1.5; // Herbs: ~1.5kg CO2/year
      case 'fruit':
        return 5.0; // Fruit plants: ~5kg CO2/year
      default:
        return 3.0; // Default: ~3kg CO2/year
    }
  }

  DocumentReference<Map<String, dynamic>>? _userDocRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check if cached tasks are still valid (same date)
  /// Tasks automatically refresh at midnight when _todayKey changes
  bool _areTasksValidForToday(String plantId) {
    return _taskCacheDate[plantId] == _todayKey &&
        _plantTasks.containsKey(plantId);
  }

  /// Load completed tasks from Firestore for today
  Future<void> _loadCompletedTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final todayTasks = data['dailyTasks'] as Map<String, dynamic>?;
        if (todayTasks != null) {
          final todayData = todayTasks[_todayKey] as Map<String, dynamic>?;
          if (todayData != null) {
            final completed = (todayData['completed'] as List<dynamic>?) ?? [];
            final completedSet = completed.map<int>((e) => e as int).toSet();
            final current = _completedTasksNotifier.value;
            current[doc.id] = completedSet;
            _completedTasksNotifier.value = Map.from(current);

            // Also restore cached tasks if available
            final cachedTasks = (todayData['tasks'] as List<dynamic>?);
            if (cachedTasks != null) {
              _plantTasks[doc.id] = cachedTasks
                  .map<Map<String, String>>(
                    (t) => {
                      'task': (t['task'] as String?) ?? '',
                      'icon': (t['icon'] as String?) ?? 'inspect',
                    },
                  )
                  .toList();
              _taskCacheDate[doc.id] = _todayKey;
            }
          }
        }
      }
    } catch (e) {
      print('Error loading completed tasks: $e');
    }
  }

  /// Preload daily tasks for all plants to avoid lazy loading
  Future<void> _preloadAllTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .get();

      final weather = await _getWeatherData();
      final location = _gardenAddress ?? 'Malaysia';
      final temp = weather['temperature'] as double;
      final condition = weather['condition'] as String;

      for (final doc in snapshot.docs) {
        final plantId = doc.id;

        // Skip if already have today's tasks
        if (_areTasksValidForToday(plantId)) {
          continue;
        }

        final data = doc.data();
        final plantName = data['name'] as String? ?? 'Plant';
        final rawTotalDays = (data['totalDays'] as num?)?.toInt() ?? 0;
        final totalDays = _resolvePlantTotalDays(
          name: plantName,
          storedTotalDays: rawTotalDays,
        );
        final plant = {
          'name': plantName,
          'scientificName': data['scientificName'] as String? ?? '',
          'category': data['category'] as String? ?? 'Unknown',
          'daysPlanted': (data['daysPlanted'] as num?)?.toInt() ?? 0,
          'totalDays': totalDays,
        };

        try {
          final langCode = mounted
              ? LanguageServiceProvider.of(context).currentLanguage.code
              : 'en';
          final tasks = await _geminiApi.generateDailyTasks(
            plantName: plant['name'] as String,
            scientificName: plant['scientificName'] as String,
            category: plant['category'] as String,
            daysPlanted: plant['daysPlanted'] as int,
            totalDays: plant['totalDays'] as int,
            location: location,
            temperature: temp,
            weatherCondition: condition,
            languageCode: langCode,
          );

          if (tasks != null && tasks.isNotEmpty) {
            _plantTasks[plantId] = tasks;
            _taskCacheDate[plantId] = _todayKey;

            // Initialize completed set if absent
            final current = _completedTasksNotifier.value;
            current.putIfAbsent(plantId, () => <int>{});
            _completedTasksNotifier.value = Map.from(current);

            // Persist to Firestore
            await _saveTasksToFirestore(plantId, tasks);
          }
        } catch (e) {
          print('Error preloading tasks for $plantId: $e');
        }
      }

      if (mounted) setState(() {}); // Single rebuild after all tasks loaded
    } catch (e) {
      print('Error in preloadAllTasks: $e');
    }
  }

  /// Take a photo or pick from gallery and analyze the plant condition
  Future<void> _takePhotoAndAnalyze(Map<String, dynamic> plant) async {
    final plantId = plant['id'] as String;

    // Show bottom sheet to choose camera or gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.of(context).analyzePhotoTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                title: Text(AppLocalizations.of(context).takePhoto),
                subtitle: Text(AppLocalizations.of(context).useCameraCapture),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF2E7D32),
                ),
                title: Text(AppLocalizations.of(context).chooseFromGallery),
                subtitle: Text(
                  AppLocalizations.of(context).uploadExistingPhoto,
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return; // User cancelled

    final XFile? image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1024,
    );

    if (image == null) return; // User cancelled

    // Ensure plant is expanded
    if (_expandedPlantId != plantId) {
      setState(() => _expandedPlantId = plantId);
    }

    setState(() => _photoAnalyzing[plantId] = true);

    try {
      final langCode = LanguageServiceProvider.of(context).currentLanguage.code;
      final result = await _geminiApi.analyzeAndSuggestTasks(
        imagePath: image.path,
        plantName: plant['name'] as String,
        daysPlanted: plant['daysPlanted'] as int,
        totalDays: plant['totalDays'] as int,
        languageCode: langCode,
      );

      if (!mounted) return;

      if (result != null) {
        // Show result immediately (don't wait for upload)
        setState(() {
          _photoAnalysis[plantId] = result;
          _photoAnalyzing[plantId] = false;
        });

        // Upload photo in the background (non-blocking)
        _uploadAndSavePhoto(
          plantId: plantId,
          imagePath: image.path,
          daysPlanted: plant['daysPlanted'] as int,
          status: (result['status'] as String?) ?? 'Unknown',
          diagnosis: (result['diagnosis'] as String?) ?? '',
        );
      } else {
        setState(() => _photoAnalyzing[plantId] = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).couldNotAnalyze),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _photoAnalyzing[plantId] = false);

        final errorMessage = e.toString().contains('API limit reached')
            ? AppLocalizations.of(context).apiLimitReached
            : 'Analysis error: $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Build the analysis result card
  Widget _buildAnalysisCard(Map<String, dynamic> analysis) {
    final status = (analysis['status'] as String?) ?? 'Unknown';
    final diagnosis = (analysis['diagnosis'] as String?) ?? '';

    Color statusColor;
    IconData statusIcon;
    if (status.toLowerCase().contains('healthy')) {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle;
    } else if (status.toLowerCase().contains('critical')) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.08),
              statusColor.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).photoAnalysis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (diagnosis.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                diagnosis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[800],
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Upload photo to Firebase Storage and save metadata to Firestore
  Future<void> _uploadAndSavePhoto({
    required String plantId,
    required String imagePath,
    required int daysPlanted,
    required String status,
    required String diagnosis,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final safeDay = daysPlanted < 1 ? 1 : daysPlanted;

    // Immediately add to local cache with local file path so gallery works right away
    _photoTimeline.putIfAbsent(plantId, () => []);
    final localEntry = {
      'url': imagePath, // Use local path first
      'day': safeDay,
      'date': _todayKey,
      'status': status,
      'diagnosis': diagnosis,
      'isLocal': true,
    };
    _photoTimeline[plantId]!.add(localEntry);
    _photoTimeline[plantId]!.sort(
      (a, b) => (a['day'] as int).compareTo(b['day'] as int),
    );

    try {
      final file = File(imagePath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'users/${user.uid}/plants/$plantId/photos/$timestamp.jpg';

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Save metadata to Firestore
      final photoData = {
        'url': downloadUrl,
        'day': safeDay,
        'date': _todayKey,
        'timestamp': FieldValue.serverTimestamp(),
        'status': status,
        'diagnosis': diagnosis,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .doc(plantId)
          .collection('photos')
          .add(photoData);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .doc(plantId)
          .set({
            'latestPhotoStatus': status,
            'latestPhotoDiagnosis': diagnosis,
            'latestPhotoDate': _todayKey,
          }, SetOptions(merge: true));

      // Update the local entry with the remote URL
      localEntry['url'] = downloadUrl;
      localEntry['isLocal'] = false;

      print('\u2705 Photo saved: day $safeDay, $status');
    } catch (e) {
      print('\u274c Photo upload error: $e');
    }
  }

  /// Restore the latest photo analysis from Firestore (so it persists across restarts)
  Future<void> _restoreLatestAnalysis(String plantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .doc(plantId)
          .collection('photos')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      final data = snapshot.docs.first.data();
      final status = data['status'] as String? ?? 'Unknown';
      final diagnosis = data['diagnosis'] as String? ?? '';

      if (mounted) {
        setState(() {
          _photoAnalysis[plantId] = {
            'status': status,
            'diagnosis': diagnosis,
            'tasks': <Map<String, dynamic>>[],
          };
        });
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .doc(plantId)
          .set({
            'latestPhotoStatus': status,
            'latestPhotoDiagnosis': diagnosis,
            'latestPhotoDate': data['date'] as String? ?? _todayKey,
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error restoring analysis: $e');
    }
  }

  /// Load photo timeline for a plant
  Future<List<Map<String, dynamic>>> _loadPhotoTimeline(String plantId) async {
    // Return cached if available (includes photos just taken but not yet synced)
    if (_photoTimeline.containsKey(plantId) &&
        _photoTimeline[plantId]!.isNotEmpty) {
      return _photoTimeline[plantId]!;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .doc(plantId)
          .collection('photos')
          .orderBy('day')
          .get();

      final photos = snapshot.docs.map((doc) {
        final data = doc.data();
        final storedDay = (data['day'] as int?) ?? 1;
        return {
          'url': data['url'] as String? ?? '',
          'day': storedDay < 1 ? 1 : storedDay,
          'date': data['date'] as String? ?? '',
          'status': data['status'] as String? ?? 'Unknown',
          'diagnosis': data['diagnosis'] as String? ?? '',
        };
      }).toList();

      _photoTimeline[plantId] = photos;
      return photos;
    } catch (e) {
      // If orderBy query fails (missing index), try without ordering
      print('Error loading photo timeline: $e');
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('plantations')
            .doc(plantId)
            .collection('photos')
            .get();

        final photos = snapshot.docs.map((doc) {
          final data = doc.data();
          final storedDay = (data['day'] as int?) ?? 1;
          return {
            'url': data['url'] as String? ?? '',
            'day': storedDay < 1 ? 1 : storedDay,
            'date': data['date'] as String? ?? '',
            'status': data['status'] as String? ?? 'Unknown',
            'diagnosis': data['diagnosis'] as String? ?? '',
          };
        }).toList();

        photos.sort((a, b) => (a['day'] as int).compareTo(b['day'] as int));
        _photoTimeline[plantId] = photos;
        return photos;
      } catch (e2) {
        print('Fallback photo load also failed: $e2');
        return [];
      }
    }
  }

  /// Open photo timeline gallery
  void _openPhotoTimeline(Map<String, dynamic> plant) async {
    final plantId = plant['id'] as String;
    final photos = await _loadPhotoTimeline(plantId);

    if (!mounted) return;

    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photos yet. Take a photo to start your timeline!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoTimelineScreen(
          plantName: plant['name'] as String,
          totalDays: plant['totalDays'] as int,
          photos: photos,
        ),
      ),
    );
  }

  /// Fetch weather data using Open-Meteo (same as dictionary)
  Future<Map<String, dynamic>> _getWeatherData() async {
    if (_gardenLatitude == null || _gardenLongitude == null) {
      return {'temperature': 30.0, 'condition': 'Unknown'};
    }
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$_gardenLatitude&longitude=$_gardenLongitude&current_weather=true',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        return {
          'temperature': (current['temperature'] as num).toDouble(),
          'condition': _weatherCodeToString(current['weathercode'] as int),
        };
      }
    } catch (_) {}
    return {'temperature': 30.0, 'condition': 'Unknown'};
  }

  String _weatherCodeToString(int code) {
    if (code == 0) return 'Clear sky';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Toggle expand on a plant block — load AI tasks if needed
  Future<void> _togglePlantExpand(Map<String, dynamic> plant) async {
    final plantId = plant['id'] as String;

    // Collapse if already expanded
    if (_expandedPlantId == plantId) {
      setState(() => _expandedPlantId = null);
      return;
    }

    // Expand this plant
    setState(() => _expandedPlantId = plantId);

    // Restore latest photo analysis from Firestore if not in memory
    if (!_photoAnalysis.containsKey(plantId)) {
      _restoreLatestAnalysis(plantId);
    }

    // Already have today's tasks cached (refreshes only at midnight when date changes)
    if (_areTasksValidForToday(plantId)) {
      return;
    }

    // Load tasks
    setState(() => _taskLoading[plantId] = true);

    try {
      final weather = await _getWeatherData();
      final location = _gardenAddress ?? 'Malaysia';
      final temp = weather['temperature'] as double;
      final condition = weather['condition'] as String;

      final langCode = LanguageServiceProvider.of(context).currentLanguage.code;
      final tasks = await _geminiApi.generateDailyTasks(
        plantName: plant['name'] as String,
        scientificName: plant['scientificName'] as String,
        category: plant['category'] as String,
        daysPlanted: plant['daysPlanted'] as int,
        totalDays: plant['totalDays'] as int,
        location: location,
        temperature: temp,
        weatherCondition: condition,
        languageCode: langCode,
      );

      if (!mounted) return;

      if (tasks != null && tasks.isNotEmpty) {
        _plantTasks[plantId] = tasks;
        _taskCacheDate[plantId] = _todayKey;
        // Initialize completed set if absent
        final current = _completedTasksNotifier.value;
        current.putIfAbsent(plantId, () => <int>{});
        _completedTasksNotifier.value = Map.from(current);

        // Persist generated tasks to Firestore
        _saveTasksToFirestore(plantId, tasks);
      }
    } catch (e) {
      print('Error loading tasks: $e');
      if (mounted) {
        if (e.toString().contains('API limit reached')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API limit reached. Please try again later.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _taskLoading[plantId] = false);
    }
  }

  /// Save tasks and completed state to Firestore
  Future<void> _saveTasksToFirestore(
    String plantId,
    List<Map<String, String>> tasks,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .doc(plantId)
          .set({
            'dailyTasks': {
              _todayKey: {
                'tasks': tasks,
                'completed': (_completedTasksNotifier.value[plantId] ?? <int>{})
                    .toList(),
              },
            },
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  /// Toggle task completion and persist
  void _toggleTaskCompletion(String plantId, int taskIndex) {
    // Update using ValueNotifier to avoid full page rebuild
    final current = Map<String, Set<int>>.from(_completedTasksNotifier.value);
    current.putIfAbsent(plantId, () => <int>{});

    if (current[plantId]!.contains(taskIndex)) {
      current[plantId]!.remove(taskIndex);
    } else {
      current[plantId]!.add(taskIndex);
    }

    _completedTasksNotifier.value = current;

    // Persist to Firestore (async, non-blocking)
    final tasks = _plantTasks[plantId];
    if (tasks != null) {
      _saveTasksToFirestore(plantId, tasks);
    }
  }

  IconData _taskIconFromString(String icon) {
    switch (icon) {
      case 'water':
        return Icons.water_drop;
      case 'sun':
        return Icons.wb_sunny;
      case 'fertilizer':
        return Icons.science;
      case 'prune':
        return Icons.content_cut;
      case 'inspect':
        return Icons.search;
      case 'harvest':
        return Icons.agriculture;
      case 'protect':
        return Icons.shield;
      case 'soil':
        return Icons.terrain;
      default:
        return Icons.task_alt;
    }
  }

  Color _taskIconColor(String icon) {
    switch (icon) {
      case 'water':
        return Colors.blue;
      case 'sun':
        return Colors.orange;
      case 'fertilizer':
        return Colors.brown;
      case 'prune':
        return Colors.purple;
      case 'inspect':
        return Colors.teal;
      case 'harvest':
        return Colors.amber[700]!;
      case 'protect':
        return Colors.red;
      case 'soil':
        return Colors.brown[400]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadGardenLocation() async {
    final userDocRef = _userDocRef();
    if (userDocRef == null) {
      return;
    }

    setState(() {
      _gardenLocationLoading = true;
    });

    try {
      final snapshot = await userDocRef.get();
      final data = snapshot.data();
      final location = data?['gardenLocation'] as Map<String, dynamic>?;

      if (!mounted) {
        return;
      }

      if (location != null) {
        setState(() {
          _gardenAddress = location['address'] as String?;
          _gardenLatitude = (location['latitude'] as num?)?.toDouble();
          _gardenLongitude = (location['longitude'] as num?)?.toDouble();
          _gardenPlaceId = location['placeId'] as String?;
          _gardenLocationLoading = false;
        });
      } else {
        setState(() {
          _gardenAddress = null;
          _gardenLatitude = null;
          _gardenLongitude = null;
          _gardenPlaceId = null;
          _gardenLocationLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _gardenLocationLoading = false;
      });
    }
  }

  Future<void> _setGardenLocation() async {
    final userDocRef = _userDocRef();
    if (userDocRef == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to save garden location.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final result = await Navigator.push<_GardenLocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => _GardenLocationPickerScreen(
          apiKey: _googleMapsApiKey,
          initialLatitude: _gardenLatitude,
          initialLongitude: _gardenLongitude,
          initialAddress: _gardenAddress,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _gardenLocationLoading = true;
    });

    try {
      await userDocRef.set({
        'gardenLocation': {
          'latitude': result.latitude,
          'longitude': result.longitude,
          'address': result.address,
          'placeId': result.placeId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }

      setState(() {
        _gardenLatitude = result.latitude;
        _gardenLongitude = result.longitude;
        _gardenAddress = result.address;
        _gardenPlaceId = result.placeId;
        _gardenLocationLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Garden location saved successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _gardenLocationLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save garden location: $error'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildGardenLocationCard() {
    final hasLocation = _gardenLatitude != null && _gardenLongitude != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).myGardenLocation,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              if (_gardenLocationLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasLocation
                ? (_gardenAddress ??
                      'Lat: ${_gardenLatitude!.toStringAsFixed(5)}, Lng: ${_gardenLongitude!.toStringAsFixed(5)}')
                : 'Set your garden location to get localized suggestions and weather context.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          if (hasLocation) ...[
            const SizedBox(height: 6),
            Text(
              'Lat: ${_gardenLatitude!.toStringAsFixed(5)}, Lng: ${_gardenLongitude!.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _gardenLocationLoading ? null : _setGardenLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit_location_alt),
                label: Text(
                  hasLocation
                      ? AppLocalizations.of(context).editLocation
                      : AppLocalizations.of(context).setLocation,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _gardenPlantStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plantations')
        .snapshots()
        .map((snapshot) {
          final plants = snapshot.docs
              .map((doc) => _mapGardenPlant(doc))
              .toList();
          // Sort based on selected criteria
          switch (_sortBy) {
            case 'newest':
              plants.sort((a, b) {
                final aPlantedAt = a['plantedAt'] as Timestamp?;
                final bPlantedAt = b['plantedAt'] as Timestamp?;

                if (aPlantedAt != null && bPlantedAt != null) {
                  return bPlantedAt.compareTo(aPlantedAt);
                }
                if (aPlantedAt != null) return -1;
                if (bPlantedAt != null) return 1;

                final aDays = (a['daysPlanted'] as int?) ?? 0;
                final bDays = (b['daysPlanted'] as int?) ?? 0;
                return aDays.compareTo(bDays);
              });
              break;
            case 'daysPlanted':
              plants.sort(
                (a, b) => (b['daysPlanted'] as int).compareTo(
                  a['daysPlanted'] as int,
                ),
              );
              break;
            case 'health':
              plants.sort((a, b) {
                final aHealth = _calculateHealth(a);
                final bHealth = _calculateHealth(b);
                return bHealth.compareTo(aHealth);
              });
              break;
            case 'name':
            default:
              plants.sort(
                (a, b) => (a['name'] as String).compareTo(b['name'] as String),
              );
          }
          return plants;
        });
  }

  Map<String, dynamic> _mapGardenPlant(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = (data['name'] as String?) ?? 'Unnamed Plant';
    final scientificName = (data['scientificName'] as String?) ?? '';
    final category = (data['category'] as String?) ?? 'Unknown';
    final storedTotalDays = (data['totalDays'] as num?)?.toInt() ?? 0;
    final totalDays = _resolvePlantTotalDays(
      name: name,
      storedTotalDays: storedTotalDays,
    );
    final daysPlanted = (data['daysPlanted'] as num?)?.toInt() ?? 0;
    final plantedAt = data['plantedAt'] as Timestamp?;
    final latestPhotoStatus = (data['latestPhotoStatus'] as String?) ?? '';
    final iconName = (data['icon'] as String?) ?? 'spa';
    final colorValue = (data['color'] as int?) ?? 0xFF4CAF50;

    int actualDaysPlanted = daysPlanted;
    if (plantedAt != null) {
      actualDaysPlanted =
          DateTime.now().difference(plantedAt.toDate()).inDays + 1;
    }
    if (actualDaysPlanted < 1) {
      actualDaysPlanted = 1;
    }

    return {
      'id': doc.id,
      'name': name,
      'scientificName': scientificName,
      'category': category,
      'totalDays': totalDays,
      'daysPlanted': actualDaysPlanted,
      'plantedAt': plantedAt,
      'latestPhotoStatus': latestPhotoStatus,
      'icon': _iconFromName(iconName),
      'color': _parseColor(colorValue),
    };
  }

  int _resolvePlantTotalDays({
    required String name,
    required int storedTotalDays,
  }) {
    final detailDays = _plantDetailDays[name];

    if (storedTotalDays <= 0) {
      return detailDays ?? 60;
    }

    if (storedTotalDays == 90 && detailDays != null && detailDays != 90) {
      return detailDays;
    }

    return storedTotalDays;
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'circle':
        return Icons.circle;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'spa':
        return Icons.spa;
      case 'nature':
        return Icons.nature;
      case 'grass':
        return Icons.grass;
      default:
        return Icons.spa;
    }
  }

  Color _parseColor(dynamic value) {
    if (value is int) {
      return Color(value);
    }
    if (value is String && value.startsWith('0x')) {
      return Color(int.parse(value));
    }
    if (value is String && value.startsWith('#')) {
      return Color(int.parse(value.replaceFirst('#', '0xff')));
    }
    return const Color(0xFF4CAF50);
  }

  int _healthFromStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('healthy')) return 90;
    if (normalized.contains('critical')) return 20;
    if (normalized.contains('attention') || normalized.contains('warning'))
      return 55;
    if (normalized.contains('unknown')) return 50;
    return 60;
  }

  String _localizeLabel(String key) {
    if (!mounted) return key;
    final loc = AppLocalizations.of(context);
    switch (key) {
      case 'All':
        return loc.all;
      case 'Vegetables':
        return loc.vegetables;
      case 'Fruits':
        return loc.fruits;
      case 'Herbs':
        return loc.herbs;
      default:
        return key;
    }
  }

  int _calculateHealth(Map<String, dynamic> plant) {
    final latestStatus = (plant['latestPhotoStatus'] as String?)?.trim();
    if (latestStatus != null && latestStatus.isNotEmpty) {
      return _healthFromStatus(latestStatus);
    }

    final plantId = plant['id'] as String;
    final cachedStatus = (_photoAnalysis[plantId]?['status'] as String?)
        ?.trim();
    if (cachedStatus != null && cachedStatus.isNotEmpty) {
      return _healthFromStatus(cachedStatus);
    }

    return 50;
  }

  String _getHealthStatus(int health) {
    final loc = AppLocalizations.of(context);
    if (health >= 85) return loc.healthy;
    if (health >= 65) return loc.stable;
    if (health >= 40) return loc.needsAttention;
    return loc.critical;
  }

  Color _getHealthColor(int health) {
    if (health >= 85) return const Color(0xFF2E7D32);
    if (health >= 65) return Colors.lightGreen;
    if (health >= 40) return Colors.orange;
    return Colors.red;
  }

  double _calculateGrowthProgress(Map<String, dynamic> plant) {
    final daysPlanted = plant['daysPlanted'] as int;
    final totalDays = plant['totalDays'] as int;
    if (totalDays <= 0) return 0;
    return (daysPlanted / totalDays).clamp(0.0, 1.0);
  }

  Future<void> _deletePlant(String plantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('plantations')
          .doc(plantId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plant removed from your garden'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting plant: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).deletePlantTitle),
        content: Text(
          AppLocalizations.of(context).removePlantConfirmation(
            AppLocalizations.of(
              context,
            ).getLocalizedPlantName(plant['name'] as String),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlant(plant['id'] as String);
            },
            child: Text(
              AppLocalizations.of(context).delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).myJourney,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildGardenLocationCard(),
          // Sort options
          Container(
            color: Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortButton(
                    AppLocalizations.of(context).newest,
                    'newest',
                  ),
                  const SizedBox(width: 8),
                  _buildSortButton(AppLocalizations.of(context).name, 'name'),
                  const SizedBox(width: 8),
                  _buildSortButton(
                    AppLocalizations.of(context).daysPlantedLabel,
                    'daysPlanted',
                  ),
                  const SizedBox(width: 8),
                  _buildSortButton(
                    AppLocalizations.of(context).health,
                    'health',
                  ),
                ],
              ),
            ),
          ),
          // Plant list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _gardenPlantStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context).errorLoadingGarden),
                      ],
                    ),
                  );
                }

                final plants = snapshot.data ?? [];

                if (plants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.grass, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context).gardenEmpty,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).addPlantsToStart,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plants.length,
                  itemBuilder: (context, index) {
                    final plant = plants[index];
                    return _buildPlantListItem(plant);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Color(0xFF2E7D32) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPlantListItem(Map<String, dynamic> plant) {
    final health = _calculateHealth(plant);
    final growthProgress = _calculateGrowthProgress(plant);
    final growthPercent = (growthProgress * 100).round();
    final healthStatus = _getHealthStatus(health);
    final healthColor = _getHealthColor(health);
    final daysRemaining =
        (plant['totalDays'] as int) - (plant['daysPlanted'] as int);
    final plantId = plant['id'] as String;
    final latestPhotoStatus = (plant['latestPhotoStatus'] as String?)?.trim();
    final isExpanded = _expandedPlantId == plantId;
    final tasks = _plantTasks[plantId] ?? [];
    final isLoading = _taskLoading[plantId] == true;

    return GestureDetector(
      onTap: () => _togglePlantExpand(plant),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isExpanded ? const Color(0xFF2E7D32) : Colors.grey[300]!,
            width: isExpanded ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: isExpanded
                  ? const Color(0xFF2E7D32).withOpacity(0.15)
                  : (plant['color'] as Color).withOpacity(0.1),
              blurRadius: isExpanded ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Main plant info block ──
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and name
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: plant['color'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              plant['icon'] as IconData,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  ).getLocalizedPlantName(
                                    plant['name'] as String,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plant['scientificName'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _localizeLabel(plant['category'] as String),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Health status (based on latest uploaded photo)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            ).healthLabel(healthStatus),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: healthColor,
                            ),
                          ),
                          Text(
                            latestPhotoStatus?.isNotEmpty == true
                                ? latestPhotoStatus!
                                : AppLocalizations.of(context).noPhotoYet,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Health bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: health / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            healthColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Growth progress (based on plant details)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context).progress,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            '${plant['daysPlanted']} / ${plant['totalDays']} ${AppLocalizations.of(context).days} ($growthPercent%)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: growthProgress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2E7D32),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Days remaining + expand hint
                      Row(
                        children: [
                          if (daysRemaining > 0) ...[
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).daysUntilHarvest(daysRemaining),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context).readyToHarvest,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          // Task progress badge + chevron
                          ValueListenableBuilder<Map<String, Set<int>>>(
                            valueListenable: _completedTasksNotifier,
                            builder: (context, completedMap, _) {
                              final completed =
                                  completedMap[plantId] ?? <int>{};
                              final completedCount = completed.length;
                              final totalTasks = tasks.length;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (totalTasks > 0 && !isExpanded)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: completedCount == totalTasks
                                            ? const Color(0xFFE8F5E9)
                                            : Colors.orange[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context).tasksCount(
                                          completedCount,
                                          totalTasks,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: completedCount == totalTasks
                                              ? const Color(0xFF2E7D32)
                                              : Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                ],
                              );
                            },
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[500],
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Delete button - top right corner
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Gallery timeline button
                      GestureDetector(
                        onTap: () => _openPhotoTimeline(plant),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Icon(
                            Icons.photo_library,
                            color: Colors.green[600],
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Camera button
                      GestureDetector(
                        onTap: () => _takePhotoAndAnalyze(plant),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _photoAnalyzing[plantId] == true
                                ? Colors.blue[100]
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: _photoAnalyzing[plantId] == true
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.blue,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt,
                                  color: Colors.blue[600],
                                  size: 18,
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Delete button
                      GestureDetector(
                        onTap: () => _showDeleteConfirmation(plant),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red[600],
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Expandable AI Tasks Dropdown ──
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _buildTasksDropdown(plantId, tasks, isLoading),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksDropdown(
    String plantId,
    List<Map<String, String>> tasks,
    bool isLoading,
  ) {
    final analysis = _photoAnalysis[plantId];
    final isAnalyzing = _photoAnalyzing[plantId] == true;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(11),
          bottomRight: Radius.circular(11),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFC8E6C9)),

          // ── Photo Analysis Result (if available) ──
          if (isAnalyzing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Analyzing photo...',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ),

          if (analysis != null) ...[
            _buildAnalysisCard(analysis),
            // Photo-based tasks
            if (analysis['tasks'] != null &&
                (analysis['tasks'] as List).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Icon(Icons.camera_alt, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Photo-Based Tasks',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate((analysis['tasks'] as List).length, (index) {
                final task = analysis['tasks'][index] as Map<String, dynamic>;
                final taskStr = (task['task'] as String?) ?? '';
                final iconStr = (task['icon'] as String?) ?? 'inspect';
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 3,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _taskIconFromString(iconStr),
                        size: 16,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          taskStr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Colors.blue[300],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ],

          // ── Standard AI Tasks header ──
          ValueListenableBuilder<Map<String, Set<int>>>(
            valueListenable: _completedTasksNotifier,
            builder: (context, completedMap, _) {
              final completed = completedMap[plantId] ?? <int>{};
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Today's AI Tasks",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const Spacer(),
                    if (tasks.isNotEmpty)
                      Text(
                        '${completed.length}/${tasks.length} done',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: completed.length == tasks.length
                              ? const Color(0xFF2E7D32)
                              : Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generating tasks...',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Could not load tasks. Tap to retry.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ),
            )
          else
            ValueListenableBuilder<Map<String, Set<int>>>(
              valueListenable: _completedTasksNotifier,
              builder: (context, completedMap, _) {
                final completed = completedMap[plantId] ?? <int>{};
                return Column(
                  children: List.generate(tasks.length, (index) {
                    final task = tasks[index];
                    final isDone = completed.contains(index);
                    final iconStr = task['icon'] ?? 'inspect';
                    return GestureDetector(
                      onTap: () => _toggleTaskCompletion(plantId, index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFFA5D6A7)
                                : Colors.grey[200]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? const Color(0xFF2E7D32)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDone
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            // Task icon
                            Icon(
                              _taskIconFromString(iconStr),
                              size: 18,
                              color: isDone
                                  ? Colors.grey[400]
                                  : _taskIconColor(iconStr),
                            ),
                            const SizedBox(width: 10),
                            // Task text
                            Expanded(
                              child: Text(
                                task['task'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDone
                                      ? Colors.grey[400]
                                      : Colors.grey[800],
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: isDone
                                      ? FontWeight.normal
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Full-screen photo timeline viewer
class _PhotoTimelineScreen extends StatelessWidget {
  const _PhotoTimelineScreen({
    required this.plantName,
    required this.totalDays,
    required this.photos,
  });

  final String plantName;
  final int totalDays;
  final List<Map<String, dynamic>> photos;

  Color _statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('healthy')) return const Color(0xFF2E7D32);
    if (lower.contains('critical')) return Colors.red;
    return Colors.orange;
  }

  IconData _statusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('healthy')) return Icons.check_circle;
    if (lower.contains('critical')) return Icons.error;
    return Icons.warning_amber_rounded;
  }

  /// Build image widget that handles both local files and network URLs
  Widget _buildImage(Map<String, dynamic> photo, {BoxFit fit = BoxFit.cover}) {
    final url = photo['url'] as String;
    final isLocal = photo['isLocal'] == true;

    if (isLocal) {
      return Image.file(
        File(url),
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${photos.length} photos · $totalDays day journey',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          final day = photo['day'] as int;
          final date = photo['date'] as String;
          final status = photo['status'] as String;
          final diagnosis = photo['diagnosis'] as String;
          final url = photo['url'] as String;
          final color = _statusColor(status);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timeline rail ──
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    if (index > 0)
                      Container(width: 2, height: 16, color: Colors.grey[300]),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'D$day',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    if (index < photos.length - 1)
                      Container(width: 2, height: 16, color: Colors.grey[300]),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ── Photo card ──
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _openFullImage(context, photo, day, status, diagnosis),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: _buildImage(photo),
                          ),
                        ),
                        // Info
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(_statusIcon(status), size: 16, color: color),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                date,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (diagnosis.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Text(
                              diagnosis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                height: 1.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openFullImage(
    BuildContext context,
    Map<String, dynamic> photo,
    int day,
    String status,
    String diagnosis,
  ) {
    final color = _statusColor(status);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('Day $day', style: const TextStyle(fontSize: 16)),
          ),
          body: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  child: Center(child: _buildImage(photo, fit: BoxFit.contain)),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[900],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_statusIcon(status), size: 16, color: color),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    if (diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        diagnosis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GardenLocationResult {
  const _GardenLocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.placeId,
  });

  final double latitude;
  final double longitude;
  final String address;
  final String? placeId;
}

class _GardenLocationPickerScreen extends StatefulWidget {
  const _GardenLocationPickerScreen({
    required this.apiKey,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
  });

  final String apiKey;
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;

  @override
  State<_GardenLocationPickerScreen> createState() =>
      _GardenLocationPickerScreenState();
}

class _GardenLocationPickerScreenState
    extends State<_GardenLocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;
  List<_PlaceSuggestion> _suggestions = [];
  bool _searching = false;
  bool _resolvingAddress = false;
  String? _selectedAddress;
  String? _selectedPlaceId;
  LatLng _selectedPoint = const LatLng(3.1390, 101.6869);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedPoint = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _selectedAddress = widget.initialAddress;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location services.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final target = LatLng(position.latitude, position.longitude);

    setState(() {
      _selectedPoint = target;
      _selectedPlaceId = null;
      _resolvingAddress = true;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));

    final address = await _reverseGeocode(target);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAddress =
          address ??
          'Lat: ${target.latitude.toStringAsFixed(5)}, Lng: ${target.longitude.toStringAsFixed(5)}';
      _resolvingAddress = false;
    });
  }

  Future<void> _onMapTap(LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _selectedPlaceId = null;
      _resolvingAddress = true;
    });

    final address = await _reverseGeocode(point);

    if (!mounted) {
      return;
    }
    setState(() {
      _selectedAddress =
          address ??
          'Lat: ${point.latitude.toStringAsFixed(5)}, Lng: ${point.longitude.toStringAsFixed(5)}';
      _resolvingAddress = false;
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    if (widget.apiKey.isEmpty) {
      await _searchPlacesFallback(query);
      return;
    }

    setState(() {
      _searching = true;
    });

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {'input': query, 'key': widget.apiKey},
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _searching = false;
            _suggestions = [];
          });
        }
        return;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = (payload['predictions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _suggestions = predictions
            .map(
              (item) => _PlaceSuggestion(
                placeId: (item['place_id'] as String?) ?? '',
                description: (item['description'] as String?) ?? '',
              ),
            )
            .where(
              (item) =>
                  (item.placeId?.isNotEmpty ?? false) &&
                  item.description.isNotEmpty,
            )
            .toList();
        _searching = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = false;
        _suggestions = [];
      });
    }
  }

  Future<void> _searchPlacesFallback(String query) async {
    setState(() {
      _searching = true;
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5',
      );
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'KitaAgroApp/1.0'},
      );

      if (response.statusCode != 200) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searching = false;
          _suggestions = [];
        });
        return;
      }

      final results = (jsonDecode(response.body) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _suggestions = results
            .map(
              (item) => _PlaceSuggestion(
                placeId: null,
                description: (item['display_name'] as String?) ?? '',
                latitude: double.tryParse(item['lat'] as String? ?? ''),
                longitude: double.tryParse(item['lon'] as String? ?? ''),
              ),
            )
            .where(
              (item) =>
                  item.description.isNotEmpty &&
                  item.latitude != null &&
                  item.longitude != null,
            )
            .toList();
        _searching = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = false;
        _suggestions = [];
      });
    }
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    if (suggestion.latitude != null && suggestion.longitude != null) {
      final target = LatLng(suggestion.latitude!, suggestion.longitude!);
      setState(() {
        _selectedPoint = target;
        _selectedAddress = suggestion.description;
        _selectedPlaceId = suggestion.placeId;
        _suggestions = [];
        _resolvingAddress = false;
        _searching = false;
      });
      _searchController.text = suggestion.description;
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
      return;
    }

    if (widget.apiKey.isEmpty || suggestion.placeId == null) {
      return;
    }

    setState(() {
      _searching = true;
      _suggestions = [];
      _resolvingAddress = true;
    });

    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
            'place_id': suggestion.placeId!,
            'fields': 'geometry,formatted_address,place_id',
            'key': widget.apiKey,
          });
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searching = false;
          _resolvingAddress = false;
        });
        return;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final result = payload['result'] as Map<String, dynamic>?;
      final geometry = result?['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;

      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();
      final formattedAddress = result?['formatted_address'] as String?;

      if (lat == null || lng == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _searching = false;
          _resolvingAddress = false;
        });
        return;
      }

      final target = LatLng(lat, lng);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedPoint = target;
        _selectedAddress =
            formattedAddress ??
            'Lat: ${target.latitude.toStringAsFixed(5)}, Lng: ${target.longitude.toStringAsFixed(5)}';
        _selectedPlaceId = suggestion.placeId!;
        _searching = false;
        _resolvingAddress = false;
      });

      _searchController.text = suggestion.description;

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searching = false;
        _resolvingAddress = false;
      });
    }
  }

  Future<String?> _reverseGeocode(LatLng point) async {
    if (widget.apiKey.isEmpty) {
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${point.latitude}&lon=${point.longitude}',
        );
        final response = await http.get(
          uri,
          headers: const {'User-Agent': 'KitaAgroApp/1.0'},
        );
        if (response.statusCode != 200) {
          return null;
        }
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        return payload['display_name'] as String?;
      } catch (_) {
        return null;
      }
    }
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '${point.latitude},${point.longitude}',
        'key': widget.apiKey,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (payload['results'] as List<dynamic>? ?? []);
      if (results.isEmpty) {
        return null;
      }
      final first = results.first as Map<String, dynamic>;
      return first['formatted_address'] as String?;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallbackAddress =
        'Lat: ${_selectedPoint.latitude.toStringAsFixed(5)}, Lng: ${_selectedPoint.longitude.toStringAsFixed(5)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Garden Location'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: widget.apiKey.isEmpty
                          ? 'Search place or address (fallback mode)'
                          : 'Search place or address',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: _searchPlaces,
                    onSubmitted: _searchPlaces,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _goToCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  tooltip: 'Use current location',
                ),
              ],
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade300),
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined),
                    title: Text(suggestion.description),
                    onTap: () => _selectSuggestion(suggestion),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPoint,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: _onMapTap,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('garden_location'),
                  position: _selectedPoint,
                ),
              },
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pin_drop, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedAddress ?? fallbackAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (_resolvingAddress)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _GardenLocationResult(
                          latitude: _selectedPoint.latitude,
                          longitude: _selectedPoint.longitude,
                          address: _selectedAddress ?? fallbackAddress,
                          placeId: _selectedPlaceId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save Garden Location'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSuggestion {
  const _PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.latitude,
    this.longitude,
  });

  final String? placeId;
  final String description;
  final double? latitude;
  final double? longitude;
}
