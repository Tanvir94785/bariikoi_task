import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Enhanced Location Map',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: EnhancedMap(),
    );
  }
}

class EnhancedMap extends StatefulWidget {
  @override
  State<EnhancedMap> createState() => _EnhancedMapState();
}

class _EnhancedMapState extends State<EnhancedMap> {
  CameraPosition initialPosition = const CameraPosition(
    target: LatLng(23.835677, 90.380325),
    zoom: 12,
  );
  MaplibreMapController? mController;
  LatLng? _currentLocation;

  static const styleId = 'osm-liberty';
  static const apiKey =
      'bkoi_7fd35604c8ed0d1e2e295ec851c16a2d45d8e3a34a8ec92f5f6e0b99efb27c45';
  static const mapUrl =
      'https://map.barikoi.com/styles/$styleId/style.json?key=$apiKey&sprite=https://your-server-url.com/assets/sprites/sprite';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Fetch current location and move map camera
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _currentLocation = currentLatLng;

      if (mController != null) {
        mController!
            .animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 14));

        // Add a custom marker at the current location
        mController!.addSymbol(SymbolOptions(
          geometry: currentLatLng,
          iconImage: 'location',
          iconSize: 2.0,
        ));
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // Handle map click to show location name and draw polyline
  void _onMapClick(Point<double> point, LatLng coordinates) async {
    if (_currentLocation == null) return;

    // Fetch location name
    String locationName = await _getLocationName(coordinates);

    // Show location name
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Location Details"),
          content: Text("Location: $locationName"),
          actions: <Widget>[
            TextButton(
              child: Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    // Draw a polyline from current location to the selected location
    await mController?.addLine(LineOptions(
      geometry: [_currentLocation!, coordinates],
      lineColor: "#ff0000",
      lineWidth: 3.0,
      lineOpacity: 0.6,
    ));
  }

  // Fetch location name using Barikoi reverse geolocation API
  Future<String> _getLocationName(LatLng coordinates) async {
    final url =
        'https://barikoi.com/api/search/reverse/geocode/server/bkoi_7fd35604c8ed0d1e2e295ec851c16a2d45d8e3a34a8ec92f5f6e0b99efb27c45/place?longitude=${coordinates.longitude}&latitude=${coordinates.latitude}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['place']['name'] ?? "Unknown location";
    } else {
      print('Failed to fetch location name');
      return "Unknown location";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MaplibreMap(
        initialCameraPosition: initialPosition,
        onMapCreated: (MaplibreMapController mapController) {
          mController = mapController;
          _getCurrentLocation();
          mController!.onMapClick?.add(_onMapClick); // Listen for map clicks
        },
        styleString: mapUrl,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

extension on OnMapClickCallback? {
  void add(void Function(Point<double> point, LatLng coordinates) onMapClick) {}
}
