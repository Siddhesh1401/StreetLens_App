import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/issue_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'complaint_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _firestoreService = FirestoreService();
  final _locationService = LocationService();
  final _mapController = MapController();
  LatLng _currentPosition = const LatLng(19.0760, 72.8777); // Mumbai default

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _setCurrentLocation();
    }
  }

  Future<void> _setCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition, 14);
    }
  }

  Color _markerColor(String status) {
    if (status == 'Resolved') return Colors.green;
    if (status == 'In Progress') return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Issue Map',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              const Text(
                'Map View',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Map view is available on the mobile app.',
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                'Please use the Android app to view issue locations.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue Map',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _setCurrentLocation,
            tooltip: 'Go to my location',
          ),
        ],
      ),
      body: StreamBuilder<List<IssueModel>>(
        stream: _firestoreService.getAllIssues(),
        builder: (context, snapshot) {
          final issues = snapshot.data ?? [];

          final markers = issues
              .where((i) => i.latitude != 0 && i.longitude != 0)
              .map((issue) {
            return Marker(
              point: LatLng(issue.latitude, issue.longitude),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComplaintDetailScreen(issue: issue),
                  ),
                ),
                child: Tooltip(
                  message:
                      '${issue.category}: ${issue.description.length > 30 ? issue.description.substring(0, 30) + '...' : issue.description}',
                  child: Icon(
                    Icons.location_pin,
                    color: _markerColor(issue.status),
                    size: 36,
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 4)
                    ],
                  ),
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.streetlens.streetlens_app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
              // Legend
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendItem(color: Colors.red, label: 'Pending'),
                      SizedBox(height: 4),
                      _LegendItem(color: Colors.orange, label: 'In Progress'),
                      SizedBox(height: 4),
                      _LegendItem(color: Colors.green, label: 'Resolved'),
                    ],
                  ),
                ),
              ),
              // OSM attribution (required by OpenStreetMap license)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  color: Colors.white70,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: const Text('© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
