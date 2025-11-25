import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/form_options.dart';
import '../../models/user_profile.dart';
import '../../models/university.dart';
import '../../providers/supabase_providers.dart';
import '../../providers/university_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_buttons.dart';
import '../home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routeName = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _basicFormKey = GlobalKey<FormState>();
  final _lifestyleFormKey = GlobalKey<FormState>();
  final _budgetFormKey = GlobalKey<FormState>();
  final _socialFormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _majorController = TextEditingController();
  final _bioController = TextEditingController();
  final _roommateExpectationsController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _otherLinkController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();

  int _currentStep = 0;
  bool _isSaving = false;
  bool _moveInFlexible = false;

  String? _email;
  String? _selectedYear;
  String? _studyHabits = FormOptions.studyHabits.first;
  String? _sleepSchedule = FormOptions.sleepSchedules.first;
  String? _personalityType = FormOptions.personalityTypes.first;
  String? _smokingPreference = FormOptions.smokingPreferences.first;
  String? _petsPreference = FormOptions.petsPreferences.first;
  String? _guestTolerance = FormOptions.guestTolerance.first;
  String? _gender; // NEW: User's gender (male, female, other)
  String? _roommatePreference; // NEW: Who they want to live with (male_only, female_only, any)
  String? _pronouns = FormOptions.pronounOptions.first;
  String _housingStatus = 'on_campus';
  String _housingPreference = 'either';
  String? _city;
  String? _zipCode;
  double? _latitude;
  double? _longitude;
  int _maxDistanceMiles = 20;

  University? _selectedUniversity;

  double _cleanlinessLevel = 3;
  double _noiseTolerance = 3;
  DateTime? _moveInDate;

  XFile? _selectedPhotoFile;
  String? _photoUrl;

  // Optional Me and My Room photos (max 5), shared with Edit Profile.
  List<String> _roomPhotoUrls = [];

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(_hydrateInitialValues);
  }

  Future<void> _hydrateInitialValues() async {
    final authUser = Supabase.instance.client.auth.currentUser;

    // Read any cached profile, but only trust it if it belongs to the
    // CURRENT authenticated user. This avoids showing a previous user's
    // data when a new account has just logged in.
    final profileState = ref.read(currentUserProfileProvider);
    final profile = profileState.maybeWhen(
      data: (p) {
        if (p == null || authUser == null) return null;
        return p.id == authUser.id ? p : null;
      },
      orElse: () => null,
    );

    setState(() {
      _email = profile?.email ?? authUser?.email;
      _fullNameController.text = profile?.fullName ?? authUser?.userMetadata?['full_name'] ?? '';
      _ageController.text = profile?.age?.toString() ?? '';
      _majorController.text = profile?.major ?? '';
      _bioController.text = profile?.bio ?? '';
      _roommateExpectationsController.text = profile?.roommateExpectations ?? '';
      _budgetMinController.text = profile?.budgetMin?.toString() ?? '';
      _budgetMaxController.text = profile?.budgetMax?.toString() ?? '';
      _instagramController.text = profile?.socialLinks?['instagram']?.toString() ?? '';
      _linkedinController.text = profile?.socialLinks?['linkedin']?.toString() ?? '';
      _otherLinkController.text = profile?.socialLinks?['other']?.toString() ?? '';
      _selectedYear = profile?.year ?? FormOptions.academicYears.first;
      _studyHabits = profile?.studyHabits ?? FormOptions.studyHabits.first;
      _sleepSchedule = profile?.sleepSchedule ?? FormOptions.sleepSchedules.first;
      _personalityType = profile?.personalityType ?? FormOptions.personalityTypes.first;
      _smokingPreference = profile?.smoking ?? FormOptions.smokingPreferences.first;
      _petsPreference = profile?.pets ?? FormOptions.petsPreferences.first;
      _guestTolerance = profile?.guests ?? FormOptions.guestTolerance.first;
      _gender = profile?.gender;
      _roommatePreference = profile?.roommatePreference;
      _pronouns = profile?.pronouns ?? FormOptions.pronounOptions.first;
      _housingStatus = profile?.housingStatus ?? 'on_campus';
      _housingPreference = profile?.housingPreference ?? 'either';
      _city = profile?.city;
      _zipCode = profile?.zipCode;
      _latitude = profile?.latitude;
      _longitude = profile?.longitude;
      _maxDistanceMiles = profile?.maxDistanceMiles ?? 20;
      _cityController.text = profile?.city ?? '';
      _zipCodeController.text = profile?.zipCode ?? '';
      _cleanlinessLevel = (profile?.cleanliness?.toDouble() ?? 3).clamp(1, 5);
      _noiseTolerance = (profile?.noiseTolerance?.toDouble() ?? 3).clamp(1, 5);
      _moveInDate = profile?.moveInDate;
      _moveInFlexible = _moveInDate == null;
      _photoUrl = profile?.photoUrl;
      _roomPhotoUrls = List<String>.from(profile?.roomPhotos ?? const <String>[]);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _ageController.dispose();
    _majorController.dispose();
    _bioController.dispose();
    _roommateExpectationsController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _otherLinkController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _selectedPhotoFile = file);
    }
  }

  Future<void> _addRoomPhoto() async {
    if (_roomPhotoUrls.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 photos in Me and My Room.')),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    final storageService = ref.read(storageServiceProvider);
    try {
      final url = await storageService.uploadRoomPhoto(File(picked.path));
      if (!mounted) return;
      setState(() {
        _roomPhotoUrls.add(url);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $error')),
      );
    }
  }

  void _removeRoomPhoto(String url) {
    setState(() {
      _roomPhotoUrls.remove(url);
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        final basicValid = _basicFormKey.currentState?.validate() ?? false;
        if (!basicValid) return false;
        if (_selectedUniversity == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your university to continue.')),
          );
          return false;
        }
        return true;
      case 1:
        final lifestyleValid = _lifestyleFormKey.currentState?.validate() ?? false;
        if (_personalityType == null || _studyHabits == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select personality and study habits to continue.')),
          );
          return false;
        }
        return lifestyleValid;
      case 2:
        // Me and My Room step is optional; no validation required.
        return true;
      case 3:
        // Gender step - REQUIRED
        if (_gender == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your gender to continue.')),
          );
          return false;
        }
        return true;
      case 4:
        // Roommate Preference step - REQUIRED
        if (_roommatePreference == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your roommate preference to continue.')),
          );
          return false;
        }
        return true;
      case 5:
        final budgetValid = _budgetFormKey.currentState?.validate() ?? false;
        if (!_moveInFlexible && _moveInDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please choose a move-in date or mark yourself as flexible.')),
          );
          return false;
        }
        return budgetValid;
      case 6:
        return _socialFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (_currentStep == _totalSteps - 1) {
      _submit();
      return;
    }
    setState(() => _currentStep += 1);
    _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
    _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    if (!_validateCurrentStep()) return;
    if ((_photoUrl == null || _photoUrl!.isEmpty) && _selectedPhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile photo before finishing.')),
      );
      return;
    }

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please log in again.')),
      );
      return;
    }

    final email = _email ?? authUser.email;
    final emailDomain = email?.split('@').last.toLowerCase();

    if (_selectedUniversity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your university before finishing.')),
      );
      return;
    }

    final allowedDomains = _selectedUniversity!.domains.map((d) => d.toLowerCase()).toList();
    if (emailDomain == null || !allowedDomains.contains(emailDomain)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your email domain ($emailDomain) does not match ${_selectedUniversity!.name}. '
            'Use your university email or pick the correct university.',
          ),
        ),
      );
      return;
    }

    final age = int.tryParse(_ageController.text.trim());
    final budgetMin = int.tryParse(_budgetMinController.text.trim());
    final budgetMax = int.tryParse(_budgetMaxController.text.trim());

    final storageService = ref.read(storageServiceProvider);
    final databaseService = ref.read(databaseServiceProvider);

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      String? photoUrl = _photoUrl;
      if (_selectedPhotoFile != null) {
        photoUrl = await storageService.uploadProfilePhoto(File(_selectedPhotoFile!.path));
      }

      final socialLinks = <String, dynamic>{};
      if (_instagramController.text.trim().isNotEmpty) {
        socialLinks['instagram'] = _instagramController.text.trim();
      }
      if (_linkedinController.text.trim().isNotEmpty) {
        socialLinks['linkedin'] = _linkedinController.text.trim();
      }
      if (_otherLinkController.text.trim().isNotEmpty) {
        socialLinks['other'] = _otherLinkController.text.trim();
      }

      final profile = UserProfile(
        id: authUser.id,
        email: _email ?? authUser.email,
        fullName: _fullNameController.text.trim(),
        age: age,
        major: _majorController.text.trim(),
        year: _selectedYear,
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        sleepSchedule: _sleepSchedule,
        cleanliness: _cleanlinessLevel.round(),
        noiseTolerance: _noiseTolerance.round(),
        smoking: _smokingPreference,
        pets: _petsPreference,
        guests: _guestTolerance,
        personalityType: _personalityType,
        studyHabits: _studyHabits,
        roommateExpectations:
            _roommateExpectationsController.text.trim().isEmpty ? null : _roommateExpectationsController.text.trim(),
        gender: _gender,
        roommatePreference: _roommatePreference,
        pronouns: _pronouns,
        moveInDate: _moveInFlexible ? null : _moveInDate,
        socialLinks: socialLinks.isEmpty ? null : socialLinks,
        profileCompleted: true,
        universityName: _selectedUniversity!.name,
        housingStatus: _housingStatus,
        housingPreference: _housingPreference,
        city: _city,
        zipCode: _zipCode,
        latitude: _latitude,
        longitude: _longitude,
        maxDistanceMiles: _maxDistanceMiles,
        roomPhotos: _roomPhotoUrls,
      );

      await databaseService.upsertProfile(profile);
      await ref.read(currentUserProfileProvider.future);
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved! Welcome to Campus Roommate Finder.')),
        );
        
        // Navigate to home screen after successful profile completion
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save profile: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  int get _totalSteps => 7; // Updated from 5 to include gender and roommate preference

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildBasicInfoStep(),
      _buildLifestyleStep(),
      _buildMeAndMyRoomStep(),
      _buildGenderStep(), // NEW: Gender selection
      _buildRoommatePreferenceStep(), // NEW: Roommate preference selection
      _buildBudgetStep(),
      _buildSocialStep(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Complete your profile'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: steps,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousStep,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Back'),
                      ),
                    )
                  else
                    Expanded(
                      child: TextButton(
                        onPressed: null,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: _currentStep == _totalSteps - 1 ? 'Finish' : 'Continue',
                      icon: _currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward,
                      onPressed: _isSaving ? null : _nextStep,
                      isLoading: _isSaving,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final labels = ['Basics', 'Lifestyle', 'Me & My Room', 'Gender', 'Roommate', 'Budget', 'Social'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step ${_currentStep + 1} of $_totalSteps', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int i = 0; i < _totalSteps; i++)
                Expanded(
                  child: AnimatedContainer(
                    duration: 250.ms,
                    height: 6,
                    margin: EdgeInsets.only(right: i == _totalSteps - 1 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: i <= _currentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(labels[_currentStep], style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    final theme = Theme.of(context);
    final universitiesAsync = ref.watch(universitiesProvider);
    return Form(
      key: _basicFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Let’s start with the basics', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Add your personal details so we can help other students learn about you.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Center(child: _buildPhotoPicker()),
            const SizedBox(height: 24),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Full name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _email,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'University email'),
            ),
            const SizedBox(height: 16),
            universitiesAsync.when(
              data: (universities) {
                // Pre-filter to likely relevant universities (e.g., US / .edu style domains).
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
                    return TextFormField(
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
              error: (error, _) => const Text('Unable to load universities'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Age is required';
                final age = int.tryParse(value.trim());
                if (age == null) return 'Enter a valid number';
                if (age < 16 || age > 100) return 'Age must be between 16 and 100';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedYear,
              items: FormOptions.academicYears
                  .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                  .toList(),
              onChanged: (value) => setState(() => _selectedYear = value),
              decoration: const InputDecoration(labelText: 'Academic year'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _majorController,
              decoration: const InputDecoration(labelText: 'Major'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Major is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio / Interests'),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final imageWidget = _selectedPhotoFile != null
        ? CircleAvatar(radius: 48, backgroundImage: FileImage(File(_selectedPhotoFile!.path)))
        : (_photoUrl != null && _photoUrl!.isNotEmpty)
            ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(_photoUrl!))
            : CircleAvatar(
                radius: 48,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(.1),
                child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary, size: 32),
              );

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            imageWidget,
            Positioned(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.edit, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.photo_library), label: const Text('Upload photo')),
      ],
    );
  }

  Widget _buildMeAndMyRoomStep() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Me & My Room (optional)',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Share a few photos of yourself, your hobbies, or your room so matches can see how you live.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _roomPhotoUrls.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == _roomPhotoUrls.length) {
                  final canAddMore = _roomPhotoUrls.length < 5;
                  return OutlinedButton.icon(
                    onPressed: canAddMore ? _addRoomPhoto : null,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(canAddMore ? 'Add photo' : 'Max 5 photos'),
                  );
                }

                final url = _roomPhotoUrls[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          splashRadius: 12,
                          icon: const Icon(Icons.close, size: 14, color: Colors.white),
                          onPressed: () => _removeRoomPhoto(url),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can add or change these later from Edit Profile.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLifestyleStep() {
    final theme = Theme.of(context);
    return Form(
      key: _lifestyleFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lifestyle & preferences', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Help us understand your daily rhythms and roommate expectations.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text('Personality', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final option in FormOptions.personalityTypes)
                  ChoiceChip(
                    label: Text(option),
                    selected: _personalityType == option,
                    onSelected: (_) => setState(() => _personalityType = option),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Study habits', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              multiSelectionEnabled: false,
              segments: FormOptions.studyHabits
                  .map((habit) => ButtonSegment<String>(value: habit, label: Text(habit)))
                  .toList(),
              selected: {_studyHabits ?? FormOptions.studyHabits.first},
              onSelectionChanged: (newSelection) => setState(() => _studyHabits = newSelection.first),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _sleepSchedule,
              items: FormOptions.sleepSchedules
                  .map((schedule) => DropdownMenuItem(value: schedule, child: Text(schedule)))
                  .toList(),
              onChanged: (value) => setState(() => _sleepSchedule = value),
              decoration: const InputDecoration(labelText: 'Sleep schedule'),
            ),
            const SizedBox(height: 24),
            _buildSliderRow(
              label: 'Cleanliness level',
              value: _cleanlinessLevel,
              onChanged: (value) => setState(() => _cleanlinessLevel = value),
            ),
            const SizedBox(height: 16),
            _buildSliderRow(
              label: 'Noise tolerance',
              value: _noiseTolerance,
              onChanged: (value) => setState(() => _noiseTolerance = value),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _smokingPreference,
              decoration: const InputDecoration(labelText: 'Smoking preference'),
              items: FormOptions.smokingPreferences
                  .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) => setState(() => _smokingPreference = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _petsPreference,
              decoration: const InputDecoration(labelText: 'Pets preference'),
              items:
                  FormOptions.petsPreferences.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
              onChanged: (value) => setState(() => _petsPreference = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _guestTolerance,
              decoration: const InputDecoration(labelText: 'Guest tolerance'),
              items: FormOptions.guestTolerance
                  .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) => setState(() => _guestTolerance = value),
            ),
            const SizedBox(height: 24),
            Text('Housing status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Where are you currently staying?', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'on_campus', label: Text('On Campus')),
                ButtonSegment(value: 'off_campus', label: Text('Off Campus')),
              ],
              selected: {_housingStatus},
              onSelectionChanged: (newSelection) => setState(() => _housingStatus = newSelection.first),
            ),
            const SizedBox(height: 24),
            Text('Housing preference', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('What kind of roommates are you looking for?', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'on_campus', label: Text('On Campus')),
                ButtonSegment(value: 'off_campus', label: Text('Off Campus')),
                ButtonSegment(value: 'either', label: Text('Either')),
              ],
              selected: {_housingPreference},
              onSelectionChanged: (newSelection) => setState(() => _housingPreference = newSelection.first),
            ),
            const SizedBox(height: 24),
            Text('Location', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Help us find nearby matches', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City/Area',
                hintText: 'e.g., Arlington',
              ),
              onChanged: (value) => setState(() => _city = value.trim().isEmpty ? null : value.trim()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipCodeController,
              decoration: const InputDecoration(
                labelText: 'Zip Code',
                hintText: '5-digit zip code',
              ),
              keyboardType: TextInputType.number,
              maxLength: 5,
              onChanged: (value) async {
                final zip = value.trim();
                if (zip.length == 5 && RegExp(r'^\d{5}$').hasMatch(zip)) {
                  // Geocode the zip code
                  final geocoding = ref.read(geocodingServiceProvider);
                  final location = await geocoding.geocodeZipCode(zip);
                  if (location != null) {
                    setState(() {
                      _zipCode = zip;
                      _latitude = location.latitude;
                      _longitude = location.longitude;
                      if (_cityController.text.isEmpty && location.city != null) {
                        _cityController.text = location.city!;
                        _city = location.city;
                      }
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Location found: ${location.city ?? 'Unknown'}')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid zip code')),
                      );
                    }
                  }
                } else {
                  setState(() {
                    _zipCode = null;
                    _latitude = null;
                    _longitude = null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            Text('Max distance', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('How far are you willing to commute/travel? ($_maxDistanceMiles miles)', style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Slider(
              value: _maxDistanceMiles.toDouble(),
              min: 5,
              max: 50,
              divisions: 9,
              label: '$_maxDistanceMiles miles',
              onChanged: (value) => setState(() => _maxDistanceMiles = value.round()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roommateExpectationsController,
              decoration: const InputDecoration(labelText: 'Roommate expectations (optional)'),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({required String label, required double value, required ValueChanged<double> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            Text(value.round().toString(), style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        Slider(
          min: 1,
          max: 5,
          divisions: 4,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBudgetStep() {
    final theme = Theme.of(context);
    return Form(
      key: _budgetFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget & logistics', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Share your housing budget and move-in timing to find the right match.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budgetMinController,
                    decoration: const InputDecoration(labelText: 'Budget min', prefixText: '\$'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Required';
                      final min = int.tryParse(value.trim());
                      if (min == null) return 'Enter a number';
                      if (min < 100) return 'Must be at least 100';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _budgetMaxController,
                    decoration: const InputDecoration(labelText: 'Budget max', prefixText: '\$'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Required';
                      final max = int.tryParse(value.trim());
                      if (max == null) return 'Enter a number';
                      final min = int.tryParse(_budgetMinController.text.trim());
                      if (min != null && max < min) return 'Must be >= min';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _moveInFlexible
                        ? null
                        : () async {
                            final now = DateTime.now();
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: _moveInDate ?? now,
                              firstDate: DateTime(now.year - 1),
                              lastDate: DateTime(now.year + 3),
                            );
                            if (selected != null) {
                              setState(() => _moveInDate = selected);
                            }
                          },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_moveInDate == null ? 'Select move-in date' : DateFormat.yMMMMd().format(_moveInDate!)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    value: _moveInFlexible,
                    onChanged: (value) {
                      setState(() {
                        _moveInFlexible = value ?? false;
                        if (_moveInFlexible) {
                          _moveInDate = null;
                        }
                      });
                    },
                    title: const Text('I’m flexible'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _pronouns,
              decoration: const InputDecoration(
                labelText: 'Pronouns',
                helperText: 'Required - Your gender identity',
              ),
              items: FormOptions.pronounOptions
                  .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                  .toList(),
              onChanged: (value) => setState(() => _pronouns = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your pronouns';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderStep() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is your gender?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'This helps us match you with compatible roommates',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ...FormOptions.genders.map((gender) {
            final value = FormOptions.genderValues[gender]!;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _gender = value),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _gender == value ? theme.colorScheme.primary : Colors.grey.shade300,
                      width: _gender == value ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _gender == value ? theme.colorScheme.primary.withOpacity(0.1) : null,
                  ),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: value,
                        groupValue: _gender,
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        gender,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: _gender == value ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRoommatePreferenceStep() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Who would you like to live with?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can change this later in filters. Your choice affects who can see your profile.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...FormOptions.roommatePreferences.map((pref) {
            final value = FormOptions.roommatePreferenceValues[pref]!;
            String description = '';
            if (pref == 'Men only') {
              description = 'Only see men • Only visible to users looking for men';
            } else if (pref == 'Women only') {
              description = 'Only see women • Only visible to users looking for women';
            } else {
              description = 'See everyone • Only visible to users with "No preference"';
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _roommatePreference = value),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _roommatePreference == value ? theme.colorScheme.primary : Colors.grey.shade300,
                      width: _roommatePreference == value ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _roommatePreference == value ? theme.colorScheme.primary.withOpacity(0.1) : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<String>(
                        value: value,
                        groupValue: _roommatePreference,
                        onChanged: (val) => setState(() => _roommatePreference = val),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pref,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: _roommatePreference == value ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSocialStep() {
    final theme = Theme.of(context);
    return Form(
      key: _socialFormKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Social links & wrap-up', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Share optional social profiles so matches can learn more about you.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _instagramController,
              decoration: const InputDecoration(labelText: 'Instagram (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkedinController,
              decoration: const InputDecoration(labelText: 'LinkedIn (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _otherLinkController,
              decoration: const InputDecoration(labelText: 'Other link (optional)'),
            ),
            const SizedBox(height: 32),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready to find your match?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Tap Finish to save your profile and view your personalized roommate matches.', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
