import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

// Import necessary screens
import 'core/widgets/auth_wrapper.dart';

// Import the Pest Alert Service
import 'core/services/pest_alert_service.dart';

// 👉 NEW: Import Language Service & Localizations
import 'core/services/language_service.dart';
import 'core/services/app_localizations.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Cleanly initialized Firebase without conflict markers
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Start the Alert Engine to listen for new pest reports globally
  final pestAlertService = PestAlertService();
  await pestAlertService.initialize();

  // Initialize the language service
  final languageService = LanguageService();

  runApp(KitaAgroApp(languageService: languageService));
}

class KitaAgroApp extends StatelessWidget {
  final LanguageService languageService;
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  const KitaAgroApp({super.key, required this.languageService});

  @override
  Widget build(BuildContext context) {
    return LanguageServiceProvider(
      service: languageService,
      child: ListenableBuilder(
        listenable: languageService,
        builder: (context, child) {
          return MaterialApp(
            title: 'Kita Agro',
            debugShowCheckedModeBanner: false,
            locale: languageService.locale,
            navigatorObservers: [KitaAgroApp.observer],
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2E7D32), // Forest Green
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            // The Magic Switcher
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}
