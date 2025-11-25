import 'dart:math';

import '../models/user_profile.dart';
import 'database_service.dart';
import 'geocoding_service.dart';

class MatchingService {
  MatchingService(this._databaseService);

  final DatabaseService _databaseService;

  Future<List<MatchResult>> fetchRankedMatches(String uid) async {
    final profiles = await _databaseService.fetchMatches(uid);
    final likedIds = await _databaseService.fetchLikedUserIds(uid);
    final candidateProfiles = profiles.where((profile) => !likedIds.contains(profile.id)).toList();
    final currentProfile = await _databaseService.fetchCurrentUserProfile(uid);
    if (currentProfile == null) return [];

    // Filter by user's housing preference
    // (Housing filtering is now handled by MatchFilters / Filters screen.)
    final filteredByHousing = candidateProfiles;

    // Filter by distance if location data is available
    final filteredByDistance = filteredByHousing.where((profile) {
      // If the current user is specifically looking for on-campus roommates
      // and this profile is on-campus, do NOT restrict by distance. Campus
      // roommates should be discoverable even if city/zip differ.
      if (currentProfile.housingPreference == 'on_campus' && profile.housingStatus == 'on_campus') {
        return true;
      }

      // Skip distance filter if either user doesn't have location data
      if (currentProfile.latitude == null || currentProfile.longitude == null ||
          profile.latitude == null || profile.longitude == null) {
        return true;
      }

      // Calculate distance between users
      final distance = GeocodingService.calculateDistance(
        currentProfile.latitude!,
        currentProfile.longitude!,
        profile.latitude!,
        profile.longitude!,
      );

      // Check if within both users' max distance preferences
      final maxDistance = min(currentProfile.maxDistanceMiles, profile.maxDistanceMiles);
      return true;
    }).toList();

    return filteredByDistance
        .map((profile) {
          // Calculate distance for display
          double? distance;
          if (currentProfile.latitude != null && currentProfile.longitude != null &&
              profile.latitude != null && profile.longitude != null) {
            distance = GeocodingService.calculateDistance(
              currentProfile.latitude!,
              currentProfile.longitude!,
              profile.latitude!,
              profile.longitude!,
            );
          }
          
          return MatchResult(
            profile: profile,
            compatibilityScore: _calculateScore(currentProfile, profile),
            distanceMiles: distance,
          );
        })
        .toList()
      ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
  }

  double _calculateScore(UserProfile current, UserProfile other) {
    double score = 0;
    double totalWeight = 0;

    void addScore(double weight, double value) {
      score += weight * value;
      totalWeight += weight;
    }

    // Cleanliness match (20%)
    addScore(0.2, _sliderMatch(current.cleanliness, other.cleanliness));

    // Sleep schedule (15%)
    addScore(0.15, _stringMatch(current.sleepSchedule, other.sleepSchedule));

    // Noise tolerance (10%)
    addScore(0.1, _sliderMatch(current.noiseTolerance, other.noiseTolerance));

    // Smoking / pets (10%)
    addScore(0.05, _stringMatch(current.smoking, other.smoking));
    addScore(0.05, _stringMatch(current.pets, other.pets));

    // Budget overlap (15%)
    addScore(0.15, _budgetOverlap(current, other));

    // Personality type (10%)
    addScore(0.1, _stringMatch(current.personalityType, other.personalityType));

    // Study habits (10%)
    addScore(0.1, _stringMatch(current.studyHabits, other.studyHabits));

    // Guest preference (5%)
    addScore(0.05, _stringMatch(current.guests, other.guests));

    // Major/year similarity (5%)
    addScore(0.025, _stringMatch(current.major, other.major));
    addScore(0.025, _stringMatch(current.year, other.year));

    return (totalWeight == 0 ? 0 : (score / totalWeight)) * 100;
  }

  double _sliderMatch(int? a, int? b) {
    if (a == null || b == null) return 0.5;
    final diff = (a - b).abs();
    return max(0, 1 - (diff / 4));
  }

  double _stringMatch(String? a, String? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) return 0.5;
    return a.toLowerCase() == b.toLowerCase() ? 1 : 0;
  }

  double _budgetOverlap(UserProfile a, UserProfile b) {
    if (a.budgetMin == null || a.budgetMax == null || b.budgetMin == null || b.budgetMax == null) {
      return 0.5;
    }

    final overlapStart = max<double>(a.budgetMin!.toDouble(), b.budgetMin!.toDouble());
    final overlapEnd = min<double>(a.budgetMax!.toDouble(), b.budgetMax!.toDouble());
    if (overlapEnd <= overlapStart) return 0;

    final aRange = (a.budgetMax! - a.budgetMin!).toDouble().abs();
    final bRange = (b.budgetMax! - b.budgetMin!).toDouble().abs();
    if (aRange == 0 || bRange == 0) return 0.5;

    final overlap = overlapEnd - overlapStart;
    final maxRange = max(aRange, bRange);
    return overlap / maxRange;
  }
}

class MatchResult {
  MatchResult({
    required this.profile,
    required this.compatibilityScore,
    this.distanceMiles,
  });

  final UserProfile profile;
  final double compatibilityScore;
  final double? distanceMiles;
}
