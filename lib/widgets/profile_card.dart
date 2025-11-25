import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../models/user_profile.dart';
import 'preference_chips.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    this.compatibilityScore,
    this.distanceMiles,
    this.onTap,
    this.onFavorite,
    this.onMessage,
    this.heroTag,
  });

  final UserProfile profile;
  final double? compatibilityScore;
  final double? distanceMiles;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onMessage;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final highlights = _buildHighlights();
    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PhotoSection(
            photoUrl: profile.photoUrl,
            housingStatus: profile.housingStatus,
            compatibilityScore: compatibilityScore,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [profile.fullName, if (profile.age != null) '${profile.age}'].join(', '),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (profile.pronouns != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              profile.pronouns!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text('${profile.major ?? 'Undeclared'} · ${profile.year ?? 'Year TBD'}'),
                          if (profile.city != null || distanceMiles != null) const SizedBox(height: 2),
                          if (profile.city != null || distanceMiles != null)
                            Text(
                              [
                                if (profile.city != null) profile.city,
                                if (distanceMiles != null) '${distanceMiles!.round()} mi away',
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Compatibility badge moved to photo overlay
                  ],
                ),
                const SizedBox(height: 8),
                if (highlights.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PreferenceChips(items: highlights, icon: Icons.style_rounded),
                  ),
                Text(
                  profile.bio?.isNotEmpty == true
                      ? profile.bio!
                      : 'Add a short bio to let other students know about you.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (onFavorite != null)
                      IconButton(onPressed: onFavorite, icon: const Icon(Icons.favorite_border), tooltip: 'Favorite'),
                    if (onMessage != null)
                      IconButton(
                        onPressed: onMessage,
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        tooltip: 'Message',
                      ),
                  ],
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final wrappedCard = heroTag == null ? card : Hero(tag: heroTag!, child: card);
    
    return GestureDetector(
      onTap: onTap,
      child: wrappedCard
          .animate()
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut),
    );
  }

  List<String> _buildHighlights() {
    final highlights = <String>[];
    if ((profile.studyHabits ?? '').isNotEmpty) highlights.add(profile.studyHabits!);
    if ((profile.personalityType ?? '').isNotEmpty) highlights.add(profile.personalityType!);
    if (profile.budgetMin != null && profile.budgetMax != null) {
      final formatter = NumberFormat.currency(symbol: r'$');
      highlights.add('${formatter.format(profile.budgetMin)} – ${formatter.format(profile.budgetMax)}');
    }
    return highlights;
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.photoUrl,
    required this.housingStatus,
    this.compatibilityScore,
  });

  final String? photoUrl;
  final String housingStatus;
  final double? compatibilityScore;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      height: 260,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: .08),
      child: const Center(child: Icon(Icons.person, size: 64)),
    );

    // Keep original image behavior
    if (photoUrl == null || photoUrl!.isEmpty) {
      return SizedBox(
        height: 260,
        child: Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            _buildBadge(),
          ],
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: photoUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => placeholder,
            errorWidget: (_, __, ___) => placeholder,
          ),
          // Gradient overlay for better text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          _buildBadge(),
          if (compatibilityScore != null) _buildCompatibilityBadge(),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    return Positioned(
      top: 12,
      right: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: housingStatus == 'on_campus'
                  ? const Color(0xFF8B7FD9).withOpacity(0.85)
                  : const Color(0xFFB8B0E8).withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  housingStatus == 'on_campus' ? Icons.school_rounded : Icons.home_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  housingStatus == 'on_campus' ? 'On Campus' : 'Off Campus',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: 200.ms, duration: 400.ms)
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildCompatibilityBadge() {
    return Positioned(
      top: 12,
      left: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B7FD9).withOpacity(0.9),
                  const Color(0xFF6C63D6).withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B7FD9).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  '${compatibilityScore!.toStringAsFixed(0)}% Match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .fadeIn(delay: 300.ms, duration: 400.ms)
          .scale(begin: const Offset(0.8, 0.8))
          .then()
          .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
    );
  }
}
