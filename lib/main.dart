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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
