import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../providers/match_provider.dart';
import '../providers/user_provider.dart';
import '../screens/map_view_screen.dart';

class EmbeddedMapWidget extends ConsumerWidget {
  const EmbeddedMapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final matchesAsync = ref.watch(filteredMatchesProvider);
    final filters = ref.watch(matchFiltersProvider);

    final currentProfile = profileAsync.maybeWhen(
      data: (profile) => profile,
      orElse: () => null,
    );

    if (currentProfile?.latitude == null || currentProfile?.longitude == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Add your zip code to see map',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return matchesAsync.when(
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(child: Text('Error loading map')),
      ),
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
            width: 40,
            height: 40,
            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
          ),
          // Match markers (red) - smaller and simpler
          ...matchesWithLocation.map((match) {
            return Marker(
              point: LatLng(match.profile.latitude!, match.profile.longitude!),
              width: 30,
              height: 30,
              child: const Icon(Icons.location_on, color: Colors.red, size: 30),
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
            borderStrokeWidth: 2,
          ),
        ];

        return GestureDetector(
          onTap: () {
            // Open full map screen
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapViewScreen()),
            );
          },
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                AbsorbPointer(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(currentProfile.latitude!, currentProfile.longitude!),
                      initialZoom: 10.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
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
                ),
                // Overlay with info
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${matchesWithLocation.length} nearby',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tap to expand hint
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.zoom_out_map, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'Tap to expand',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
