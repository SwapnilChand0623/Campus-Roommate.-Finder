import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/match_provider.dart';
import '../providers/matches_provider.dart';
import '../providers/supabase_providers.dart';
import '../widgets/profile_card.dart';
import '../services/matching_service.dart';
import 'profile_view.dart';

class MatchFeedScreen extends ConsumerStatefulWidget {
  const MatchFeedScreen({super.key});

  @override
  ConsumerState<MatchFeedScreen> createState() => _MatchFeedScreenState();
}

class _MatchFeedScreenState extends ConsumerState<MatchFeedScreen> with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  final Set<String> _skippedIds = {}; // Track skipped profiles

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Reset index when widget is created
    _currentIndex = 0;
  }

  void _refreshFeed() {
    // Force refresh providers and reset index
    ref.invalidate(matchResultsProvider);
    setState(() {
      _currentIndex = 0;
      _skippedIds.clear(); // Clear skips on manual refresh
    });
  }

  Future<void> _handleSwipe({required bool liked, required MatchResult match}) async {
    var showMatchDialog = false;

    if (liked) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final db = ref.read(databaseServiceProvider);
        await db.likeUser(currentUser.id, match.profile.id);
        final isMutual = await db.isMutualLike(currentUser.id, match.profile.id);
        ref.invalidate(matchesProvider);
        ref.invalidate(matchResultsProvider);
        if (isMutual) {
          showMatchDialog = true;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You liked ${match.profile.fullName}! (interest saved)')),
      );
    } else {
      // User skipped - add to skipped list
      _skippedIds.add(match.profile.id);
      print('Skipped ${match.profile.fullName} (${match.profile.id})');
    }

    if (showMatchDialog && mounted) {
      await _showItsAMatchDialog(match);
    }

    if (mounted) {
      setState(() => _currentIndex += 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final matchesAsync = ref.watch(filteredMatchesProvider);

    return matchesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load matches: $error')),
      data: (matches) {
        // Filter out skipped profiles
        final unskippedMatches = matches
            .where((match) => !_skippedIds.contains(match.profile.id))
            .toList();
        
        // Debug: print match count
        print('MatchFeed: ${matches.length} total, ${unskippedMatches.length} unskipped, current index: $_currentIndex, skipped: ${_skippedIds.length}');
        
        // Reset index if it's out of bounds (happens after unmatch)
        if (_currentIndex >= unskippedMatches.length && unskippedMatches.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentIndex = 0;
              });
            }
          });
        }
        
        if (unskippedMatches.isEmpty) {
          return _buildEmptyState();
        }

        if (_currentIndex >= unskippedMatches.length) {
          return _buildAllCaughtUp();
        }

        final match = unskippedMatches[_currentIndex];
        final nextMatch = _currentIndex + 1 < unskippedMatches.length ? unskippedMatches[_currentIndex + 1] : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              // Show refresh button if skipped profiles exist
              if (_skippedIds.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You\'ve skipped ${_skippedIds.length} profile${_skippedIds.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _refreshFeed,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Show again'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (nextMatch != null)
                      Transform.translate(
                        offset: const Offset(0, 12),
                        child: Transform.scale(
                          scale: 0.96,
                          child: ProfileCard(
                            profile: nextMatch.profile,
                            compatibilityScore: nextMatch.compatibilityScore,
                            distanceMiles: nextMatch.distanceMiles,
                          )
                              .animate()
                              .fade(duration: 250.ms, begin: 0.3, end: 0.8)
                              .scale(duration: 250.ms, begin: const Offset(0.95, 0.95), end: const Offset(0.96, 0.96)),
                        ),
                      ),
                    Dismissible(
                      key: ValueKey(match.profile.id),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        final liked = direction == DismissDirection.startToEnd;
                        _handleSwipe(liked: liked, match: match);
                      },
                      child: ProfileCard(
                        profile: match.profile,
                        compatibilityScore: match.compatibilityScore,
                        distanceMiles: match.distanceMiles,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileViewScreen(userId: match.profile.id),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap the card to see more details',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleSwipe(liked: false, match: match),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleSwipe(liked: true, match: match),
                      icon: const Icon(Icons.favorite),
                      label: const Text('Interested'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showItsAMatchDialog(MatchResult match) async {
    final theme = Theme.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          backgroundColor: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text("It's a match!",
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'You and ${match.profile.fullName} both tapped Interested.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Keep swiping'),
                  ),
                ],
              ),
            )
                .animate()
                .scale(
                  duration: 300.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                )
                .fadeIn(duration: 250.ms),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_rounded, size: 64),
            const SizedBox(height: 16),
            Text(
              'No more profiles',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _skippedIds.isNotEmpty 
                ? 'You\'ve skipped ${_skippedIds.length} profiles.'
                : 'Update your filters to see more potential roommates.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_skippedIds.isNotEmpty)
              FilledButton.icon(
                onPressed: _refreshFeed,
                icon: const Icon(Icons.refresh),
                label: const Text('Show skipped profiles'),
              ),
            if (_skippedIds.isNotEmpty) const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.read(matchFiltersProvider.notifier).reset(),
              child: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCaughtUp() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, size: 64),
            const SizedBox(height: 16),
            Text(
              'You’re all caught up! 🎉',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _skippedIds.isNotEmpty
                ? 'You skipped ${_skippedIds.length} profiles.'
                : 'Check back later as new students join.',
              textAlign: TextAlign.center,
            ),
            if (_skippedIds.isNotEmpty) const SizedBox(height: 16),
            if (_skippedIds.isNotEmpty)
              FilledButton.icon(
                onPressed: _refreshFeed,
                icon: const Icon(Icons.refresh),
                label: const Text('Show skipped profiles'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showProfilePreview(MatchResult match) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(match.profile.fullName, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('${match.profile.major ?? 'Undeclared'} · ${match.profile.year ?? 'Year TBD'}'),
                  const SizedBox(height: 16),
                  Text(match.profile.bio ?? 'No bio yet.'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Message (coming soon)'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
