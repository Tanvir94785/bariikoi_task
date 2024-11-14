import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart';
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
  List<LatLng> polylineCoordinates = [];

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
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _currentLocation = currentLatLng;

      if (mController != null) {
        await _addImageFromAsset('icons', 'assets/images/icons.png');
        mController!
            .animateCamera(CameraUpdate.newLatLngZoom(currentLatLng, 14));

        // Add a custom marker at the current location
        mController!.addSymbol(SymbolOptions(
          geometry: currentLatLng,
          iconImage: 'icons',
          iconSize: 2.0,
        ));
      }
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  // Add image from asset to the map controller
  Future<void> _addImageFromAsset(String name, String assetPath) async {
    final ByteData bytes = await rootBundle.load(assetPath);
    final Uint8List list = bytes.buffer.asUint8List();
    await mController!.addImage(name, list);
  }

  // Handle map taps, fetch location name and draw polyline
  Future<void> _onMapTapped(LatLng tappedLatLng) async {
    if (mController == null) {
      print("Map controller is not yet initialized.");
      return;
    }

    // Add a marker on the tapped location
    mController!.addSymbol(SymbolOptions(
      geometry: tappedLatLng,
      iconImage: 'icons',
      iconSize: 2.0,
    ));

    // Get address using Barikoi reverse geolocation API
    final address = await _getAddressFromLatLng(tappedLatLng);
    _showAddressInfo(address);

    // Draw polyline from current location to tapped location
    if (_currentLocation != null) {
      polylineCoordinates.add(_currentLocation!);
      polylineCoordinates.add(tappedLatLng);

      mController!.addLine(LineOptions(
        geometry: polylineCoordinates,
        lineColor: "#ff0000", // Red color for the polyline
        lineWidth: 5.0, // Width of the line
        lineOpacity: 0.5, // Transparency of the line
      ));
    }
  }

  // Fetch address info using Barikoi reverse geolocation API
  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      final url =
          'https://api.barikoi.com/reverse?key=$apiKey&lat=${latLng.latitude}&lon=${latLng.longitude}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address =
            data['result']['formatted_address'] ?? 'No address found';
        return address;
      } else {
        print('Failed to load address');
        return 'No address found';
      }
    } catch (e) {
      print('Error fetching address: $e');
      return 'Error fetching address';
    }
  }

  // Show address info in a dialog or panel
  void _showAddressInfo(String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Address'),
          content: Text(address),
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
      body: MaplibreMap(
        myLocationEnabled: true,
        initialCameraPosition: initialPosition,
        onMapCreated: (MaplibreMapController mapController) {
          mController = mapController;
          _getCurrentLocation();
        },
        styleString: mapUrl,
        onTap: (LatLng tappedLatLng) {
          _onMapTapped(tappedLatLng);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
