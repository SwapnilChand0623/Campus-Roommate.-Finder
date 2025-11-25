import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/database_service.dart';
import 'supabase_providers.dart';
import 'user_provider.dart';

final matchesProvider = FutureProvider<List<UserProfile>>((ref) async {
  final db = ref.watch(databaseServiceProvider);
  final profileAsync = ref.watch(currentUserProfileProvider);

  final profile = profileAsync.maybeWhen(data: (p) => p, orElse: () => null);
  final uid = profile?.id;
  if (uid == null) return [];

  return db.fetchMutualMatches(uid);
});
