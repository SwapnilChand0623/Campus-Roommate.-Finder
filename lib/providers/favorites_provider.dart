import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import 'supabase_providers.dart';

final favoritesProvider = AsyncNotifierProvider<FavoritesController, List<UserProfile>>(
  FavoritesController.new,
);

class FavoritesController extends AsyncNotifier<List<UserProfile>> {
  @override
  Future<List<UserProfile>> build() async {
    final db = ref.watch(databaseServiceProvider);
    return db.fetchFavoriteProfiles();
  }

  Future<void> addFavorite(String userId) async {
    final db = ref.read(databaseServiceProvider);
    await db.addFavorite(userId);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => db.fetchFavoriteProfiles());
  }

  Future<void> removeFavorite(String userId) async {
    final db = ref.read(databaseServiceProvider);
    await db.removeFavorite(userId);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => db.fetchFavoriteProfiles());
  }

  bool isFavorite(String userId) {
    final favorites = state.maybeWhen(data: (data) => data, orElse: () => const <UserProfile>[]);
    return favorites.any((profile) => profile.id == userId);
  }
}
