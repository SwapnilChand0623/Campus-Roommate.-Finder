import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../constants/form_options.dart';
import '../models/user_profile.dart';
import '../providers/supabase_providers.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_buttons.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.existingProfile});

  final UserProfile existingProfile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late final TextEditingController _fullNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _majorController;
  late final TextEditingController _bioController;
  late final TextEditingController _roommateExpectationsController;
  late final TextEditingController _budgetMinController;
  late final TextEditingController _budgetMaxController;
  late final TextEditingController _instagramController;
  late final TextEditingController _linkedinController;
  late final TextEditingController _otherLinkController;

  String? _academicYear;
  String? _studyHabits;
  String? _sleepSchedule;
  String? _personalityType;
  double _cleanliness = 3;
  double _noiseTolerance = 3;
  String? _smoking;
  String? _pets;
  String? _guests;
  DateTime? _moveInDate;
  bool _moveInFlexible = false;

  bool _isSaving = false;
  XFile? _selectedPhoto;
  List<String> _roomPhotoUrls = [];

  @override
  void initState() {
    super.initState();
    final profile = widget.existingProfile;
    _fullNameController = TextEditingController(text: profile.fullName);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _majorController = TextEditingController(text: profile.major ?? '');
    _bioController = TextEditingController(text: profile.bio ?? '');
    _roommateExpectationsController = TextEditingController(text: profile.roommateExpectations ?? '');
    _budgetMinController = TextEditingController(text: profile.budgetMin?.toString() ?? '');
    _budgetMaxController = TextEditingController(text: profile.budgetMax?.toString() ?? '');
    _instagramController = TextEditingController(text: profile.socialLinks?['instagram']?.toString() ?? '');
    _linkedinController = TextEditingController(text: profile.socialLinks?['linkedin']?.toString() ?? '');
    _otherLinkController = TextEditingController(text: profile.socialLinks?['other']?.toString() ?? '');

    _academicYear = profile.year ?? FormOptions.academicYears.first;
    _studyHabits = profile.studyHabits ?? FormOptions.studyHabits.first;
    _sleepSchedule = profile.sleepSchedule ?? FormOptions.sleepSchedules.first;
    _personalityType = profile.personalityType ?? FormOptions.personalityTypes.first;
    _cleanliness = (profile.cleanliness?.toDouble() ?? 3).clamp(1, 5);
    _noiseTolerance = (profile.noiseTolerance?.toDouble() ?? 3).clamp(1, 5);
    _smoking = profile.smoking ?? FormOptions.smokingPreferences.first;
    _pets = profile.pets ?? FormOptions.petsPreferences.first;
    _guests = profile.guests ?? FormOptions.guestTolerance.first;
    _moveInDate = profile.moveInDate;
    _moveInFlexible = profile.moveInDate == null;
    _roomPhotoUrls = List<String>.from(profile.roomPhotos);
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) {
      setState(() => _selectedPhoto = file);
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

    final storage = ref.read(storageServiceProvider);
    try {
      final url = await storage.uploadRoomPhoto(File(picked.path));
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

  Future<void> _selectMoveInDate() async {
    if (_moveInFlexible) return;
    final selected = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (selected != null) {
      setState(() => _moveInDate = selected);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final age = int.tryParse(_ageController.text.trim());
    final budgetMin = int.tryParse(_budgetMinController.text.trim());
    final budgetMax = int.tryParse(_budgetMaxController.text.trim());

    setState(() => _isSaving = true);
    final storage = ref.read(storageServiceProvider);
    final database = ref.read(databaseServiceProvider);

    try {
      String? photoUrl = widget.existingProfile.photoUrl;
      if (_selectedPhoto != null) {
        photoUrl = await storage.uploadProfilePhoto(File(_selectedPhoto!.path));
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

      final updatedProfile = widget.existingProfile.copyWith(
        fullName: _fullNameController.text.trim(),
        age: age,
        major: _majorController.text.trim(),
        year: _academicYear,
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        sleepSchedule: _sleepSchedule,
        cleanliness: _cleanliness.round(),
        noiseTolerance: _noiseTolerance.round(),
        smoking: _smoking,
        pets: _pets,
        guests: _guests,
        personalityType: _personalityType,
        studyHabits: _studyHabits,
        roommateExpectations: _roommateExpectationsController.text.trim().isEmpty
            ? null
            : _roommateExpectationsController.text.trim(),
        moveInDate: _moveInFlexible ? null : _moveInDate,
        socialLinks: socialLinks.isEmpty ? null : socialLinks,
        profileCompleted: true,
        roomPhotos: _roomPhotoUrls,
      );

      await database.upsertProfile(updatedProfile);
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $error')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _selectedPhoto != null
                          ? FileImage(File(_selectedPhoto!.path))
                          : (widget.existingProfile.hasPhoto ? NetworkImage(widget.existingProfile.photoUrl!) : null)
                              as ImageProvider?,
                      child: widget.existingProfile.hasPhoto || _selectedPhoto != null
                          ? null
                          : Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.photo), label: const Text('Change photo')),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Required';
                    final age = int.tryParse(value.trim());
                    if (age == null) return 'Enter a number';
                    if (age < 16 || age > 100) return 'Age must be 16-100';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _academicYear,
                  items: FormOptions.academicYears
                      .map((year) => DropdownMenuItem(value: year, child: Text(year)))
                      .toList(),
                  onChanged: (value) => setState(() => _academicYear = value),
                  decoration: const InputDecoration(labelText: 'Academic year'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _majorController,
                  decoration: const InputDecoration(labelText: 'Major'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio / Interests'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Text('Me and My Room', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  'Add up to 5 photos of yourself, your hobbies, and your room.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
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
                              width: 100,
                              height: 100,
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
                  segments: FormOptions.studyHabits.map((habit) => ButtonSegment(value: habit, label: Text(habit))).toList(),
                  selected: {_studyHabits ?? FormOptions.studyHabits.first},
                  onSelectionChanged: (value) => setState(() => _studyHabits = value.first),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _sleepSchedule,
                  decoration: const InputDecoration(labelText: 'Sleep schedule'),
                  items: FormOptions.sleepSchedules
                      .map((schedule) => DropdownMenuItem(value: schedule, child: Text(schedule)))
                      .toList(),
                  onChanged: (value) => setState(() => _sleepSchedule = value),
                ),
                const SizedBox(height: 24),
                _SliderInput(label: 'Cleanliness', value: _cleanliness, onChanged: (v) => setState(() => _cleanliness = v)),
                const SizedBox(height: 16),
                _SliderInput(label: 'Noise tolerance', value: _noiseTolerance, onChanged: (v) => setState(() => _noiseTolerance = v)),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _smoking,
                  decoration: const InputDecoration(labelText: 'Smoking preference'),
                  items: FormOptions.smokingPreferences
                      .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                      .toList(),
                  onChanged: (value) => setState(() => _smoking = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _pets,
                  decoration: const InputDecoration(labelText: 'Pets preference'),
                  items: FormOptions.petsPreferences
                      .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                      .toList(),
                  onChanged: (value) => setState(() => _pets = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _guests,
                  decoration: const InputDecoration(labelText: 'Guest tolerance'),
                  items: FormOptions.guestTolerance
                      .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                      .toList(),
                  onChanged: (value) => setState(() => _guests = value),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _roommateExpectationsController,
                  decoration: const InputDecoration(labelText: 'Roommate expectations (optional)'),
                  maxLines: 2,
                ),
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
                          if (min == null) return 'Enter number';
                          if (min < 100) return 'Min 100';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _budgetMaxController,
                        decoration: const InputDecoration(labelText: 'Budget max', prefixText: '\$'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          final max = int.tryParse(value.trim());
                          if (max == null) return 'Enter number';
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
                        onPressed: _selectMoveInDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_moveInDate == null ? 'Select move-in date' : DateFormat.yMMMMd().format(_moveInDate!)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        value: _moveInFlexible,
                        onChanged: (value) {
                          setState(() {
                            _moveInFlexible = value ?? false;
                            if (_moveInFlexible) _moveInDate = null;
                          });
                        },
                        title: const Text('Flexible'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
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
                PrimaryButton(
                  label: 'Save changes',
                  icon: Icons.save,
                  onPressed: _isSaving ? null : _save,
                  isLoading: _isSaving,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderInput extends StatelessWidget {
  const _SliderInput({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            Text(value.round().toString()),
          ],
        ),
        Slider(min: 1, max: 5, divisions: 4, value: value, onChanged: onChanged),
      ],
    );
  }
}
