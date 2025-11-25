import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/university.dart';

final universitiesProvider = FutureProvider<List<University>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/images/universities.json');
  final dynamic data = jsonDecode(jsonStr);

  if (data is! List) {
    return const <University>[];
  }

  final List<dynamic> list = data;

  return list
      .whereType<Map<String, dynamic>>()
      .map(University.fromJson)
      .where((u) => u.name.isNotEmpty && u.hasDomains)
      .toList();
});

class SelectedUniversityNotifier extends StateNotifier<University?> {
  SelectedUniversityNotifier() : super(null);
}

final selectedUniversityProvider =
    StateNotifierProvider<SelectedUniversityNotifier, University?>((ref) {
  return SelectedUniversityNotifier();
});
