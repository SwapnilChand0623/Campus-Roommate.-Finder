import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/database_service.dart';
import 'supabase_providers.dart';

// Listen to Supabase auth state changes so we can refresh user-dependent
// providers (like currentUserProfileProvider) when the logged-in user
// changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  // Rebuild this provider whenever the auth state changes, so switching
  // accounts does not keep showing the previous user's profile.
  ref.watch(authStateProvider);

  final db = ref.watch(databaseServiceProvider);
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;
  return db.fetchCurrentUserProfile(uid);
});

final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  final db = ref.watch(databaseServiceProvider);
  return db.fetchUserById(userId);
});

final profileCompletionProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentUserProfileProvider).maybeWhen(
        data: (profile) => profile,
        orElse: () => null,
      ) ??
      null;
  return profile?.profileCompleted ?? false;
});
