import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_keys.dart';
import 'providers/university_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/select_university_screen.dart';
import 'screens/signup_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseKeys.supabaseUrl,
    anonKey: SupabaseKeys.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );

  // Initialize notification service
  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Campus Roommate Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
      },
      home: AuthGate(ref: ref),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.ref});

  final WidgetRef ref;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          final selectedUniversity = widget.ref.watch(selectedUniversityProvider);
          if (selectedUniversity == null) {
            return const SelectUniversityScreen();
          } else {
            return LoginScreen(selectedUniversity: selectedUniversity);
          }
        }

        final userProfileAsync = widget.ref.watch(currentUserProfileProvider);
        final universitiesAsync = widget.ref.watch(universitiesProvider);

        return userProfileAsync.when(
          data: (profile) {
            return universitiesAsync.when(
              data: (universities) {
                // If profile missing or university not yet set, send to onboarding.
                if (profile == null || !profile.profileCompleted || profile.universityName == null) {
                  return const OnboardingScreen();
                }

                final authUser = Supabase.instance.client.auth.currentUser;
                final email = authUser?.email ?? profile.email;
                final emailDomain = email?.split('@').last.toLowerCase();

                final university = universities.firstWhere(
                  (u) => u.name == profile.universityName,
                  orElse: () => universities.firstWhere(
                    (u) => false,
                    orElse: () => universities.isNotEmpty
                        ? universities.first
                        : throw StateError('No universities loaded'),
                  ),
                );

                final allowedDomains = university.domains.map((d) => d.toLowerCase()).toList();

                final matchesDomain =
                    emailDomain != null && allowedDomains.isNotEmpty && allowedDomains.contains(emailDomain);

                if (!matchesDomain) {
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Email domain does not match university',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your email domain (${emailDomain ?? 'unknown'}) does not match your university '
                              '(${profile.universityName}). Please sign out and sign back in with your official '
                              'university email.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final shouldLogout = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Log out?'),
                                      content: const Text('Are you sure you want to log out?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Sure'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldLogout == true) {
                                  await Supabase.instance.client.auth.signOut();
                                }
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return const HomeScreen();
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unable to load universities'),
                      const SizedBox(height: 8),
                      Text('$error'),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load profile'),
                  const SizedBox(height: 8),
                  Text('$error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      widget.ref.invalidate(currentUserProfileProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
