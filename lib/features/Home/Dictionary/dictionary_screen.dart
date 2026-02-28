import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kita_agro/core/services/gemini_api_service.dart';
import 'package:kita_agro/core/services/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  String _selectedCategory = 'All';
  String _selectedCost = 'All';
  String _selectedDifficulty = 'All';
  final ScrollController _gridController = ScrollController();
  final GeminiApiService _geminiService = GeminiApiService(
    dotenv.env['GEMINI_API_KEY_DICTIONARY_AND_JOURNEY'] ?? '',
  );

  final List<String> _categories = ['All', 'Vegetables', 'Fruits', 'Herbs'];

  final List<String> _costFilters = ['All', 'Low', 'Medium', 'High'];
  final List<String> _difficultyFilters = ['All', 'Easy', 'Medium', 'Hard'];

  final List<Map<String, dynamic>> _plants = [
    // Vegetables
    {
      'name': 'Tomato',
      'scientificName': 'Solanum lycopersicum',
      'category': 'Vegetables',
      'cost': 'Low',
      'difficulty': 'Easy',
      'icon': Icons.circle,
      'color': Color(0xFFE53935),
      'growthTime': '80-100 days',
      'description':
          'A popular garden vegetable rich in vitamins A and C. Tomatoes are used in salads, sauces, and many cuisines worldwide.',
    },
    {
      'name': 'Chili',
      'scientificName': 'Capsicum annuum',
      'category': 'Vegetables',
      'cost': 'Low',
      'difficulty': 'Medium',
      'icon': Icons.local_fire_department,
      'color': Color(0xFFD32F2F),
      'growthTime': '90-120 days',
      'description':
          'Spicy fruit used in many cuisines worldwide. Contains capsaicin which gives the heat.',
    },
    // Fruits
    {
      'name': 'Papaya',
      'scientificName': 'Carica papaya',
      'category': 'Fruits',
      'cost': 'Medium',
      'difficulty': 'Medium',
      'icon': Icons.spa,
      'color': Color(0xFFFFB300),
      'growthTime': '240-330 days',
      'description':
          'Tropical fruit with sweet orange flesh. Rich in enzymes and vitamins.',
    },
    {
      'name': 'Banana',
      'scientificName': 'Musa acuminata',
      'category': 'Fruits',
      'cost': 'Medium',
      'difficulty': 'Medium',
      'icon': Icons.nature,
      'color': Color(0xFFFFEB3B),
      'growthTime': '270-360 days',
      'description':
          'Tropical fruit rich in potassium. Requires warm frost-free climate (above 10°C year-round). Dies at 0°C. NOT suitable for temperate zones with winter frost.',
    },
    {
      'name': 'Strawberry',
      'scientificName': 'Fragaria × ananassa',
      'category': 'Fruits',
      'cost': 'Medium',
      'difficulty': 'Medium',
      'icon': Icons.local_florist,
      'color': Color(0xFFE91E63),
      'growthTime': '90-120 days',
      'description':
          'Sweet red fruit rich in vitamin C and antioxidants. Best with good drainage and regular care.',
    },
    {
      'name': 'Apple',
      'scientificName': 'Malus domestica',
      'category': 'Fruits',
      'cost': 'High',
      'difficulty': 'Hard',
      'icon': Icons.apple,
      'color': Color(0xFFEF5350),
      'growthTime': '4-5 years',
      'description':
          'Temperate fruit tree requiring 800-1000 chill hours (below 7°C). NOT suitable for tropical lowlands. Best in highland areas above 1000m elevation.',
    },
    // Herbs
    {
      'name': 'Pandan',
      'scientificName': 'Pandanus amaryllifolius',
      'category': 'Herbs',
      'cost': 'Low',
      'difficulty': 'Easy',
      'icon': Icons.grass,
      'color': Color(0xFF388E3C),
      'growthTime': '120-180 days',
      'description':
          'Fragrant leaves used in Southeast Asian desserts and rice dishes.',
    },
  ];

  List<Map<String, dynamic>> get _filteredPlants {
    return _plants.where((plant) {
      final categoryMatch =
          _selectedCategory == 'All' || plant['category'] == _selectedCategory;
      final costMatch =
          _selectedCost == 'All' || plant['cost'] == _selectedCost;
      final difficultyMatch =
          _selectedDifficulty == 'All' ||
          plant['difficulty'] == _selectedDifficulty;
      return categoryMatch && costMatch && difficultyMatch;
    }).toList();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  Future<void> _addPlantToGarden(Map<String, dynamic> plant) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseSignIn),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final int totalDays = _parseGrowthDays(plant['growthTime'] as String?);
    final IconData icon = plant['icon'] as IconData;
    final Color color = plant['color'] as Color;
    final double carbonReduction = _estimateCarbonReduction(
      plant['name'] as String,
      plant['category'] as String,
      totalDays,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('plantations')
        .add({
          'name': plant['name'],
          'scientificName': plant['scientificName'],
          'category': plant['category'],
          'totalDays': totalDays,
          'daysPlanted': 0,
          'plantedAt': Timestamp.now(),
          'icon': _iconName(icon),
          'color': color.value,
          'carbonReduction': carbonReduction,
        });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).plantAddedToGarden(
            AppLocalizations.of(
              context,
            ).getLocalizedPlantName(plant['name'] as String),
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _parseGrowthDays(String? growthTime) {
    if (growthTime == null || growthTime.trim().isEmpty) {
      return 75;
    }

    final String lower = growthTime.toLowerCase();
    final numbers = RegExp(r'(\d+)')
        .allMatches(lower)
        .map((match) => int.tryParse(match.group(1) ?? ''))
        .whereType<int>()
        .toList();

    if (numbers.isEmpty) {
      return 75;
    }

    int value = numbers.length > 1 ? numbers.last : numbers.first;

    if (lower.contains('week')) {
      value *= 7;
    }
    if (lower.contains('month')) {
      value *= 30;
    }
    if (lower.contains('year')) {
      value *= 365;
    }

    return value;
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

  String _iconName(IconData icon) {
    if (icon == Icons.circle) {
      return 'circle';
    }
    if (icon == Icons.local_fire_department) {
      return 'local_fire_department';
    }
    if (icon == Icons.spa) {
      return 'spa';
    }
    if (icon == Icons.nature) {
      return 'nature';
    }
    if (icon == Icons.grass) {
      return 'grass';
    }
    return 'spa';
  }

  // Map English data keys to localized display text
  String _localizeLabel(String key) {
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
      case 'Low':
        return loc.low;
      case 'Medium':
        return loc.medium;
      case 'High':
        return loc.high;
      case 'Easy':
        return loc.easy;
      case 'Hard':
        return loc.hard;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1B5E20),
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context).plantDictionary,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Category tabs
          Container(
            color: Color(0xFF2E7D32),
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _localizeLabel(category),
                          style: TextStyle(
                            color: isSelected
                                ? Color(0xFF2E7D32)
                                : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Cost & difficulty filters
          Container(
            color: Color(0xFF2E7D32),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterDropdown(
                    label: AppLocalizations.of(context).cost,
                    value: _selectedCost,
                    options: _costFilters,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCost = value);
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterDropdown(
                    label: AppLocalizations.of(context).difficulty,
                    value: _selectedDifficulty,
                    options: _difficultyFilters,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedDifficulty = value);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Plant count
          Container(
            color: Color(0xFF1B5E20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.eco, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_filteredPlants.length} Plants',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Grid of plants
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: GridView.builder(
                key: const PageStorageKey<String>('dictionary_grid'),
                controller: _gridController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.7,
                ),
                itemCount: _filteredPlants.length,
                itemBuilder: (context, index) {
                  final plant = _filteredPlants[index];
                  return _buildPlantBlock(plant);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF2E7D32),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: onChanged,
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text('$label: ${_localizeLabel(option)}'),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildPlantBlock(Map<String, dynamic> plant) {
    return GestureDetector(
      onTap: () => _showPlantDetails(plant),
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xFF388E3C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF4CAF50), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Plant icon in circle
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: plant['color'] as Color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: (plant['color'] as Color).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                plant['icon'] as IconData,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            // Plant name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                AppLocalizations.of(
                  context,
                ).getLocalizedPlantName(plant['name'] as String),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                plant['scientificName'] as String,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlantDetails(Map<String, dynamic> plant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlantDetailSheet(
        plant: plant,
        geminiService: _geminiService,
        onAddToGarden: () => _addPlantToGarden(plant),
      ),
    );
  }
}

class _PlantDetailSheet extends StatefulWidget {
  final Map<String, dynamic> plant;
  final GeminiApiService geminiService;
  final VoidCallback onAddToGarden;

  const _PlantDetailSheet({
    required this.plant,
    required this.geminiService,
    required this.onAddToGarden,
  });

  @override
  State<_PlantDetailSheet> createState() => _PlantDetailSheetState();
}

class _PlantDetailSheetState extends State<_PlantDetailSheet> {
  static final Map<String, Map<String, dynamic>> _aiCache = {};
  static DateTime? _aiQuotaCooldownUntil;

  Map<String, dynamic>? _aiAdvice;
  bool _isLoadingAI = true;
  String _locationName = 'Unknown';
  double _temperature = 25.0;
  String _weatherCondition = 'Clear';

  // Map English data keys to localized display text
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
      case 'Low':
        return loc.low;
      case 'Medium':
        return loc.medium;
      case 'High':
        return loc.high;
      case 'Easy':
        return loc.easy;
      case 'Hard':
        return loc.hard;
      default:
        return key;
    }
  }

  // Track which cards are expanded
  final Set<String> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _loadLocationAndAI();
  }

  Future<void> _loadLocationAndAI() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // No user logged in - use default location for demo
        _locationName = 'Malaysia';
        _fetchAIAdvice();
        return;
      }

      // Fetch saved garden location from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data()?['gardenLocation'] == null) {
        // No saved location - use default location for demo
        _locationName = 'Malaysia';
        _fetchAIAdvice();
        return;
      }

      final locationData =
          userDoc.data()!['gardenLocation'] as Map<String, dynamic>;
      final latitude = locationData['latitude'] as double;
      final longitude = locationData['longitude'] as double;
      _locationName = locationData['address'] ?? 'Your location';

      // Fetch current weather
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code',
      );
      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode == 200) {
        final weatherJson = jsonDecode(weatherResponse.body);
        _temperature = (weatherJson['current']?['temperature_2m'] ?? 25.0)
            .toDouble();
        final weatherCode = weatherJson['current']?['weather_code'] ?? 0;
        _weatherCondition = _weatherCodeToCondition(weatherCode);
      }

      // Fetch AI advice with real data
      _fetchAIAdvice();
    } catch (e) {
      print('Error loading AI advice: $e');
      setState(() => _isLoadingAI = false);
    }
  }

  Future<void> _fetchAIAdvice() async {
    try {
      final plantName = widget.plant['name'];
      final langCode = LanguageServiceProvider.of(context).currentLanguage.code;
      final cacheKey = '$plantName-$_locationName-$langCode';

      // Check cache first
      if (_aiCache.containsKey(cacheKey)) {
        print(
          '💾 Using cached data for $plantName in $_locationName ($langCode)',
        );
        setState(() {
          _aiAdvice = _aiCache[cacheKey];
          _isLoadingAI = false;
        });
        return;
      }

      final now = DateTime.now();
      if (_aiQuotaCooldownUntil != null &&
          now.isBefore(_aiQuotaCooldownUntil!)) {
        final fallback = _buildFallbackAdvice(plantName);
        _aiCache[cacheKey] = fallback;
        setState(() {
          _aiAdvice = fallback;
          _isLoadingAI = false;
        });
        return;
      }

      print('🤖 Calling Gemini AI for $plantName...');
      print('📍 Location: $_locationName');
      print('🌡️ Temperature: $_temperature°C');
      print('🌤️ Weather: $_weatherCondition');

      // Fetch AI advice
      final advice = await widget.geminiService.getLocalizedAdvice(
        plantName: plantName,
        scientificName: widget.plant['scientificName'],
        category: widget.plant['category'],
        location: _locationName,
        temperature: _temperature,
        weatherCondition: _weatherCondition,
        languageCode: langCode,
      );

      print('✅ AI Response received: ${advice != null}');
      if (advice != null) {
        print('📊 Local Match Score: ${advice['localMatchScore']}');
        print('🌱 Growth Time: ${advice['growthTime']}');
        print('☀️ Sunlight: ${advice['sunlight']}');

        // Cache the result
        _aiCache[cacheKey] = advice;
      } else {
        print('⚠️ AI returned null - using fallback guidance');
        final fallback = _buildFallbackAdvice(plantName);
        _aiCache[cacheKey] = fallback;
        _aiQuotaCooldownUntil = DateTime.now().add(const Duration(seconds: 60));
        setState(() {
          _aiAdvice = fallback;
          _isLoadingAI = false;
        });
        return;
      }

      setState(() {
        _aiAdvice = advice;
        _isLoadingAI = false;
      });
    } catch (e) {
      print('❌ Error fetching AI advice: $e');
      final fallback = _buildFallbackAdvice(widget.plant['name']);
      setState(() {
        _aiAdvice = fallback;
        _isLoadingAI = false;
      });
    }
  }

  Map<String, dynamic> _buildFallbackAdvice(String plantName) {
    if (!mounted) return {};
    final category = (widget.plant['category'] as String? ?? '').toLowerCase();
    final loc = AppLocalizations.of(context);

    final carbonByCategory = {
      'vegetable': loc.fallbackVegetableCarbon,
      'herb': loc.fallbackHerbCarbon,
      'fruit': loc.fallbackFruitCarbon,
    };

    return {
      'localMatchScore': 78,
      'growingContext': loc.fallbackGrowingContext(plantName, _locationName),
      'growthTime': widget.plant['growthTime'] ?? '60-120 days',
      'difficulty': loc.fallbackDifficulty,
      'sunlight': loc.fallbackSunlight,
      'watering': _temperature >= 30
          ? loc.fallbackWateringHot
          : loc.fallbackWateringNormal,
      'soil': loc.fallbackSoil,
      'carbonReduction':
          carbonByCategory[category] ?? loc.fallbackDefaultCarbon,
      'materialsNeeded': [
        {'item': loc.fallbackCompost, 'purpose': loc.fallbackCompostPurpose},
        {'item': loc.fallbackMulch, 'purpose': loc.fallbackMulchPurpose},
        {
          'item': loc.fallbackWateringCan,
          'purpose': loc.fallbackWateringCanPurpose,
        },
        {
          'item': loc.fallbackNeemSpray,
          'purpose': loc.fallbackNeemSprayPurpose,
        },
      ],
      'growthStages': [
        {
          'stage': loc.fallbackStageSeedling,
          'startDay': 1,
          'endDay': 14,
          'description': loc.fallbackStageSeedlingDesc,
        },
        {
          'stage': loc.fallbackStageVegetative,
          'startDay': 15,
          'endDay': 45,
          'description': loc.fallbackStageVegetativeDesc,
        },
        {
          'stage': loc.fallbackStageFlowering,
          'startDay': 46,
          'endDay': 75,
          'description': loc.fallbackStageFloweringDesc,
        },
        {
          'stage': loc.fallbackStageMaturity,
          'startDay': 76,
          'endDay': 120,
          'description': loc.fallbackStageMaturityDesc,
        },
      ],
    };
  }

  String _weatherCodeToCondition(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 49) return 'Foggy';
    if (code <= 59) return 'Drizzle';
    if (code <= 69) return 'Rainy';
    if (code <= 79) return 'Snowy';
    if (code <= 84) return 'Showers';
    return 'Stormy';
  }

  String _getDetailedInfo(String key) {
    if (!mounted) return '';
    final loc = AppLocalizations.of(context);
    final plantName = loc.getLocalizedPlantName(
      widget.plant['name'] as String? ?? 'Plant',
    );
    final location = _locationName;

    switch (key) {
      case 'growthTime':
        return loc.growthTimeDetail(
          location,
          _temperature.toStringAsFixed(1),
          plantName,
        );

      case 'difficulty':
        return loc.difficultyDetail(plantName, location);

      case 'sunlight':
        return loc.sunlightDetail(location);

      case 'watering':
        return loc.wateringDetail(
          _weatherCondition,
          _temperature.toStringAsFixed(1),
        );

      case 'soil':
        return loc.soilDetail(location);

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and name
                  _buildHeader(),
                  const SizedBox(height: 16),

                  // Location info banner
                  if (_locationName == 'Malaysia')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).saveLocationForAdvice,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_locationName == 'Malaysia') const SizedBox(height: 16),

                  // AI SECTION 1: Local Match Score
                  if (_aiAdvice != null) ...[
                    _buildLocalMatchScore(_aiAdvice!['localMatchScore']),
                    const SizedBox(height: 16),
                  ],

                  // AI SECTION 2: Local Growing Context
                  if (_aiAdvice != null) ...[
                    _buildLocalGrowingContext(_aiAdvice!['growingContext']),
                    const SizedBox(height: 16),
                  ],

                  // Description
                  _buildSection(
                    AppLocalizations.of(context).aboutLabel,
                    AppLocalizations.of(context).getLocalizedPlantDescription(
                      widget.plant['name'] as String,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AI SECTION 3: AI-Enhanced Growing Guide
                  _buildAIGrowingGuide(),
                  const SizedBox(height: 24),

                  // AI SECTION 3.5: Growth Stages Timeline
                  if (_aiAdvice != null && _aiAdvice!['growthStages'] != null)
                    _buildGrowthStagesTimeline(_aiAdvice!['growthStages']),
                  if (_aiAdvice != null && _aiAdvice!['growthStages'] != null)
                    const SizedBox(height: 24),

                  // AI SECTION 3.6: Materials Needed
                  if (_aiAdvice != null &&
                      _aiAdvice!['materialsNeeded'] != null)
                    _buildMaterialsNeeded(_aiAdvice!['materialsNeeded']),
                  if (_aiAdvice != null &&
                      _aiAdvice!['materialsNeeded'] != null)
                    const SizedBox(height: 24),

                  // AI SECTION 4: Carbon Reduction
                  if (_aiAdvice != null) ...[
                    _buildCarbonReduction(_aiAdvice!['carbonReduction']),
                    const SizedBox(height: 16),
                  ],

                  // Loading state
                  if (_isLoadingAI)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F8E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFF2E7D32),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).aiAnalyzingLocalConditions,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onAddToGarden();
                      },
                      icon: const Icon(Icons.add),
                      label: Text(AppLocalizations.of(context).addToMyGarden),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildHeader() {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.plant['color'] as Color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (widget.plant['color'] as Color).withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.plant['icon'] as IconData,
                color: Colors.white,
                size: 40,
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: GestureDetector(
                onTap: widget.onAddToGarden,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).getLocalizedPlantName(widget.plant['name'] as String),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.plant['scientificName'],
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _localizeLabel(widget.plant['category']),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // AI SECTION 1: Local Match Score
  Widget _buildLocalMatchScore(int score) {
    Color scoreColor;
    String scoreLabel;
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = AppLocalizations.of(context).excellentMatch;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = AppLocalizations.of(context).goodMatch;
    } else {
      scoreColor = Colors.red;
      scoreLabel = AppLocalizations.of(context).challengingMatch;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.1), scoreColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).localClimateMatch,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  scoreLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).forLocation(_locationName),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Icon(Icons.eco, color: scoreColor, size: 32),
        ],
      ),
    );
  }

  // AI SECTION 2: Local Growing Context
  Widget _buildLocalGrowingContext(String adviceContext) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2E7D32).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).localGrowingContext,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            adviceContext,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).currentTempWeather(
              _temperature.toStringAsFixed(1),
              _weatherCondition,
            ),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // AI SECTION 3: AI-Enhanced Growing Guide
  Widget _buildAIGrowingGuide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_florist, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).growingGuide,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            if (_aiAdvice != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    const Text(
                      'AI Powered',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        _buildInfoCard(
          Icons.schedule,
          AppLocalizations.of(context).growthTimeLabel,
          'growthTime',
          _aiAdvice?['growthTime'] ?? '',
        ),
        _buildInfoCard(
          Icons.trending_up,
          AppLocalizations.of(context).difficulty,
          'difficulty',
          _aiAdvice?['difficulty'] ?? '',
        ),
        _buildInfoCard(
          Icons.wb_sunny,
          AppLocalizations.of(context).sunlight,
          'sunlight',
          _aiAdvice?['sunlight'] ?? '',
        ),
        _buildInfoCard(
          Icons.water_drop,
          AppLocalizations.of(context).watering,
          'watering',
          _aiAdvice?['watering'] ?? '',
        ),
        _buildInfoCard(
          Icons.landscape,
          AppLocalizations.of(context).soil,
          'soil',
          _aiAdvice?['soil'] ?? '',
        ),
      ],
    );
  }

  // AI SECTION 3.5: Growth Stages Timeline
  Widget _buildGrowthStagesTimeline(dynamic rawStages) {
    final List<Map<String, dynamic>> stages = [];
    if (rawStages is List) {
      for (final item in rawStages) {
        if (item is Map<String, dynamic>) {
          final int? start = item['startDay'] is int
              ? item['startDay'] as int
              : int.tryParse('${item['startDay']}');
          final int? end = item['endDay'] is int
              ? item['endDay'] as int
              : int.tryParse('${item['endDay']}');
          final String stage = (item['stage'] ?? '').toString().trim();
          final String desc = (item['description'] ?? '').toString().trim();
          if (start != null && end != null && stage.isNotEmpty) {
            stages.add({
              'stage': stage,
              'startDay': start,
              'endDay': end,
              'description': desc,
            });
          }
        }
      }
    }

    if (stages.isEmpty) return const SizedBox.shrink();

    stages.sort(
      (a, b) => (a['startDay'] as int).compareTo(b['startDay'] as int),
    );

    final int totalDays = stages.last['endDay'] as int;

    const List<Color> stageColors = [
      Color(0xFF8D6E63), // brown - seed
      Color(0xFF66BB6A), // light green - sprout
      Color(0xFF43A047), // green - vegetative
      Color(0xFFFFB300), // amber - flowering
      Color(0xFFEF5350), // red - fruiting
      Color(0xFFAB47BC), // purple - ripening
      Color(0xFF26A69A), // teal - harvest
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, color: Color(0xFF2E7D32), size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).growthStages,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  const Text(
                    'AI Powered',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Total: $totalDays days',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 16),

        // Proportional color bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 14,
            child: Row(
              children: List.generate(stages.length, (i) {
                final s = stages[i];
                final int days =
                    (s['endDay'] as int) - (s['startDay'] as int) + 1;
                final double fraction = days / totalDays;
                return Expanded(
                  flex: (fraction * 1000).round().clamp(1, 1000),
                  child: Container(color: stageColors[i % stageColors.length]),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stage timeline cards
        ...List.generate(stages.length, (i) {
          final s = stages[i];
          final color = stageColors[i % stageColors.length];
          final int startDay = s['startDay'] as int;
          final int endDay = s['endDay'] as int;
          final int days = endDay - startDay + 1;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: dot + vertical line
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (i < stages.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right: card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s['stage'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Day $startDay\u2013$endDay',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((s['description'] as String).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            s['description'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '$days days',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // AI SECTION 3.6: Materials Needed
  Widget _buildMaterialsNeeded(dynamic rawMaterials) {
    if (rawMaterials == null || rawMaterials is! List || rawMaterials.isEmpty) {
      return const SizedBox.shrink();
    }

    final materials = rawMaterials.cast<Map<String, dynamic>>();

    IconData _materialIcon(String item) {
      final lower = item.toLowerCase();
      if (lower.contains('seed')) return Icons.grain;
      if (lower.contains('fertiliz') ||
          lower.contains('compost') ||
          lower.contains('manure'))
        return Icons.science;
      if (lower.contains('pot') ||
          lower.contains('container') ||
          lower.contains('tray'))
        return Icons.inventory_2;
      if (lower.contains('water') ||
          lower.contains('hose') ||
          lower.contains('can'))
        return Icons.water_drop;
      if (lower.contains('soil') ||
          lower.contains('mulch') ||
          lower.contains('peat'))
        return Icons.terrain;
      if (lower.contains('trellis') ||
          lower.contains('stake') ||
          lower.contains('support'))
        return Icons.vertical_align_top;
      if (lower.contains('net') ||
          lower.contains('cover') ||
          lower.contains('shade'))
        return Icons.shield;
      if (lower.contains('prun') ||
          lower.contains('scissor') ||
          lower.contains('shear'))
        return Icons.content_cut;
      if (lower.contains('pesticide') ||
          lower.contains('spray') ||
          lower.contains('insect'))
        return Icons.bug_report;
      if (lower.contains('shovel') ||
          lower.contains('spade') ||
          lower.contains('tool') ||
          lower.contains('hoe'))
        return Icons.handyman;
      return Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.amber[800], size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).materialsNeeded,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 12,
                      color: Colors.amber[800],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Powered',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: materials.map<Widget>((m) {
              final item = (m['item'] as String?) ?? '';
              final purpose = (m['purpose'] as String?) ?? '';
              return Tooltip(
                message: purpose,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade100),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _materialIcon(item),
                        size: 16,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B5E20),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (purpose.isNotEmpty)
                              Text(
                                purpose,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // AI SECTION 4: Carbon Reduction
  Widget _buildCarbonReduction(String carbonText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).carbonImpact,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  carbonText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String key,
    String? value,
  ) {
    // Only show card if value exists and is not empty
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }

    final isExpanded = _expandedCards.contains(key);
    final detailedInfo = _getDetailedInfo(key);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedCards.remove(key);
          } else {
            _expandedCards.add(key);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isExpanded ? Color(0xFFE8F5E9) : Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExpanded ? Color(0xFF2E7D32) : Colors.transparent,
            width: isExpanded ? 2 : 0,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Color(0xFF2E7D32),
                  size: 24,
                ),
              ],
            ),
            if (isExpanded && detailedInfo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  detailedInfo,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
