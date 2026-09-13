import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapCard extends StatelessWidget {
  final Position? userPosition;
  final double latLab;
  final double longLab;

  const MapCard({
    super.key,
    required this.userPosition,
    required this.latLab,
    required this.longLab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(latLab, longLab),
              initialZoom: 15.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pi',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(latLab, longLab),
                    color: Colors.blue.withOpacity(0.2),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: 50,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(latLab, longLab),
                    child: const Icon(Icons.business, color: Colors.blue, size: 30),
                  ),
                  if (userPosition != null)
                    Marker(
                      point: LatLng(userPosition!.latitude, userPosition!.longitude),
                      child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}