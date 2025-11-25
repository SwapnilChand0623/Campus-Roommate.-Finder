import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/favorites_provider.dart';
import '../providers/match_provider.dart';
import '../providers/matches_provider.dart';
import '../providers/supabase_providers.dart';
import '../providers/user_provider.dart';
import '../widgets/profile_card.dart';
import 'chat_room.dart';
import 'profile_view.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final matchesAsync = ref.watch(matchesProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load favorites: $error')),
      data: (favorites) {
        final theme = Theme.of(context);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Matches', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            matchesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('Unable to load matches: $error'),
              data: (matches) {
                if (matches.isEmpty) {
                  return const Text(
                    'No matches yet. When you and another student both tap Interested, you\'ll see them here.',
                  );
                }

                return Column(
                  children: [
                    for (final profile in matches) ...[
                      ProfileCard(
                        profile: profile,
                        heroTag: 'match-${profile.id}',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileViewScreen(userId: profile.id)),
                        ),
                        onFavorite: () {
                          ref.read(favoritesProvider.notifier).addFavorite(profile.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to favorites')),
                          );
                        },
                        onMessage: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              partnerId: profile.id,
                              partnerName: profile.fullName,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            final db = ref.read(databaseServiceProvider);
                            final currentUserAsync = ref.read(currentUserProfileProvider);
                            final currentUser = currentUserAsync.maybeWhen(
                              data: (user) => user,
                              orElse: () => null,
                            );
                            
                            if (currentUser != null) {
                              try {
                                print('Unmatching: ${currentUser.id} with ${profile.id}');
                                
                                // Remove match from BOTH sides
                                await db.removeMatch(currentUser.id, profile.id);
                                
                                print('Database unmatch complete, invalidating providers');
                                
                                // Invalidate providers to force refresh
                                ref.invalidate(matchesProvider);
                                ref.invalidate(matchResultsProvider);
                                ref.invalidate(filteredMatchesProvider);
                                
                                // Wait a moment for providers to refresh
                                await Future.delayed(const Duration(milliseconds: 300));
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Match removed from both sides. Pull down to refresh swipe feed.'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('Error unmatching: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error removing match: $e')),
                                  );
                                }
                              }
                            }
                          },
                          icon: const Icon(Icons.block),
                          label: const Text('Unmatch'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text('My Favorites', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (favorites.isEmpty)
              const Text('No favorites yet. Add some from the match feed!')
            else
              Column(
                children: [
                  for (final profile in favorites) ...[
                    ProfileCard(
                      profile: profile,
                      heroTag: 'favorite-${profile.id}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProfileViewScreen(userId: profile.id)),
                      ),
                      onFavorite: () {
                        ref.read(favoritesProvider.notifier).removeFavorite(profile.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Removed from favorites')),
                        );
                      },
                      onMessage: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomScreen(
                            partnerId: profile.id,
                            partnerName: profile.fullName,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}
