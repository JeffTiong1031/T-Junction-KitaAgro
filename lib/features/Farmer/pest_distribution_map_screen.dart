import 'package:flutter/material.dart';
import '../../core/services/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:typed_data';

// 👉 Make sure this import path matches exactly where you saved the new screen!
import 'my_reports_screen.dart';

class PestDistributionMapScreen extends StatefulWidget {
  const PestDistributionMapScreen({super.key});

  @override
  State<PestDistributionMapScreen> createState() =>
      _PestDistributionMapScreenState();
}

class _PestDistributionMapScreenState extends State<PestDistributionMapScreen> {
  // Filter the stream to only show "active" outbreaks for the map polygons
  final Stream<QuerySnapshot> _pestStream = FirebaseFirestore.instance
      .collection('pest_reports')
      .where('status', isEqualTo: 'active')
      .snapshots();

  // Separate stream to fetch the 5 most recent reports (any status) for the top card list
  final Stream<QuerySnapshot> _recentReportsStream = FirebaseFirestore.instance
      .collection('pest_reports')
      .orderBy('timestamp', descending: true)
      .limit(5)
      .snapshots();

  GoogleMapController? _mapController;
  bool _hasLocationPermission = false;

  static final CameraTargetBounds _malaysiaBounds = CameraTargetBounds(
    LatLngBounds(
      southwest: const LatLng(0.8, 99.6),
      northeast: const LatLng(7.5, 119.3),
    ),
  );

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(4.2105, 101.9758),
    zoom: 14,
  );

  // Store raw bytes instead of BitmapDescriptor to avoid the type mismatch
  Uint8List? customWindArrowBytes;

  @override
  void initState() {
    super.initState();
    _loadWindArrow();
    _requestPermissionOnLoad();
  }

  // The bulletproof image loader
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<void> _loadWindArrow() async {
    try {
      final Uint8List markerIcon = await getBytesFromAsset(
        'assets/images/wind_arrow.png',
        200,
      );
      setState(() {
        customWindArrowBytes = markerIcon;
      });
    } catch (e) {
      print("Error loading custom arrow bytes: $e");
    }
  }

  Future<void> _requestPermissionOnLoad() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (!_hasLocationPermission) return;
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error getting location for map: $e");
    }
  }

  // The popup dialog to clear the outbreak
  void _showClearOutbreakDialog(String docId) {
    // save the state context so we can show SnackBar later
    final BuildContext parentContext = context;
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).clearOutbreakTitle),
        content: Text(AppLocalizations.of(context).clearOutbreakContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close the dialog
              // Update the database to hide it!
              await FirebaseFirestore.instance
                  .collection('pest_reports')
                  .doc(docId)
                  .update({'status': 'cleared'});
              // use the outer context (not the dialog's) for the snackbar
              if (mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(parentContext).outbreakCleared,
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).yesClearIt),
          ),
        ],
      ),
    );
  }

  List<LatLng> _createWindEllipse(
    LatLng center,
    double radiusY,
    double radiusX,
    double windAngleDegrees,
  ) {
    List<LatLng> points = [];
    const double earthRadius = 6378137.0;
    final double radAngle = windAngleDegrees * (math.pi / 180);

    for (int i = 0; i <= 360; i += 10) {
      final double t = i * (math.pi / 180);
      final double x = radiusX * math.cos(t);
      final double y = radiusY * math.sin(t);

      // Clockwise rotation matrix to fix the crisscrossing shapes
      final double xRotated = x * math.cos(radAngle) + y * math.sin(radAngle);
      final double yRotated = -x * math.sin(radAngle) + y * math.cos(radAngle);

      final double dLat = yRotated / earthRadius;
      final double dLng =
          xRotated / (earthRadius * math.cos(math.pi * center.latitude / 180));
      points.add(
        LatLng(
          center.latitude + (dLat * 180 / math.pi),
          center.longitude + (dLng * 180 / math.pi),
        ),
      );
    }
    return points;
  }

  LatLng _calculateArrowPosition(
    LatLng center,
    double distanceInMeters,
    double bearingDegrees,
  ) {
    const double earthRadius = 6378137.0;
    final double radBearing = bearingDegrees * (math.pi / 180.0);
    final double dx = distanceInMeters * math.sin(radBearing);
    final double dy = distanceInMeters * math.cos(radBearing);
    final double dLat = dy / earthRadius;
    final double dLng =
        dx / (earthRadius * math.cos(center.latitude * math.pi / 180.0));
    return LatLng(
      center.latitude + (dLat * 180.0 / math.pi),
      center.longitude + (dLng * 180.0 / math.pi),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).pestDistributionMap),
        // 👉 NEW: Add the history button to the top right of the map
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: AppLocalizations.of(context).myReportsTitle,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyReportsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).recentPestAlerts,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _recentReportsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context).errorLoadingAlerts,
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context).noRecentAlerts,
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final String pestName = data['pestName'] ?? 'Unknown';
                          final String severity = data['severity'] ?? 'Unknown';
                          final GeoPoint? loc = data['location'];
                          final bool cleared =
                              (data['status'] ?? '') == 'cleared';

                          Color color;
                          switch (severity.toLowerCase()) {
                            case 'low':
                              color = Colors.yellow;
                              break;
                            case 'medium':
                              color = Colors.orange;
                              break;
                            case 'high':
                            default:
                              color = Colors.red;
                          }

                          // create widget that resolves geocoding
                          Widget alertWidget;
                          if (loc != null) {
                            // show coordinates initially, then replace with city/state when available
                            alertWidget = FutureBuilder<List<Placemark>>(
                              future: placemarkFromCoordinates(
                                loc.latitude,
                                loc.longitude,
                              ),
                              builder: (ctx, snap) {
                                String locationStr =
                                    'Lat: ${loc.latitude.toStringAsFixed(2)}, Lng: ${loc.longitude.toStringAsFixed(2)}';
                                if (snap.connectionState ==
                                    ConnectionState.done) {
                                  if (snap.hasData && snap.data!.isNotEmpty) {
                                    final pl = snap.data![0];
                                    String city = pl.locality ?? '';
                                    String state = pl.administrativeArea ?? '';
                                    if (city.isNotEmpty || state.isNotEmpty) {
                                      locationStr =
                                          '${city.isNotEmpty ? city : ''}${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}${state}';
                                    }
                                  }
                                }
                                return _buildPestAlert(
                                  pestName,
                                  locationStr,
                                  severity,
                                  color,
                                  Icons.bug_report,
                                  cleared: cleared,
                                );
                              },
                            );
                          } else {
                            alertWidget = _buildPestAlert(
                              pestName,
                              AppLocalizations.of(context).locationUnknown,
                              severity,
                              color,
                              Icons.bug_report,
                              cleared: cleared,
                            );
                          }

                          return alertWidget;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _pestStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context).networkError,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    Set<Polygon> polygons = {};
                    Set<Marker> markers = {};
                    Set<GroundOverlay> groundOverlays = {};

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        try {
                          var data = doc.data() as Map<String, dynamic>;
                          GeoPoint? loc = data['location'];
                          num windSpeedNum = data['windSpeed'] ?? 0;
                          num windAngleNum = data['windAngle'] ?? 0;
                          double windSpeed = windSpeedNum.toDouble();
                          double windAngle = windAngleNum.toDouble();
                          String pestName = data['pestName'] ?? 'Unknown Pest';
                          String severity = data['severity'] ?? 'low';

                          if (loc != null) {
                            LatLng center = LatLng(loc.latitude, loc.longitude);
                            String docId = doc.id;
                            double windStretch = windSpeed * 20.0;

                            // Weather APIs state where wind comes FROM. Flip 180 degrees to show where pests blow TO.
                            double downwindAngle = (windAngle + 180) % 360;

                            // Check ownership of the report
                            String currentUserId =
                                FirebaseAuth.instance.currentUser?.uid ?? '';
                            String reporterId = data['reporterId'] ?? '';
                            bool isMyReport =
                                reporterId == currentUserId &&
                                currentUserId.isNotEmpty;

                            // 1. Draw Polygons using downwindAngle
                            polygons.add(
                              Polygon(
                                polygonId: PolygonId("${docId}_safe"),
                                points: _createWindEllipse(
                                  center,
                                  500 + windStretch,
                                  500,
                                  downwindAngle,
                                ),
                                strokeWidth: 0,
                                fillColor: Colors.green.withOpacity(0.2),
                              ),
                            );
                            polygons.add(
                              Polygon(
                                polygonId: PolygonId("${docId}_warning"),
                                points: _createWindEllipse(
                                  center,
                                  200 + (windStretch * 0.5),
                                  200,
                                  downwindAngle,
                                ),
                                strokeWidth: 0,
                                fillColor: Colors.orange.withOpacity(0.5),
                              ),
                            );
                            polygons.add(
                              Polygon(
                                polygonId: PolygonId("${docId}_danger"),
                                points: _createWindEllipse(
                                  center,
                                  50 + (windStretch * 0.1),
                                  50,
                                  downwindAngle,
                                ),
                                strokeWidth: 0,
                                fillColor: Colors.red.withOpacity(0.8),
                              ),
                            );

                            // 2. Add Red Pin Marker
                            // choose hue based on threat level
                            double hue;
                            switch (severity.toLowerCase()) {
                              case 'low':
                                hue = BitmapDescriptor.hueYellow;
                                break;
                              case 'medium':
                                hue = BitmapDescriptor.hueOrange;
                                break;
                              case 'high':
                              default:
                                hue = BitmapDescriptor.hueRed;
                            }

                            markers.add(
                              Marker(
                                markerId: MarkerId("${docId}_pin"),
                                position: center,
                                infoWindow: InfoWindow(
                                  title: '🚨 $pestName',
                                  // Change text and logic based on ownership
                                  snippet: isMyReport
                                      ? AppLocalizations.of(context).tapToClear
                                      : AppLocalizations.of(
                                          context,
                                        ).reportedOutbreakCenter,
                                  onTap: () {
                                    if (isMyReport) {
                                      _showClearOutbreakDialog(docId);
                                    }
                                  },
                                ),
                                icon: BitmapDescriptor.defaultMarkerWithHue(
                                  hue,
                                ),
                              ),
                            );

                            // 3. Add Wind Arrow using downwindAngle
                            if (windSpeed > 0 && customWindArrowBytes != null) {
                              LatLng arrowPosition = _calculateArrowPosition(
                                center,
                                300,
                                downwindAngle,
                              );

                              groundOverlays.add(
                                GroundOverlay.fromPosition(
                                  groundOverlayId: GroundOverlayId(
                                    "${docId}_arrow_overlay",
                                  ),
                                  image: BytesMapBitmap(
                                    customWindArrowBytes!,
                                    bitmapScaling: MapBitmapScaling.none,
                                  ),
                                  position: arrowPosition,
                                  width: 600,
                                  bearing: downwindAngle,
                                  anchor: const Offset(0.5, 0.5),
                                  transparency: 0.2,
                                  zIndex: 1,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print("Error parsing data: $e");
                        }
                      }
                    }

                    return GoogleMap(
                      initialCameraPosition: _initialPosition,
                      polygons: polygons,
                      markers: markers,
                      groundOverlays: groundOverlays,
                      cameraTargetBounds: _malaysiaBounds,
                      minMaxZoomPreference: const MinMaxZoomPreference(5, 18),
                      myLocationEnabled: _hasLocationPermission,
                      myLocationButtonEnabled: _hasLocationPermission,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _goToCurrentLocation();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPestAlert(
    String name,
    String region,
    String severity,
    Color color,
    IconData icon, {
    bool cleared = false,
  }) {
    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(region),
        trailing: Chip(
          label: Text(severity),
          backgroundColor: color.withOpacity(0.2),
          labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );

    if (cleared) {
      return Stack(
        children: [
          card,
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.7),
              alignment: Alignment.center,
              child: Text(
                AppLocalizations.of(context).cleared,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return card;
  }
}
