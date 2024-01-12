import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase'i başlat
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Map Application',
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController mapController = MapController();
  List<LatLng> buildingCoordinates = [];
  String selectedDamageType = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Map'),
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: LatLng(38.329579, 38.447752),
          zoom: 15.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayerOptions(
            polylines: [
              Polyline(
                points: buildingCoordinates,
                color: Colors.blue,
                strokeWidth: 3.0,
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBuildingDialog(); // Yeni bina eklemek için iletişim penceresini göster
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddBuildingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Building'),
          content: Column(
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Building Name'),
              ),
              SizedBox(height: 10),
              _buildDamageTypeDropdown(), // Hasar türü seçimini içeren dropdown
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addBuildingToFirestore(); // Firestore'a bina eklemeyi dene
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDamageTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Damage Type', style: TextStyle(fontSize: 16)),
        SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedDamageType,
          onChanged: (String? newValue) {
            setState(() {
              selectedDamageType = newValue ?? '';
            });
          },
          items: <String>['', 'Light Damage', 'Moderate Damage', 'Severe Damage']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a damage type';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _addBuildingToFirestore() {
    FirebaseFirestore.instance.collection('buildings').add({
      'name': 'Building Name', // Bu kısmı textfield'dan alınan değere dönüştür
      'damageType': selectedDamageType,
      'coordinates': _convertLatLngToGeoPoint(buildingCoordinates),
    }).then((value) {
      setState(() {
        buildingCoordinates = [];
      });
      _fetchBuildingsFromFirestore(); // Firestore'dan binaları al ve haritada göster
    });
  }

  void _fetchBuildingsFromFirestore() {
    FirebaseFirestore.instance.collection('buildings').get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        var data = doc.data();
        var coordinates = _convertGeoPointToLatLng(data['coordinates']);
        setState(() {
          buildingCoordinates.addAll(coordinates);
        });
      });
    });
  }

  List<LatLng> _convertGeoPointToLatLng(GeoPoint geoPoint) {
    return [LatLng(geoPoint.latitude, geoPoint.longitude)];
  }

  GeoPoint _convertLatLngToGeoPoint(List<LatLng> latLngList) {
    return GeoPoint(latLngList.first.latitude, latLngList.first.longitude);
  }
}
