import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:flutter/material.dart';

import '../models/match_filters.dart';
import '../services/matching_service.dart';
import 'supabase_providers.dart';
import 'user_provider.dart';

final matchResultsProvider = FutureProvider<List<MatchResult>>((ref) async {
  final matchingService = ref.watch(matchingServiceProvider);
  final profileAsync = ref.watch(currentUserProfileProvider);

  final profile = profileAsync.maybeWhen(data: (profile) => profile, orElse: () => null);
  final uid = profile?.id;
  if (uid == null) return [];
  return matchingService.fetchRankedMatches(uid);
});

final matchFiltersProvider = StateNotifierProvider<MatchFiltersNotifier, MatchFilters>((ref) {
  return MatchFiltersNotifier();
});

final filteredMatchesProvider = Provider<AsyncValue<List<MatchResult>>>((ref) {
  final filters = ref.watch(matchFiltersProvider);
  final matchesAsync = ref.watch(matchResultsProvider);
  final currentUserAsync = ref.watch(currentUserProfileProvider);
  
  // Get current user for mutual matching
  final currentUser = currentUserAsync.maybeWhen(data: (user) => user, orElse: () => null);

  return matchesAsync.whenData((matches) {
    // Apply filters with mutual matching
    var filtered = matches.where((match) => filters.matches(match.profile, currentUser)).toList();
    
    // Apply additional distance filter from UI slider only when set AND
    // not explicitly filtering for on-campus-only housing. When the user
    // chooses on-campus housing preference, we want on-campus matches even
    // if they are beyond the max distance.
    final shouldApplyDistanceFilter =
        filters.maxDistanceMiles != null && filters.housingPreference != 'on_campus';

    if (shouldApplyDistanceFilter) {
      filtered = filtered.where((match) {
        if (match.distanceMiles == null) return true; // Keep if no distance data
        return match.distanceMiles! <= filters.maxDistanceMiles!;
      }).toList();
    }
    
    // Apply sorting
    if (filters.sortBy == MatchSortBy.newest) {
      filtered.sort(
        (a, b) => (b.profile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.profile.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    } else if (filters.sortBy == MatchSortBy.distance) {
      filtered.sort((a, b) {
        // Put profiles without distance at the end
        if (a.distanceMiles == null && b.distanceMiles == null) return 0;
        if (a.distanceMiles == null) return 1;
        if (b.distanceMiles == null) return -1;
        return a.distanceMiles!.compareTo(b.distanceMiles!);
      });
    }
    
    return filtered;
  });
});

class MatchFiltersNotifier extends StateNotifier<MatchFilters> {
  MatchFiltersNotifier() : super(const MatchFilters());

  void updateFilters(MatchFilters filters) {
    state = filters;
  }

  void patchFilters(MatchFilters Function(MatchFilters current) updater) {
    state = updater(state);
  }

  void reset() {
    state = const MatchFilters();
  }
}
