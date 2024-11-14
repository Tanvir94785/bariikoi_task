import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maplibre_gl/maplibre_gl.dart';

// class SearchMap extends StatefulWidget {
//   @override
//  Search createState() => SearchMapState();

// }

// class _SearchMapState extends State<SearchMap> {
// TextEditingController _searchController = TextEditingController();
// MaplibreMapController? _mapController;
// List<Map<String, dynamic>> _searchResults = [];

// static const String _mapUrl = 'https://map.barikoi.com/styles/osm-liberty/style.json?key=YOUR_API_KEY';

// Future<void> _searchPlace(String query) async {
//   final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5');
//   final response = await http.get(url);

//   if (response.statusCode == 200) {
//     List<dynamic> data = json.decode(response.body);
//     setState(() {
//       _searchResults = data.map((item) {
//         return {
//           'name': item['display_name'],
//           'lat': double.parse(item['lat']),
//           'lon': double.parse(item['lon']),
//         };
//       }).toList();
//     });
//   } else {
//     print('Failed to load search results');
//   }
// }

// void _onPlaceSelected(Map<String, dynamic> place) {
//   double lat = place['lat'];
//   double lon = place['lon'];
//   LatLng position = LatLng(lat, lon);

//   if (_mapController != null) {
//     _mapController!.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
//     _mapController!.addSymbol(SymbolOptions(
//       geometry: position,
//       iconImage: 'marker-icon',
//     ));
//   }

//   print('Selected place: ${place['name']}');
// }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Search and Select Location')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               decoration: InputDecoration(
//                 hintText: 'Search for a place',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.search),
//                   onPressed: () {
//                     if (_searchController.text.isNotEmpty) {
//                       _searchPlace(_searchController.text);
//                     }
//                   },
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _searchResults.length,
//               itemBuilder: (context, index) {
//                 final place = _searchResults[index];
//                 return Column(
//                   children: [
//                     ListTile(
//                       title: Text(place['name'],),

//                       onTap: () => _onPlaceSelected(place),
//                     ),
//                     Divider(color: Colors.orange,)
//                   ],
//                 );
//               },
//             ),
//           ),
//           Expanded(
//             child: MaplibreMap(
//               initialCameraPosition: CameraPosition(target: LatLng(23.835677, 90.380325), zoom: 12),
//               onMapCreated: (controller) {
//                 _mapController = controller;
//               },
//               styleString: _mapUrl,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//import 'package:flutter/material.dart';

// ignore: non_constant_identifier_names
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  TextEditingController _searchController = TextEditingController();
  MaplibreMapController? _mapController;
  List<Map<String, dynamic>> _searchResults = [];

  static const String _mapUrl =
      'https://map.barikoi.com/styles/osm-liberty/style.json?key=YOUR_API_KEY';

  Future<void> _searchPlace(String query) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        _searchResults = data.map((item) {
          return {
            'name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          };
        }).toList();
      });
    } else {
      print('Failed to load search results');
    }
  }

  void _onPlaceSelected(Map<String, dynamic> place) {
    double lat = place['lat'];
    double lon = place['lon'];
    LatLng position = LatLng(lat, lon);

    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
      _mapController!.addSymbol(SymbolOptions(
        geometry: position,
        iconImage: 'marker-icon',
      ));
    }

    print('Selected place: ${place['name']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search and Select Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _searchPlace(_searchController.text);
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        place['name'],
                      ),
                      onTap: () => _onPlaceSelected(place),
                    ),
                    Divider(
                      color: Colors.orange,
                    )
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: MaplibreMap(
              initialCameraPosition: CameraPosition(
                  target: LatLng(23.835677, 90.380325), zoom: 12),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              styleString: _mapUrl,
            ),
          ),
        ],
      ),
    );
  }
}
