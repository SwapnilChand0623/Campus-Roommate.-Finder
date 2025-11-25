import 'package:flutter/material.dart';

import 'user_profile.dart';

enum MatchSortBy { compatibility, newest, distance }

class MatchFilters {
  const MatchFilters({
    this.minBudget,
    this.maxBudget,
    this.genderPreference,
    this.major,
    this.year,
    this.cleanlinessRange = const RangeValues(1, 5),
    this.noiseToleranceRange = const RangeValues(1, 5),
    this.smokingPreference,
    this.petsPreference,
    this.studyHabits,
    this.moveInStart,
    this.housingPreference,
    this.maxDistanceMiles,
    this.sortBy = MatchSortBy.compatibility,
  });

  final int? minBudget;
  final int? maxBudget;
  final String? genderPreference;
  final String? major;
  final String? year;
  final RangeValues cleanlinessRange;
  final RangeValues noiseToleranceRange;
  final String? smokingPreference;
  final String? petsPreference;
  final String? studyHabits;
  final DateTime? moveInStart;
  final String? housingPreference; // 'on_campus', 'off_campus', or null for either
  final int? maxDistanceMiles; // Maximum distance in miles for matches
  final MatchSortBy sortBy;

  MatchFilters copyWith({
    int? minBudget,
    int? maxBudget,
    String? genderPreference,
    String? major,
    String? year,
    RangeValues? cleanlinessRange,
    RangeValues? noiseToleranceRange,
    String? smokingPreference,
    String? petsPreference,
    String? studyHabits,
    DateTime? moveInStart,
    String? housingPreference,
    int? maxDistanceMiles,
    MatchSortBy? sortBy,
    bool resetGenderPreference = false,
    bool resetMajor = false,
    bool resetYear = false,
    bool resetSmoking = false,
    bool resetPets = false,
    bool resetStudyHabits = false,
    bool resetMoveInStart = false,
    bool resetHousingPreference = false,
    bool resetMaxDistance = false,
  }) {
    return MatchFilters(
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      genderPreference: resetGenderPreference ? null : (genderPreference ?? this.genderPreference),
      major: resetMajor ? null : (major ?? this.major),
      year: resetYear ? null : (year ?? this.year),
      cleanlinessRange: cleanlinessRange ?? this.cleanlinessRange,
      noiseToleranceRange: noiseToleranceRange ?? this.noiseToleranceRange,
      smokingPreference: resetSmoking ? null : (smokingPreference ?? this.smokingPreference),
      petsPreference: resetPets ? null : (petsPreference ?? this.petsPreference),
      studyHabits: resetStudyHabits ? null : (studyHabits ?? this.studyHabits),
      moveInStart: resetMoveInStart ? null : (moveInStart ?? this.moveInStart),
      housingPreference: resetHousingPreference ? null : (housingPreference ?? this.housingPreference),
      maxDistanceMiles: resetMaxDistance ? null : (maxDistanceMiles ?? this.maxDistanceMiles),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool matches(UserProfile profile, [UserProfile? currentUser]) {
    if (minBudget != null || maxBudget != null) {
      final min = profile.budgetMin;
      final max = profile.budgetMax;
      if (min == null || max == null) {
        return false;
      }
      if (minBudget != null && max < minBudget!) return false;
      if (maxBudget != null && min > maxBudget!) return false;
    }

    // NEW BIDIRECTIONAL ROOMMATE PREFERENCE MATCHING
    // Both users must be able to see each other based on their preferences
    if (currentUser != null) {
      // Check 1: Can I (currentUser) see them (profile)?
      if (!_canUserSeeProfile(currentUser, profile)) {
        return false;
      }
      
      // Check 2: Can they (profile) see me (currentUser)?
      if (!_canUserSeeProfile(profile, currentUser)) {
        return false;
      }
    }

    if (major != null && major!.trim().isNotEmpty) {
      if ((profile.major ?? '').toLowerCase() != major!.trim().toLowerCase()) {
        return false;
      }
    }

    if (year != null && year!.isNotEmpty && profile.year != year) {
      return false;
    }

    if (_isValueOutsideRange(profile.cleanliness?.toDouble(), cleanlinessRange)) {
      return false;
    }

    if (_isValueOutsideRange(profile.noiseTolerance?.toDouble(), noiseToleranceRange)) {
      return false;
    }

    if (smokingPreference != null && smokingPreference!.isNotEmpty) {
      if ((profile.smoking ?? '').toLowerCase() != smokingPreference!.toLowerCase()) {
        return false;
      }
    }

    if (petsPreference != null && petsPreference!.isNotEmpty) {
      if ((profile.pets ?? '').toLowerCase() != petsPreference!.toLowerCase()) {
        return false;
      }
    }

    if (studyHabits != null && studyHabits!.isNotEmpty) {
      if ((profile.studyHabits ?? '').toLowerCase() != studyHabits!.toLowerCase()) {
        return false;
      }
    }

    if (moveInStart != null) {
      final moveIn = profile.moveInDate;
      if (moveIn == null) return false;
      if (moveIn.isBefore(moveInStart!)) return false;
    }

    // Housing preference filter
    if (housingPreference != null && housingPreference!.isNotEmpty) {
      // Normalize values so legacy strings like 'on campus' and 'off campus'
      // still match the newer 'on_campus' / 'off_campus' values.
      String normalize(String value) => value.replaceAll('_', '').replaceAll(' ', '').toLowerCase();

      final profileStatus = normalize(profile.housingStatus);
      final filterStatus = normalize(housingPreference!);

      if (profileStatus != filterStatus) {
        return false;
      }
    }

    return true;
  }

  bool _isValueOutsideRange(double? value, RangeValues range) {
    if (value == null) return false;
    return value < range.start || value > range.end;
  }

  /// NEW BIDIRECTIONAL VISIBILITY LOGIC
  /// Checks if viewer can see target based on viewer's preference
  static bool _canUserSeeProfile(UserProfile viewer, UserProfile target) {
    final viewerPref = viewer.roommatePreference;
    final targetGender = target.gender;
    
    // If viewer has no preference set or 'any', they can see everyone
    if (viewerPref == null || viewerPref == 'any') {
      return true;
    }
    
    // If target has no gender set, don't show them (incomplete profile)
    if (targetGender == null) {
      return false;
    }
    
    // Apply preference rules:
    // 'male_only' -> only see males
    // 'female_only' -> only see females
    if (viewerPref == 'male_only') {
      return targetGender == 'male';
    } else if (viewerPref == 'female_only') {
      return targetGender == 'female';
    }
    
    return true;
  }
}
