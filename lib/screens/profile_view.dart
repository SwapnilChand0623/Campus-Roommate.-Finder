import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../providers/favorites_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_buttons.dart';
import 'chat_room.dart';
import 'edit_profile.dart';
import 'change_password_screen.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key, this.userId});

  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = userId == null
        ? ref.watch(currentUserProfileProvider)
        : ref.watch(userProfileProvider(userId!));

    return profileAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Unable to load profile: $error'))),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(body: Center(child: Text('Profile not found.')));
        }
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        final isCurrentUser = currentUserId != null && profile.id == currentUserId;
        final favoritesNotifier = ref.read(favoritesProvider.notifier);
        final isFavorite = isCurrentUser ? false : favoritesNotifier.isFavorite(profile.id);

        return Scaffold(
          appBar: AppBar(title: Text(isCurrentUser ? 'My Profile' : profile.fullName)),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                if (userId == null) {
                  ref.invalidate(currentUserProfileProvider);
                } else {
                  ref.invalidate(userProfileProvider(userId!));
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(profile: profile),
                    const SizedBox(height: 24),
                    _ProfileSection(title: 'About', children: _aboutSection(profile)),
                     const SizedBox(height: 24),
                     _ProfileSection(title: 'Me and My Room', children: _roomSection(profile)),
                    const SizedBox(height: 24),
                    _ProfileSection(title: 'Lifestyle & Preferences', children: _lifestyleSection(profile)),
                    const SizedBox(height: 24),
                    _ProfileSection(title: 'Budget & Logistics', children: _budgetSection(profile)),
                    const SizedBox(height: 24),
                    _ProfileSection(title: 'Social Links', children: _socialSection(profile)),
                    const SizedBox(height: 24),
                    _ProfileSection(title: 'Metadata', children: _metaSection(profile)),
                    const SizedBox(height: 32),
                    if (isCurrentUser) ...[
                      PrimaryButton(
                        label: 'Edit Profile',
                        icon: Icons.edit,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfileScreen(existingProfile: profile)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Change password'),
                      ),
                    ]
                    else ...[
                      FilledButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(partnerId: profile.id, partnerName: profile.fullName),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Message'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (isFavorite) {
                            favoritesNotifier.removeFavorite(profile.id);
                          } else {
                            favoritesNotifier.addFavorite(profile.id);
                          }
                        },
                        icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                        label: Text(isFavorite ? 'Remove Favorite' : 'Add to Favorites'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _aboutSection(UserProfile profile) {
    return [
      if (profile.universityName != null)
        _InfoRow(label: 'University', value: profile.universityName!),
      if (profile.city != null)
        _InfoRow(label: 'City', value: profile.city!),
      _InfoRow(label: 'Personality', value: profile.personalityType ?? 'Unknown'),
      _InfoRow(label: 'Study habits', value: profile.studyHabits ?? 'Unknown'),
      _InfoRow(label: 'Sleep schedule', value: profile.sleepSchedule ?? 'Unknown'),
      _InfoRow(label: 'Roommate expectations', value: profile.roommateExpectations ?? 'Not provided'),
    ];
  }

  List<Widget> _roomSection(UserProfile profile) {
  if (profile.roomPhotos.isEmpty) {
    return const [Text('No photos yet.')];
  }

  return [
    Builder(
      builder: (context) {
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: profile.roomPhotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final url = profile.roomPhotos[index];
              return GestureDetector(
                onTap: () {
                  showDialog<void>(
                    context: context,
                    barrierColor: Colors.black87,
                    builder: (dialogContext) {
                      final controller = PageController(initialPage: index);
                      return GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: PageView.builder(
                            controller: controller,
                            itemCount: profile.roomPhotos.length,
                            itemBuilder: (_, pageIndex) {
                              final pageUrl = profile.roomPhotos[pageIndex];
                              return InteractiveViewer(
                                child: Image.network(
                                  pageUrl,
                                  fit: BoxFit.contain,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  ];
}


List<Widget> _lifestyleSection(UserProfile profile) {
  return [
    _SliderDisplay(label: 'Cleanliness', value: profile.cleanliness),
    _SliderDisplay(label: 'Noise tolerance', value: profile.noiseTolerance),
    _InfoRow(label: 'Smoking', value: profile.smoking ?? 'Unknown'),
    _InfoRow(label: 'Pets', value: profile.pets ?? 'Unknown'),
    _InfoRow(label: 'Guest tolerance', value: profile.guests ?? 'Unknown'),
    if (profile.gender != null)
      _InfoRow(
        label: 'Gender', 
        value: profile.gender == 'male' ? 'Male' : profile.gender == 'female' ? 'Female' : 'Other'
      ),
    if (profile.roommatePreference != null)
      _InfoRow(
        label: 'Roommate preference',
        value: profile.roommatePreference == 'male_only' 
          ? 'Men only' 
          : profile.roommatePreference == 'female_only' 
            ? 'Women only' 
            : 'No preference'
      ),
  ];
}

List<Widget> _budgetSection(UserProfile profile) {
    return [
      _InfoRow(
        label: 'Budget range',
        value: profile.budgetMin == null || profile.budgetMax == null
            ? 'N/A'
            : ' ${profile.budgetMin} –  ${profile.budgetMax}',
      ),
      _InfoRow(
        label: 'Move-in date',
        value: profile.moveInDate == null ? 'Flexible' : DateFormat.yMMMMd().format(profile.moveInDate!),
      ),
    ];
  }

  List<Widget> _socialSection(UserProfile profile) {
    final links = profile.socialLinks ?? {};
    if (links.isEmpty) return [const Text('No social links provided.')];
    return links.entries
        .map((entry) => _InfoRow(label: entry.key, value: entry.value.toString()))
        .toList();
  }

  List<Widget> _metaSection(UserProfile profile) {
    return [
      _InfoRow(
        label: 'Created',
        value: profile.createdAt == null ? 'Unknown' : DateFormat.yMMMd().format(profile.createdAt!),
      ),
      _InfoRow(
        label: 'Updated',
        value: profile.updatedAt == null ? 'Unknown' : DateFormat.yMMMd().add_jm().format(profile.updatedAt!),
      ),
    ];
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: profile.hasPhoto ? NetworkImage(profile.photoUrl!) : null,
          child: profile.hasPhoto
              ? null
              : Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.fullName}${profile.age == null ? '' : ', ${profile.age}'}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (profile.pronouns != null) ...[
                const SizedBox(height: 2),
                Text(
                  profile.pronouns!,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Text(profile.email ?? ''),
              const SizedBox(height: 8),
              Text('${profile.major ?? 'Undeclared'} · ${profile.year ?? 'Year TBD'}'),
              if (profile.city != null) ...[              
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(profile.city!, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(profile.bio ?? 'No bio yet.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _SliderDisplay extends StatelessWidget {
  const _SliderDisplay({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value ?? 'Unknown'}'),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value == null ? 0 : (value!.clamp(0, 5) / 5),
          minHeight: 6,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
