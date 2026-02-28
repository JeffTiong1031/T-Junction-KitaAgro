import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;
import 'notification_storage.dart'; 

class PestAlertService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final Set<String> _notifiedReportIds = {};

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);

    // 👉 NEW: Explicitly ask the user for notification permissions (Android 13+)
    await _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    _db.collection('pest_reports').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _processNewReport(change.doc);
        }
      }
    });
  }

  Future<void> _processNewReport(DocumentSnapshot doc) async {
    try {
      if (_notifiedReportIds.contains(doc.id)) return;
      _notifiedReportIds.add(doc.id);

      var data = doc.data() as Map<String, dynamic>;
      GeoPoint? pestLoc = data['location'];
      if (pestLoc == null) return;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (!serviceEnabled || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print("❌ Alert aborted: GPS is turned off or denied.");
        return; 
      }

      Position farmerPos = await Geolocator.getCurrentPosition();
      LatLng farmerLatLng = LatLng(farmerPos.latitude, farmerPos.longitude);
      LatLng pestLatLng = LatLng(pestLoc.latitude, pestLoc.longitude);

      double distanceInMeters = Geolocator.distanceBetween(
        farmerLatLng.latitude, farmerLatLng.longitude,
        pestLatLng.latitude, pestLatLng.longitude,
      );
      String distanceStr = (distanceInMeters / 1000).toStringAsFixed(1);

      double windSpeed = (data['windSpeed'] ?? 0).toDouble();
      double windAngle = (data['windAngle'] ?? 0).toDouble();
      String zoneInfo = _determineZone(farmerLatLng, pestLatLng, windSpeed, windAngle);

      // 👉 NEW: Print the exact math to the Debug Console
      print("🔍 NEW PEST REPORT DETECTED: ${data['pestName']}");
      print("   📍 Farmer GPS: ${farmerLatLng.latitude}, ${farmerLatLng.longitude}");
      print("   📍 Pest GPS: ${pestLatLng.latitude}, ${pestLatLng.longitude}");
      print("   📏 Distance: $distanceStr km");
      print("   ⚠️ Calculated Zone: $zoneInfo");

      String pestName = data['pestName'] ?? 'Unknown Pest';
      String aiAdvice = data['aiAdvice'] ?? 'Please take standard precautionary measures immediately.';

      _showNotification(pestName, distanceStr, zoneInfo, aiAdvice);

    } catch (e) {
      print("Error processing pest alert: $e");
    }
  }

  // 👉 The invisible math to draw the ellipses in memory
  List<LatLng> _createWindEllipse(LatLng center, double radiusY, double radiusX, double windAngleDegrees) {
    List<LatLng> points = [];
    const double earthRadius = 6378137.0;
    final double radAngle = windAngleDegrees * (math.pi / 180);

    for (int i = 0; i <= 360; i += 10) {
      final double t = i * (math.pi / 180);
      final double x = radiusX * math.cos(t);
      final double y = radiusY * math.sin(t);
      final double xRotated = x * math.cos(radAngle) - y * math.sin(radAngle);
      final double yRotated = x * math.sin(radAngle) + y * math.cos(radAngle);
      final double dLat = yRotated / earthRadius;
      final double dLng = xRotated / (earthRadius * math.cos(math.pi * center.latitude / 180));
      points.add(LatLng(center.latitude + (dLat * 180 / math.pi), center.longitude + (dLng * 180 / math.pi)));
    }
    return points;
  }

  // 👉 Classic Ray-Casting Algorithm to check if GPS is inside the polygon
  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) /
                      (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }

  // 👉 Check the zones from smallest (Danger) to largest (Safe)
  String _determineZone(LatLng farmer, LatLng pestCenter, double windSpeed, double windAngle) {
    double windStretch = windSpeed * 20.0;

    // Check Danger Zone first
    List<LatLng> dangerZone = _createWindEllipse(pestCenter, 50 + (windStretch * 0.1), 50, windAngle);
    if (_isPointInPolygon(farmer, dangerZone)) return "DANGER ZONE";

    // Check Warning Zone
    List<LatLng> warningZone = _createWindEllipse(pestCenter, 200 + (windStretch * 0.5), 200, windAngle);
    if (_isPointInPolygon(farmer, warningZone)) return "WARNING ZONE";

    // Check Safe/Monitoring Zone
    List<LatLng> safeZone = _createWindEllipse(pestCenter, 500 + windStretch, 500, windAngle);
    if (_isPointInPolygon(farmer, safeZone)) return "MONITORING ZONE";

    return "CLEAR"; // Farmer is outside the heatmap entirely
  }

  Future<void> _showNotification(String pestName, String distance, String zone, String advice) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pest_alerts_channel', 
      'Pest Outbreak Alerts',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''), // Allows multi-line text
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Skip alerting if the farmer is miles away and totally clear
    if (zone == "CLEAR") return; 

    // 👉 NEW: Define the text strings
    final String title = '🚨 $pestName Outbreak Nearby!';
    final String body = 'You are $distance km away ($zone).\nAdvice: $advice';

    // 👉 NEW: Save a copy to the phone's local memory instantly
    await NotificationStorage.saveNotification(
      AppNotification(title: title, body: body, timestamp: DateTime.now())
    );
    
    await _notificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID
      '🚨 $pestName Outbreak Nearby!',
      'You are $distance km away ($zone).\nAdvice: $advice',
      platformDetails,
    );
  }
}
