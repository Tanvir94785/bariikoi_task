import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mapppp/search_map.dart';

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
  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(23.835677, 90.380325),
    zoom: 12,
  );
  MaplibreMapController? _mapController;
  LatLng? _currentLocation;
  List<LatLng> _polylineCoordinates = [];

  static const String _styleId = 'osm-liberty';
  static const String _apiKey =
      'bkoi_7fd35604c8ed0d1e2e295ec851c16a2d45d8e3a34a8ec92f5f6e0b99efb27c45';
  static const String _mapUrl =
      'https://map.barikoi.com/styles/$_styleId/style.json?key=$_apiKey';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _currentLocation = currentLatLng;

      print('Current location: $currentLatLng');

      if (_mapController != null) {
        await _addImageFromAsset('icons', 'assets/images/icons.png');
        _mapController!
            .animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 14));

        _mapController!.addSymbol(SymbolOptions(
          geometry: currentLatLng,
          iconImage: 'icons',
        ));
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _addImageFromAsset(String name, String assetPath) async {
    final ByteData bytes = await rootBundle.load(assetPath);
    final Uint8List list = bytes.buffer.asUint8List();
    await _mapController!.addImage(name, list);
  }

  Future<void> _onMapTapped(LatLng tappedLatLng) async {
    if (_mapController == null) {
      print("Map controller is not initialized.");
      return;
    }

    print('Tapped location: $tappedLatLng');

    _mapController!.addSymbol(SymbolOptions(
      geometry: tappedLatLng,
      iconImage: 'icons',
      iconSize: 2.0,
    ));

    final address = await _getAddressFromLatLng(tappedLatLng);
    final distance = _calculateDistance(_currentLocation!, tappedLatLng);
    _showAddressInfo(address, distance);

    if (_currentLocation != null) {
      _polylineCoordinates = [_currentLocation!, tappedLatLng];

      _mapController!.addLine(LineOptions(
        geometry: _polylineCoordinates,
        lineColor: "#ff0000",
        lineWidth: 5.0,
        lineOpacity: 0.5,
      ));
    }
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final url =
          'https://api.barikoi.com/reverse?key=$_apiKey&lat=${latLng.latitude}&lon=${latLng.longitude}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result']['formatted_address'] ?? 'No address found';
      } else {
        print('Failed to load address.');
        return 'No address found';
      }
    } catch (e) {
      print('Error fetching address: $e');
      return 'Error fetching address';
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Radius in kilometers
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLon = _degreesToRadians(end.longitude - start.longitude);

    double a = pow(sin(dLat / 2), 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            pow(sin(dLon / 2), 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _showAddressInfo(String address, double distance) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Information'),
          content: Text(
              'Address: $address\nDistance: ${distance.toStringAsFixed(2)} km'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 9,
            child: MaplibreMap(
              myLocationEnabled: true,
              initialCameraPosition: _initialPosition,
              onMapCreated: (MaplibreMapController controller) {
                _mapController = controller;
                _getCurrentLocation();
              },
              styleString: _mapUrl,
              onMapClick: (point, latLng) {
                _onMapTapped(latLng);
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              height: 40,
              width: 200,
              decoration: BoxDecoration(
                  color: Colors.blueAccent, // Set background color
                  borderRadius: BorderRadius.all(
                      Radius.circular(15))), // Adjust height as needed
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // Keeps the Container color
                    shadowColor: Colors.transparent, // Removes button shadow
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MyWidget()),
                    );
                  },
                  child: Row(
                    children: [
                      Text('Search Location',
                          style: TextStyle(color: Colors.white)),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      )
                    ],
                  )),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
