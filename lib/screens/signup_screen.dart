import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/university.dart';
import '../providers/supabase_providers.dart';
import '../widgets/custom_buttons.dart';
import 'verify_email_otp_screen.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.selectedUniversity});

  static const routeName = '/signup';

  final University? selectedUniversity;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final authService = ref.read(authServiceProvider);

    final selectedUniversity = widget.selectedUniversity;
    if (selectedUniversity != null) {
      final email = _emailController.text.trim();
      final emailDomain = email.split('@').length > 1 ? email.split('@').last.toLowerCase() : null;
      final allowedDomains = selectedUniversity.domains.map((d) => d.toLowerCase()).toList();
      if (emailDomain == null || !allowedDomains.contains(emailDomain)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your email domain ($emailDomain) does not match ${selectedUniversity.name}. '
              'Use your official university email for this campus.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      await authService.signUp(
        email: email,
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
      );

      // Send OTP for email verification
      await authService.sendLoginOtp(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Check your email for verification code.')),
        );
        // Navigate to OTP verification screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerifyEmailOtpScreen(
              email: email,
              selectedUniversity: widget.selectedUniversity,
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Let’s get you started!', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.selectedUniversity != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Campus: ${widget.selectedUniversity!.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => (value == null || value.isEmpty) ? 'Full name required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'University Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Email required';
                    if (!value.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Create Account', onPressed: _signup, isLoading: _isLoading, icon: Icons.person_add_alt_1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
