import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kita_agro/core/services/notification_storage.dart';
import 'package:kita_agro/core/services/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAndMarkNotifications();
  }

  Future<void> _loadAndMarkNotifications() async {
    // 1. Load them
    final loaded = await NotificationStorage.getNotifications();
    setState(() {
      _notifications = loaded;
      _isLoading = false;
    });

    // 2. Mark them all as read immediately so the red dot on home screen vanishes
    await NotificationStorage.markAllAsRead();
  }

  Future<void> _clearNotifications() async {
    await NotificationStorage.clearAll();
    setState(() {
      _notifications = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).notifications),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: AppLocalizations.of(context).clearAll,
              onPressed: _clearNotifications,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context).noNewAlerts,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                final timeString = DateFormat(
                  'MMM d, h:mm a',
                ).format(notif.timestamp);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  // If it was unread, give it a slight red tint!
                  color: notif.isRead ? Colors.white : Colors.red.shade50,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notif.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif.body),
                        const SizedBox(height: 8),
                        Text(
                          timeString,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
