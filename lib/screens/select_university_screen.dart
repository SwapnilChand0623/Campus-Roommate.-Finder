import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/university.dart';
import '../providers/university_provider.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/cozy_background.dart';

class SelectUniversityScreen extends ConsumerStatefulWidget {
  const SelectUniversityScreen({super.key});

  static const routeName = '/select-university';

  @override
  ConsumerState<SelectUniversityScreen> createState() => _SelectUniversityScreenState();
}

class _SelectUniversityScreenState extends ConsumerState<SelectUniversityScreen> {
  University? _selectedUniversity;

  void _goToLogin() {
    if (_selectedUniversity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your university to continue.')),
      );
      return;
    }

    // Persist selection so AuthGate can show the appropriate login screen.
    ref.read(selectedUniversityProvider.notifier).state = _selectedUniversity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/friends_background.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to CozyBackground if image not found
              return const CozyBackground(child: SizedBox.expand());
            },
          ),
          // White overlay for readability (reduced for clearer background)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.25),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Vignette effect (on top of everything) - subtle
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.45),
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          // Content
          SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                        const SizedBox(height: 20),
                // Bunky-style Word Art Title with fun font
                Stack(
                  children: [
                    // Black stroke outline (multiple layers for thickness)
                    Text(
                      'Campus\nRoommate\nFinder',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        height: 1.05,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 7
                          ..color = Colors.black,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(3, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // Purple fill
                    Text(
                      'Campus\nRoommate\nFinder',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        height: 1.05,
                        color: const Color(0xFFB8B0E8), // Light purple fill
                      ),
                    ),
                  ],
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: false))
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut)
                    .then(delay: 2000.ms)
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        // Subtitle with fancy font - bouncing animation
                        Text(
                          'Find someone worth living with',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.6),
                                offset: const Offset(2, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 400.ms)
                            .slideY(
                              begin: 3.0,
                              end: 0,
                              delay: 600.ms,
                              duration: 1000.ms,
                              curve: Curves.elasticOut,
                            ),
                        const SizedBox(height: 250),
                        // Info Card - Transparent and Fancy
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Text(
                                  'Select your university',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        offset: const Offset(1, 1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Connect with students from your campus',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.4,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        offset: const Offset(1, 1),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        )
                            .animate()
                            .fadeIn(delay: 800.ms, duration: 600.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                        const SizedBox(height: 32),
                        universitiesAsync.when(
                          data: (universities) {
                            // Reuse same pre-filtering strategy as onboarding.
                            final filtered = universities.where((u) {
                              final code = (u.alphaTwoCode ?? '').toUpperCase();
                              if (code == 'US') return true;
                              final lowerDomains = u.domains.map((d) => d.toLowerCase());
                              return lowerDomains.any((d) => d.endsWith('.edu'));
                            }).toList();

                            return Autocomplete<University>(
                              displayStringForOption: (u) => u.name,
                              optionsBuilder: (textEditingValue) {
                                final query = textEditingValue.text.toLowerCase().trim();
                                if (query.isEmpty) {
                                  return const Iterable<University>.empty();
                                }
                                return filtered.where(
                                  (u) => u.name.toLowerCase().contains(query),
                                );
                              },
                              onSelected: (u) {
                                setState(() => _selectedUniversity = u);
                              },
                              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                                if (_selectedUniversity != null && textEditingController.text.isEmpty) {
                                  textEditingController.text = _selectedUniversity!.name;
                                }
                                return TextField(
                                  controller: textEditingController,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'University / Campus',
                                    hintText: 'Start typing your university name',
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                          error: (error, _) => Center(
                            child: Text('Unable to load universities: $error'),
                          ),
                        ),
                        const SizedBox(height: 40),
                        PrimaryButton(
                          label: 'Continue to Login',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _goToLogin,
                        )
                            .animate()
                            .fadeIn(delay: 1000.ms, duration: 600.ms)
                            .slideY(begin: 0.3, end: 0),
                        const SizedBox(height: 16),
                        // Terms and Privacy Policy text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'By selecting "Continue to Login" button I am agreeing to the ',
                                ),
                                TextSpan(
                                  text: 'Terms of Use',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' & ',
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(
                                  text: '.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }
}
