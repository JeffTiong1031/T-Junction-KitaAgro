import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
// Import wrapper screens
import 'features/Home/home_screen.dart';
import 'features/Farmer/farmer_screen.dart';
import 'features/Diagnostic/scan_feature.dart'; // Import the new ScanFeature
import 'features/Message/message_screen.dart';
import 'features/Profile/profile_screen.dart';
import 'services/chat_service.dart';
import 'core/services/app_localizations.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // Use late because we initialize it in initState using widget.initialIndex
  late int _selectedIndex;

  // The list of pages matching the icons below
  final List<Widget> _screens = [
    const HomeScreen(), // 0 - Home (Planting + Community)
    const FarmerScreen(), // 1 - Farmer (Rental + Map)
    const ScanFeature(), // 2 - Scan
    const MessageScreen(), // 3 - Message
    const ProfileScreen(), // 4 - Profile
  ];

  // Helper to ensure the index stays within bounds
  int _sanitizeIndex(int index) {
    if (index < 0 || index >= _screens.length) {
      return 0; // Default to Home if index is invalid
    }
    return index;
  }

  @override
  void initState() {
    super.initState();
    // Initialize the selection based on what was passed to the widget
    _selectedIndex = _sanitizeIndex(widget.initialIndex);
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent updates the initialIndex, update our local selection
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _selectedIndex = _sanitizeIndex(widget.initialIndex);
      });
    }
  }

  void _onItemTapped(int index) async {
    // Log Custom Events for specific Bottom Nav Tabs
    if (index == 1) {
      await FirebaseAnalytics.instance.logEvent(name: 'open_marketplace_map');
    } else if (index == 2) {
      await FirebaseAnalytics.instance.logEvent(name: 'open_ai_diagnostic_scan');
    }
    
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        indicatorColor: Colors.green.shade100,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: loc.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.agriculture_outlined),
            selectedIcon: const Icon(Icons.agriculture),
            label: loc.navFarmer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner),
            label: loc.navScan,
          ),
          NavigationDestination(
            icon: StreamBuilder<int>(
              stream: ChatService().getUnreadChatsCountStream(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count > 0) {
                  return Badge(
                    label: Text(count.toString()),
                    child: const Icon(Icons.mail_outlined),
                  );
                }
                return const Icon(Icons.mail_outlined);
              },
            ),
            selectedIcon: StreamBuilder<int>(
              stream: ChatService().getUnreadChatsCountStream(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count > 0) {
                  return Badge(
                    label: Text(count.toString()),
                    child: const Icon(Icons.mail),
                  );
                }
                return const Icon(Icons.mail);
              },
            ),
            label: loc.navMessage,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: loc.navProfile,
          ),
        ],
      ),
    );
  }
}
