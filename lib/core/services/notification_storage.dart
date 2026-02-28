import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// 1. The Blueprint for a saved notification
class AppNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead; // 👉 NEW: Track if the user has seen it to control the red dot

  AppNotification({
    required this.title, 
    required this.body, 
    required this.timestamp,
    this.isRead = false, 
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  // Convert from JSON when loading
  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    title: json['title'],
    body: json['body'],
    timestamp: DateTime.parse(json['timestamp']),
    isRead: json['isRead'] ?? false,
  );
}

// 2. The Storage Engine
class NotificationStorage {
  static const String _key = 'saved_notifications';

  // Save a new notification to the top of the list
  static Future<void> saveNotification(AppNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationsList = prefs.getStringList(_key) ?? [];
    
    notificationsList.insert(0, jsonEncode(notification.toJson())); 
    
    // Keep only the 50 most recent notifications to save memory
    if (notificationsList.length > 50) {
      notificationsList = notificationsList.sublist(0, 50);
    }
    
    await prefs.setStringList(_key, notificationsList);
  }

  // Load all notifications for the Bell Icon screen
  static Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationsList = prefs.getStringList(_key) ?? [];
    
    return notificationsList
        .map((str) => AppNotification.fromJson(jsonDecode(str)))
        .toList();
  }

  // Check how many are unread (for the red dot)
  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  // Mark all as read when the user opens the notification screen
  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<AppNotification> notifications = await getNotifications();
    
    List<String> updatedList = notifications.map((n) {
      n.isRead = true; // Mark it as read
      return jsonEncode(n.toJson());
    }).toList();
    
    await prefs.setStringList(_key, updatedList);
  }

  // Clear all notifications
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
