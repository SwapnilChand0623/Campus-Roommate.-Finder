import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/match_provider.dart';
import '../providers/user_provider.dart';
import '../services/matching_service.dart';
import 'profile_view.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final matchesAsync = ref.watch(filteredMatchesProvider);
    final filters = ref.watch(matchFiltersProvider);

    final currentProfile = profileAsync.maybeWhen(
      data: (profile) => profile,
      orElse: () => null,
    );

    if (currentProfile?.latitude == null || currentProfile?.longitude == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Map View'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Location not available',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Please add your zip code in your profile to see the map view.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on my location',
            onPressed: () {
              if (currentProfile?.latitude != null && currentProfile?.longitude != null) {
                _mapController.move(
                  LatLng(currentProfile!.latitude!, currentProfile.longitude!),
                  12.0,
                );
              }
            },
          ),
        ],
      ),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (matches) {
          // Filter matches with location data
          final matchesWithLocation = matches.where((match) {
            return match.profile.latitude != null && match.profile.longitude != null;
          }).toList();

          // Create markers
          final markers = <Marker>[
            // Current user marker (blue)
            Marker(
              point: LatLng(currentProfile!.latitude!, currentProfile.longitude!),
              width: 60,
              height: 60,
              child: GestureDetector(
                onTap: () {
                  _showInfoDialog(
                    context,
                    'You',
                    currentProfile.city ?? 'Unknown',
                    null,
                    true,
                  );
                },
                child: const Column(
                  children: [
                    Icon(Icons.person_pin, color: Colors.blue, size: 40),
                    Text(
                      'You',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Match markers (red)
            ...matchesWithLocation.map((match) {
              return Marker(
                point: LatLng(match.profile.latitude!, match.profile.longitude!),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileViewScreen(userId: match.profile.id),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 40),
                          if (match.distanceMiles != null)
                            Positioned(
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red, width: 1),
                                ),
                                child: Text(
                                  '${match.distanceMiles!.round()}',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          match.profile.fullName.split(' ').first,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ];

          // Create circle for current user's max distance
          // Use filter's max distance if set, otherwise use profile's default
          final displayDistance = filters.maxDistanceMiles ?? currentProfile.maxDistanceMiles;
          final circles = <CircleMarker>[
            CircleMarker(
              point: LatLng(currentProfile.latitude!, currentProfile.longitude!),
              radius: displayDistance * 1609.34, // miles to meters
              useRadiusInMeter: true,
              color: Colors.blue.withOpacity(0.15),
              borderColor: Colors.blue.withOpacity(0.5),
              borderStrokeWidth: 3,
            ),
          ];

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(currentProfile.latitude!, currentProfile.longitude!),
                  initialZoom: 11.0,
                  minZoom: 8.0,
                  maxZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.campus_roommate_finder',
                  ),
                  CircleLayer(circles: circles),
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_pin, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text('Your location'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text('Matches (${matchesWithLocation.length})'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              border: Border.all(color: Colors.blue.withOpacity(0.3), width: 2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('$displayDistance mi range'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String name, String city, double? distance, bool isCurrentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 $city'),
            if (distance != null) Text('📏 ${distance.round()} miles away'),
            if (isCurrentUser) const Text('👤 This is you'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
