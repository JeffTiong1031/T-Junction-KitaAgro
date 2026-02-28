import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'package:kita_agro/features/Home/Planting/planting_screen.dart';
import 'package:kita_agro/features/Home/Dictionary/dictionary_screen.dart';
import 'package:kita_agro/features/Home/my_journey/my_journey_screen.dart';
import 'package:kita_agro/features/Home/search_users_screen.dart';
import 'package:kita_agro/features/Home/global_search_screen.dart';
import 'package:kita_agro/features/Profile/single_post_screen.dart';
import 'package:kita_agro/services/notification_service.dart';
import 'package:kita_agro/features/community/community_service.dart';
import 'package:kita_agro/features/Home/notification_screen.dart';
import 'package:kita_agro/core/services/notification_storage.dart';
import 'package:kita_agro/features/Home/ai_assistant_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kita_agro/features/community/create_post_screen.dart';
import 'package:kita_agro/features/community/comments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;
  final PageController _gardenCarouselController = PageController(
    viewportFraction: 0.85,
  );
  int _currentGardenPage = 0;
  final ValueNotifier<int> _gardenPageNotifier = ValueNotifier<int>(0);
  Future<_WeatherData?>? _weatherFuture;
  String? _weatherLocationKey;
  DateTime? _weatherFetchedAt;
  final NotificationService _notificationService = NotificationService();
  final CommunityService _communityService = CommunityService();

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
  void dispose() {
    _gardenCarouselController.dispose();
    _gardenPageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16.0,
        toolbarHeight: 65, // Adjusts the height to fit the search bar nicely
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GlobalSearchScreen(),
                      ),
                    );
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).searchHint,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 👉 The Bell Icon Section
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
                setState(() {});
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: FutureBuilder<int>(
                  future: NotificationStorage.getUnreadCount(),
                  builder: (context, snapshot) {
                    int unseenCount = snapshot.data ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                        if (unseenCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unseenCount > 9 ? '9+' : unseenCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Dashboard Section
          SliverToBoxAdapter(child: _buildDashboard()),
          // My Garden Carousel
          SliverToBoxAdapter(child: _buildMyGardenCarousel()),
          // Action Buttons Section
          SliverToBoxAdapter(child: _buildActionButtons()),
          // Tab Navigation
          SliverToBoxAdapter(child: _buildTabNavigation()),
          // Community Posts from Firebase
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: _communityService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading posts: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Text(AppLocalizations.of(context).noPostsYet),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final postDoc = snapshot.data!.docs[index];
                    return _buildRealCommunityPost(postDoc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _gardenPlantStream(),
      builder: (context, snapshot) {
        final plants = snapshot.data ?? <Map<String, dynamic>>[];

        // Calculate total carbon reduction
        final totalCarbonReduction = plants.fold<double>(0.0, (sum, plant) {
          final carbon = plant['carbonReduction'];
          if (carbon is num) {
            return sum + carbon.toDouble();
          }
          return sum;
        });

        const double carbonPerLevel = 30.0;
        final int carbonLevel = (totalCarbonReduction ~/ carbonPerLevel) + 1;
        final double currentLevelCarbon = totalCarbonReduction % carbonPerLevel;
        final double levelProgress = (currentLevelCarbon / carbonPerLevel)
            .clamp(0.0, 1.0);
        final double remainToNextLevel =
            (carbonPerLevel - currentLevelCarbon) % carbonPerLevel;

        return Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[700]!, Colors.green[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.co2,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).carbonEmissionReduction,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.92),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              totalCarbonReduction > 0
                                  ? '${totalCarbonReduction.toStringAsFixed(1)} kg CO₂e/yr'
                                  : AppLocalizations.of(
                                      context,
                                    ).startPlantingToEarn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.20),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Level $carbonLevel',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${remainToNextLevel == 0 ? carbonPerLevel.toStringAsFixed(0) : remainToNextLevel.toStringAsFixed(1)} ${AppLocalizations.of(context).kgToNextLevel((remainToNextLevel == 0 ? carbonPerLevel.toStringAsFixed(0) : remainToNextLevel.toStringAsFixed(1)), carbonLevel + 1).substring((remainToNextLevel == 0 ? carbonPerLevel.toStringAsFixed(0) : remainToNextLevel.toStringAsFixed(1)).length + 1)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: levelProgress,
                                minHeight: 6,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            if (plants.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).plantsContributing(plants.length),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 9,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StreamBuilder<Map<String, dynamic>?>(
                            stream: _gardenLocationStream(),
                            builder: (context, locationSnapshot) {
                              final locationData = locationSnapshot.data;
                              final locationText = _formatGardenLocation(
                                locationData,
                              );
                              final weatherFuture = _weatherFutureForLocation(
                                locationData,
                              );

                              return FutureBuilder<_WeatherData?>(
                                future: weatherFuture,
                                builder: (context, weatherSnapshot) {
                                  final weather = weatherSnapshot.data;
                                  final isLoading =
                                      weatherSnapshot.connectionState ==
                                      ConnectionState.waiting;
                                  final hasError = weatherSnapshot.hasError;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AppLocalizations.of(
                                                context,
                                              ).today,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                            Icon(
                                              weather != null
                                                  ? _weatherIconForCode(
                                                      weather.weatherCode,
                                                    )
                                                  : Icons.cloud_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (isLoading)
                                          Text(
                                            AppLocalizations.of(
                                              context,
                                            ).loading,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        else if (weather != null)
                                          Text(
                                            '${weather.temperatureCelsius.toStringAsFixed(1)}°C',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        else
                                          Text(
                                            hasError
                                                ? AppLocalizations.of(
                                                    context,
                                                  ).unavailable
                                                : AppLocalizations.of(
                                                    context,
                                                  ).setLocation,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        Text(
                                          weather != null
                                              ? _weatherConditionLabel(
                                                  weather.weatherCode,
                                                )
                                              : locationText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (weather != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            _getWeatherAdvice(
                                              weather.temperatureCelsius,
                                              weather.weatherCode,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildReminderCard(plants),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Stream<Map<String, dynamic>?> _gardenLocationStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
          final data = snapshot.data();
          final location = data?['gardenLocation'];
          if (location is Map<String, dynamic>) {
            return location;
          }
          if (location is Map) {
            return location.cast<String, dynamic>();
          }
          return null;
        });
  }

  String _formatGardenLocation(Map<String, dynamic>? locationData) {
    if (locationData == null) {
      return AppLocalizations.of(context).setInMyJourney;
    }

    final address = locationData['address'] as String?;
    if (address != null && address.trim().isNotEmpty) {
      final firstSegment = address.split(',').first.trim();
      return firstSegment.isEmpty ? address : firstSegment;
    }

    final latitude = (locationData['latitude'] as num?)?.toDouble();
    final longitude = (locationData['longitude'] as num?)?.toDouble();
    if (latitude != null && longitude != null) {
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }

    return AppLocalizations.of(context).setInMyJourney;
  }

  Future<_WeatherData?> _weatherFutureForLocation(
    Map<String, dynamic>? locationData,
  ) {
    final latitude = (locationData?['latitude'] as num?)?.toDouble();
    final longitude = (locationData?['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      return Future.value(null);
    }

    final key =
        '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';
    final now = DateTime.now();
    final shouldRefresh =
        _weatherFuture == null ||
        _weatherLocationKey != key ||
        _weatherFetchedAt == null ||
        now.difference(_weatherFetchedAt!) > const Duration(minutes: 20);

    if (shouldRefresh) {
      _weatherLocationKey = key;
      _weatherFetchedAt = now;
      _weatherFuture = _fetchCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
    }

    return _weatherFuture!;
  }

  Future<_WeatherData?> _fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final current = payload['current'] as Map<String, dynamic>?;
      if (current == null) {
        return null;
      }

      final temperature = (current['temperature_2m'] as num?)?.toDouble();
      final weatherCode = (current['weather_code'] as num?)?.toInt();
      if (temperature == null || weatherCode == null) {
        return null;
      }

      return _WeatherData(
        temperatureCelsius: temperature,
        weatherCode: weatherCode,
      );
    } catch (_) {
      return null;
    }
  }

  String _weatherConditionLabel(int code) {
    final loc = AppLocalizations.of(context);
    if (code == 0) return loc.clearSky;
    if (code == 1 || code == 2) return loc.partlyCloudy;
    if (code == 3) return loc.cloudy;
    if (code == 45 || code == 48) return loc.fog;
    if (code == 51 || code == 53 || code == 55) return loc.drizzle;
    if (code == 56 || code == 57) return loc.freezingDrizzle;
    if (code == 61 || code == 63 || code == 65) return loc.rain;
    if (code == 66 || code == 67) return loc.freezingRain;
    if (code == 71 || code == 73 || code == 75 || code == 77) return loc.snow;
    if (code == 80 || code == 81 || code == 82) return loc.rainShowers;
    if (code == 85 || code == 86) return loc.snowShowers;
    if (code == 95 || code == 96 || code == 99) return loc.thunderstorm;
    return loc.unknownWeather;
  }

  IconData _weatherIconForCode(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2) return Icons.wb_cloudy;
    if (code == 3) return Icons.cloud;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code == 51 || code == 53 || code == 55 || code == 56 || code == 57) {
      return Icons.grain;
    }
    if (code == 61 ||
        code == 63 ||
        code == 65 ||
        code == 66 ||
        code == 67 ||
        code == 80 ||
        code == 81 ||
        code == 82) {
      return Icons.umbrella;
    }
    if (code == 71 ||
        code == 73 ||
        code == 75 ||
        code == 77 ||
        code == 85 ||
        code == 86) {
      return Icons.ac_unit;
    }
    if (code == 95 || code == 96 || code == 99) return Icons.flash_on;
    return Icons.cloud_outlined;
  }

  Widget _buildActionButtons() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        runSpacing: 12,
        spacing: 8,
        children: [
          _buildActionButton(
            label: AppLocalizations.of(context).myJourney,
            color: Colors.teal[100]!,
            icon: Icons.favorite,
            iconColor: Colors.teal,
            onTap: () async {
              await FirebaseAnalytics.instance.logEvent(
                name: 'open_my_journey',
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyJourneyScreen(),
                ),
              );
            },
          ),
          _buildActionButton(
            label: AppLocalizations.of(context).dictionary,
            color: Colors.orange[100]!,
            icon: Icons.description,
            iconColor: Colors.orange,
            onTap: () async {
              await FirebaseAnalytics.instance.logEvent(
                name: 'open_dictionary',
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DictionaryScreen(),
                ),
              );
            },
          ),
          _buildActionButton(
            label: AppLocalizations.of(context).aiAssistant,
            color: Colors.purple[100]!,
            icon: Icons.smart_toy,
            iconColor: Colors.purple,
            onTap: () async {
              await FirebaseAnalytics.instance.logEvent(
                name: 'open_ai_assistant',
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AiAssistantScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    final loc = AppLocalizations.of(context);
    final tabs = [loc.community, loc.recommend, loc.market, loc.qAndA];
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          tabs.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () async {
                if (index == 0) {
                  await FirebaseAnalytics.instance.logEvent(
                    name: 'view_community_tab',
                  );
                }
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 4.0,
                    ),
                    // 👉 Added FittedBox to scale down the text/icon if it exceeds the column width
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tabs[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: _selectedTabIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _selectedTabIndex == index
                                  ? Colors.teal
                                  : Colors.grey,
                            ),
                          ),
                          if (index == 0) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _pickImageAndNavigate(context),
                              child: Icon(
                                Icons.add_circle,
                                size: 18,
                                color: _selectedTabIndex == index
                                    ? Colors.teal
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_selectedTabIndex == index)
                    Container(height: 3, color: Colors.teal),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealCommunityPost(DocumentSnapshot postDoc) {
    final data = postDoc.data() as Map<String, dynamic>;
    final publisherId = data['publisherId'] as String?;
    final username = data['publisherName'] ?? 'Unknown User';
    final userProfilePic = data['publisherProfilePic'] ?? '?';
    final caption = data['caption'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final likesCount = data['likesCount'] ?? 0;
    final commentsCount = data['commentsCount'] ?? 0;
    final likedBy = data['likedBy'] as List<dynamic>? ?? [];

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isMyPost = publisherId == currentUserId;
    final isLiked = currentUserId != null && likedBy.contains(currentUserId);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SinglePostScreen(postDoc: postDoc),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.teal[300],
                        radius: 20,
                        child: Text(
                          userProfilePic.isNotEmpty
                              ? userProfilePic[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppLocalizations.of(context).communityMember,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isMyPost)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          // Confirm deletion
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                AppLocalizations.of(context).deletePost,
                              ),
                              content: Text(
                                AppLocalizations.of(context).deletePostConfirm,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context).cancel,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    _communityService.deletePost(
                                      postDoc.id,
                                    ); // Delete the post
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
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            AppLocalizations.of(context).deletePost,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    )
                  else
                    Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                ],
              ),
              const SizedBox(height: 12),

              // Post Caption
              if (caption.isNotEmpty) ...[
                Text(caption, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],

              // Post Image (if available)
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error_outline),
                    ),
                  ),
                ),

              if (imageUrl.isNotEmpty) const SizedBox(height: 12),

              // Engagement Metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildEngagementButton(
                    icon: isLiked ? Icons.favorite : Icons.favorite_border,
                    iconColor: isLiked ? Colors.red : null,
                    count: likesCount,
                    onTap: () {
                      if (currentUserId != null) {
                        _communityService.toggleLike(
                          postDoc.id,
                          currentUserId,
                          likedBy,
                        );
                      }
                    },
                  ),
                  _buildEngagementButton(
                    icon: Icons.comment_outlined,
                    count: commentsCount,
                    onTap: () {
                      showCommentsBottomSheet(context, postDoc.id);
                    },
                  ),
                  _buildEngagementButton(icon: Icons.share_outlined, count: 0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyGardenCarousel() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _gardenPlantStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildGardenLoadingState();
        }
        if (snapshot.hasError) {
          return _buildGardenErrorState();
        }

        final plants = snapshot.data ?? <Map<String, dynamic>>[];
        if (plants.isEmpty) {
          return _buildGardenEmptyState();
        }

        var safeCurrentPage = _currentGardenPage;
        if (safeCurrentPage >= plants.length) {
          safeCurrentPage = 0;
        }
        if (_gardenPageNotifier.value != safeCurrentPage) {
          _gardenPageNotifier.value = safeCurrentPage;
        }
        if (_gardenCarouselController.hasClients &&
            _gardenCarouselController.page?.round() != safeCurrentPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_gardenCarouselController.hasClients) {
              _gardenCarouselController.jumpToPage(safeCurrentPage);
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ValueListenableBuilder<int>(
                valueListenable: _gardenPageNotifier,
                builder: (context, pageIndex, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).myGarden,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${pageIndex + 1}/${plants.length}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(
              height: 264,
              child: PageView.builder(
                key: const PageStorageKey<String>('my_garden_pageview'),
                controller: _gardenCarouselController,
                onPageChanged: (index) {
                  _currentGardenPage = index;
                  _gardenPageNotifier.value = index;
                },
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  final int totalDays = plant['totalDays'] as int;
                  final int daysPlanted = plant['daysPlanted'] as int;
                  final int health = _calculateHealthFromPlant(plant);
                  final String healthStatus = _healthStatusLabel(health);
                  final Color healthColor = _healthStatusColor(health);
                  final String latestPhotoStatus =
                      ((plant['latestPhotoStatus'] as String?) ?? '').trim();
                  final double progress = totalDays <= 0
                      ? 0.0
                      : (daysPlanted / totalDays).clamp(0.0, 1.0);
                  final int remainingDays = (totalDays - daysPlanted) < 0
                      ? 0
                      : (totalDays - daysPlanted);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (plant['color'] as Color).withOpacity(0.8),
                          plant['color'] as Color,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (plant['color'] as Color).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            plant['icon'] as IconData,
                            size: 150,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    plant['icon'] as IconData,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).daysLabel(daysPlanted),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).getLocalizedPlantName(
                                  plant['name'] as String,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                plant['scientificName'] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).healthLabel(healthStatus),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: health / 100,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.3,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        healthColor,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    latestPhotoStatus.isNotEmpty
                                        ? latestPhotoStatus
                                        : AppLocalizations.of(
                                            context,
                                          ).noPhotoAnalysis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context).growthProgress,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.3,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                      minHeight: 8,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).daysToHarvest(remainingDays),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: ValueListenableBuilder<int>(
                  valueListenable: _gardenPageNotifier,
                  builder: (context, pageIndex, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        plants.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: pageIndex == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: pageIndex == index
                                ? Colors.green[700]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _gardenPlantStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(<Map<String, dynamic>>[]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plantations')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _mapGardenPlant(doc.data())).toList(),
        );
  }

  Map<String, dynamic> _mapGardenPlant(Map<String, dynamic> data) {
    final String? rawName = data['name'] as String?;
    final String name = (rawName == null || rawName.trim().isEmpty)
        ? 'Unnamed Plant'
        : rawName.trim();
    final String category = (data['category'] as String? ?? '').trim();
    final String scientificName = data['scientificName'] as String? ?? '';
    final String latestPhotoStatus = data['latestPhotoStatus'] as String? ?? '';
    final int rawTotalDays = _parsePositiveInt(data['totalDays'], fallback: 0);
    final int totalDays = _resolvePlantTotalDays(
      name: name,
      storedTotalDays: rawTotalDays,
    );
    final int daysPlanted = _resolveDaysPlanted(data, totalDays);
    final Color color = _parseColor(data['color']) ?? const Color(0xFF2E7D32);
    final IconData icon = _iconFromName(data['icon'] as String?);
    final double carbonReduction =
        (data['carbonReduction'] as num?)?.toDouble() ??
        _estimateCarbonReduction(
          name: name,
          category: category,
          totalDays: totalDays,
        );

    return {
      'name': name,
      'scientificName': scientificName,
      'latestPhotoStatus': latestPhotoStatus,
      'daysPlanted': daysPlanted,
      'totalDays': totalDays,
      'icon': icon,
      'color': color,
      'carbonReduction': carbonReduction,
    };
  }

  double _estimateCarbonReduction({
    required String name,
    required String category,
    required int totalDays,
  }) {
    final nameLower = name.toLowerCase();
    final categoryLower = category.toLowerCase();

    if (nameLower.contains('apple') || nameLower.contains('tree')) {
      return 25.0;
    }

    if (nameLower.contains('papaya') || nameLower.contains('banana')) {
      return 12.0;
    }

    switch (categoryLower) {
      case 'vegetable':
        return 2.5;
      case 'herb':
        return 1.5;
      case 'fruit':
        return 5.0;
      default:
        return 3.0;
    }
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

  int _healthFromStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('healthy')) return 90;
    if (normalized.contains('critical')) return 20;
    if (normalized.contains('attention') || normalized.contains('warning'))
      return 55;
    if (normalized.contains('unknown')) return 50;
    return 60;
  }

  int _calculateHealthFromPlant(Map<String, dynamic> plant) {
    final String latestStatus = ((plant['latestPhotoStatus'] as String?) ?? '')
        .trim();
    if (latestStatus.isNotEmpty) {
      return _healthFromStatus(latestStatus);
    }
    return 50;
  }

  String _healthStatusLabel(int health) {
    final loc = AppLocalizations.of(context);
    if (health >= 85) return loc.healthy;
    if (health >= 65) return loc.stable;
    if (health >= 40) return loc.needsAttention;
    return loc.critical;
  }

  Color _healthStatusColor(int health) {
    if (health >= 85) return const Color(0xFF2E7D32);
    if (health >= 65) return Colors.lightGreen;
    if (health >= 40) return Colors.orange;
    return Colors.red;
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Widget _buildReminderCard(List<Map<String, dynamic>> plants) {
    if (plants.isEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyJourneyScreen()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reminder',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Icon(
                    Icons.add_circle_outline,
                    color: Colors.orange,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).addYourFirstPlant,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<Map<String, int>>(
      stream: _pendingTasksStream(),
      builder: (context, snapshot) {
        final taskData = snapshot.data ?? {};
        final totalPending = taskData['pending'] ?? 0;
        final totalTasks = taskData['total'] ?? 0;

        final reminderColor = totalPending == 0 ? Colors.green : Colors.orange;
        final reminderIcon = totalPending == 0
            ? Icons.check_circle
            : Icons.task_alt;
        final reminderTitle = totalPending == 0
            ? AppLocalizations.of(context).allTasksDoneToday
            : AppLocalizations.of(context).tasksPending(totalPending);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyJourneyScreen()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: totalPending == 0 ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).dailyTasks,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Icon(reminderIcon, color: reminderColor, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reminderTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<Map<String, int>> _pendingTasksStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value({'total': 0, 'pending': 0});
    }

    final todayKey = _todayKey();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plantations')
        .snapshots()
        .map((snapshot) {
          int totalTasks = 0;
          int completedTasks = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final dailyTasks = data['dailyTasks'] as Map<String, dynamic>?;
            if (dailyTasks != null) {
              final todayData = dailyTasks[todayKey] as Map<String, dynamic>?;
              if (todayData != null) {
                final tasks = (todayData['tasks'] as List<dynamic>?) ?? [];
                final completed =
                    (todayData['completed'] as List<dynamic>?) ?? [];
                totalTasks += tasks.length;
                completedTasks += completed.length;
              }
            }
          }

          return {'total': totalTasks, 'pending': totalTasks - completedTasks};
        });
  }

  String _getWeatherAdvice(double temp, int weatherCode) {
    final loc = AppLocalizations.of(context);
    // Rain conditions
    if (weatherCode >= 51 && weatherCode <= 67) {
      return loc.weatherSkipWatering;
    }
    if (weatherCode >= 80 && weatherCode <= 82) {
      return loc.weatherNaturalWatering;
    }

    // Temperature-based advice
    if (temp > 35) {
      return loc.weatherTooHot;
    }
    if (temp > 30) {
      return loc.weatherHotDay;
    }
    if (temp >= 25 && temp <= 30) {
      if (weatherCode == 0) {
        return loc.weatherPerfect;
      }
      return loc.weatherGood;
    }
    if (temp >= 20 && temp < 25) {
      return loc.weatherPleasant;
    }
    if (temp < 20) {
      return loc.weatherCool;
    }

    return loc.weatherCheck;
  }

  int _parsePositiveInt(dynamic value, {required int fallback}) {
    if (value is num) {
      final int parsed = value.round();
      return parsed <= 0 ? fallback : parsed;
    }
    return fallback;
  }

  int _resolveDaysPlanted(Map<String, dynamic> data, int totalDays) {
    final dynamic daysValue = data['daysPlanted'];
    if (daysValue is num) {
      final int clamped = daysValue.round();
      if (clamped < 0) {
        return 0;
      }
      return clamped > totalDays ? totalDays : clamped;
    }

    final dynamic plantedAt = data['plantedAt'];
    if (plantedAt is Timestamp) {
      final int diffDays = DateTime.now().difference(plantedAt.toDate()).inDays;
      if (diffDays < 0) {
        return 0;
      }
      return diffDays > totalDays ? totalDays : diffDays;
    }

    return 0;
  }

  Color? _parseColor(dynamic value) {
    if (value is int) {
      return Color(value);
    }
    if (value is String) {
      var sanitized = value.trim();
      if (sanitized.startsWith('#')) {
        sanitized = sanitized.substring(1);
      }
      if (sanitized.startsWith('0x')) {
        sanitized = sanitized.substring(2);
      }
      if (sanitized.length == 6) {
        sanitized = 'FF$sanitized';
      }
      final int? colorInt = int.tryParse(sanitized, radix: 16);
      if (colorInt != null) {
        return Color(colorInt);
      }
    }
    return null;
  }

  IconData _iconFromName(String? name) {
    switch (name) {
      case 'circle':
      case 'tomato':
        return Icons.circle;
      case 'local_fire_department':
      case 'fire':
      case 'chili':
        return Icons.local_fire_department;
      case 'grass':
      case 'pandan':
        return Icons.grass;
      case 'spa':
      case 'papaya':
        return Icons.spa;
      case 'nature':
      case 'banana':
        return Icons.nature;
      case 'eco':
        return Icons.eco;
      case 'yard':
        return Icons.yard;
      default:
        return Icons.spa;
    }
  }

  Widget _buildGardenEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFAED581)),
      ),
      child: Column(
        children: [
          const Icon(Icons.yard_outlined, size: 48, color: Color(0xFF2E7D32)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).noPlantationsYet,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).addFirstPlant,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlantingScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context).addPlantation),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGardenLoadingState() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      ),
    );
  }

  Widget _buildGardenErrorState() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Color(0xFFD32F2F)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).gardenLoadError,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required int count,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageAndNavigate(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePostScreen(imageFile: pickedFile),
        ),
      );
    }
  }
}

class _WeatherData {
  const _WeatherData({
    required this.temperatureCelsius,
    required this.weatherCode,
  });

  final double temperatureCelsius;
  final int weatherCode;
}
