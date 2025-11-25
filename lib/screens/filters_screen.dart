import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/form_options.dart';
import '../models/match_filters.dart';
import '../models/user_profile.dart';
import '../providers/match_provider.dart';
import '../providers/supabase_providers.dart';
import '../providers/user_provider.dart';
import '../widgets/embedded_map_widget.dart';

class FiltersScreen extends ConsumerStatefulWidget {
  const FiltersScreen({super.key});

  @override
  ConsumerState<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends ConsumerState<FiltersScreen> {
  late TextEditingController _minBudgetController;
  late TextEditingController _maxBudgetController;
  late TextEditingController _majorController;

  RangeValues _cleanlinessRange = const RangeValues(1, 5);
  RangeValues _noiseRange = const RangeValues(1, 5);
  String? _year;
  String? _smoking;
  String? _pets;
  String? _studyHabits;
  String? _housingPreference;
  int? _maxDistanceMiles;
  DateTime? _moveInStart;
  MatchSortBy _sortBy = MatchSortBy.compatibility;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(matchFiltersProvider);
    _minBudgetController = TextEditingController(text: filters.minBudget?.toString() ?? '');
    _maxBudgetController = TextEditingController(text: filters.maxBudget?.toString() ?? '');
    _majorController = TextEditingController(text: filters.major ?? '');
    _cleanlinessRange = filters.cleanlinessRange;
    _noiseRange = filters.noiseToleranceRange;
    _year = filters.year;
    _smoking = filters.smokingPreference;
    _pets = filters.petsPreference;
    _studyHabits = filters.studyHabits;
    _housingPreference = filters.housingPreference;
    _maxDistanceMiles = filters.maxDistanceMiles;
    _moveInStart = filters.moveInStart;
    _sortBy = filters.sortBy;
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _moveInStart ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (selected != null) {
      setState(() {
        _moveInStart = selected;
      });
    }
  }

  void _applyFilters() {
    final filters = MatchFilters(
      minBudget: int.tryParse(_minBudgetController.text.trim()),
      maxBudget: int.tryParse(_maxBudgetController.text.trim()),
      major: _majorController.text.trim().isEmpty ? null : _majorController.text.trim(),
      year: _year,
      cleanlinessRange: _cleanlinessRange,
      noiseToleranceRange: _noiseRange,
      smokingPreference: _smoking,
      petsPreference: _pets,
      studyHabits: _studyHabits,
      housingPreference: _housingPreference,
      maxDistanceMiles: _maxDistanceMiles,
      moveInStart: _moveInStart,
      sortBy: _sortBy,
    );

    ref.read(matchFiltersProvider.notifier).updateFilters(filters);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied!')),
    );
  }

  void _resetFilters() {
    ref.read(matchFiltersProvider.notifier).reset();
    setState(() {
      _minBudgetController.clear();
      _maxBudgetController.clear();
      _majorController.clear();
      _cleanlinessRange = const RangeValues(1, 5);
      _noiseRange = const RangeValues(1, 5);
      _year = null;
      _smoking = null;
      _pets = null;
      _studyHabits = null;
      _housingPreference = null;
      _maxDistanceMiles = null;
      _moveInStart = null;
      _sortBy = MatchSortBy.compatibility;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(onPressed: _resetFilters, child: const Text('Reset')),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Budget range (USD)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minBudgetController,
                      decoration: const InputDecoration(labelText: 'Min', prefixText: '\$'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _maxBudgetController,
                      decoration: const InputDecoration(labelText: 'Max', prefixText: '\$'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildRoommatePreferenceSection(),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _year,
                decoration: const InputDecoration(labelText: 'Academic year'),
                items: [null, ...FormOptions.academicYears]
                    .map((year) => DropdownMenuItem(value: year, child: Text(year ?? 'Any')))
                    .toList(),
                onChanged: (value) => setState(() => _year = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _majorController,
                decoration: const InputDecoration(labelText: 'Major'),
              ),
              const SizedBox(height: 24),
              _buildRangeSection(
                label: 'Cleanliness preference',
                range: _cleanlinessRange,
                onChanged: (values) => setState(() => _cleanlinessRange = values),
              ),
              const SizedBox(height: 24),
              _buildRangeSection(
                label: 'Noise tolerance',
                range: _noiseRange,
                onChanged: (values) => setState(() => _noiseRange = values),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _pets,
                decoration: const InputDecoration(labelText: 'Pets preference'),
                items: [null, ...FormOptions.petsPreferences]
                    .map((option) => DropdownMenuItem(value: option, child: Text(option ?? 'Any')))
                    .toList(),
                onChanged: (value) => setState(() => _pets = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _smoking,
                decoration: const InputDecoration(labelText: 'Smoking preference'),
                items: [null, ...FormOptions.smokingPreferences]
                    .map((option) => DropdownMenuItem(value: option, child: Text(option ?? 'Any')))
                    .toList(),
                onChanged: (value) => setState(() => _smoking = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _studyHabits,
                decoration: const InputDecoration(labelText: 'Study habits'),
                items: [null, ...FormOptions.studyHabits]
                    .map((option) => DropdownMenuItem(value: option, child: Text(option ?? 'Any')))
                    .toList(),
                onChanged: (value) => setState(() => _studyHabits = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _housingPreference,
                decoration: const InputDecoration(labelText: 'Housing preference'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Either')),
                  DropdownMenuItem(value: 'on_campus', child: Text('On Campus Only')),
                  DropdownMenuItem(value: 'off_campus', child: Text('Off Campus Only')),
                ],
                onChanged: (value) {
                  setState(() => _housingPreference = value);
                  // Update provider immediately for real-time map visibility
                  ref.read(matchFiltersProvider.notifier).patchFilters(
                    (current) => current.copyWith(
                      housingPreference: value,
                      resetHousingPreference: value == null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Move-in date', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(_moveInStart == null ? 'Select date' : _formatDate(_moveInStart!)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              if (_moveInStart != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() => _moveInStart = null),
                    child: const Text('Clear date'),
                  ),
                ),
              // Show map only for off-campus or either (null) preferences
              if (_housingPreference == 'off_campus' || _housingPreference == null) ...[
                const SizedBox(height: 24),
                Text('Nearby matches', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                const EmbeddedMapWidget(),
                const SizedBox(height: 24),
                Text('Max distance', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  _maxDistanceMiles == null ? 'Any distance' : '${_maxDistanceMiles!} miles',
                  style: theme.textTheme.bodySmall,
                ),
                Slider(
                  value: _maxDistanceMiles?.toDouble() ?? 50,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  label: _maxDistanceMiles == null ? 'Any' : '$_maxDistanceMiles mi',
                  onChanged: (value) {
                    setState(() => _maxDistanceMiles = value.round());
                    // Update provider immediately for real-time map updates
                    ref.read(matchFiltersProvider.notifier).patchFilters(
                      (current) => current.copyWith(maxDistanceMiles: value.round()),
                    );
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 mi', style: theme.textTheme.bodySmall),
                    TextButton(
                      onPressed: () {
                        setState(() => _maxDistanceMiles = null);
                        // Update provider immediately
                        ref.read(matchFiltersProvider.notifier).patchFilters(
                          (current) => current.copyWith(maxDistanceMiles: null, resetMaxDistance: true),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                    Text('50 mi', style: theme.textTheme.bodySmall),
                  ],
                ),
              ] else
                const SizedBox(height: 24),
              Text('Sort by', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<MatchSortBy>(
                segments: const [
                  ButtonSegment(
                    value: MatchSortBy.compatibility,
                    label: Text('Match %', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: MatchSortBy.newest,
                    label: Text('Newest', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: MatchSortBy.distance,
                    label: Text('Distance', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_sortBy},
                onSelectionChanged: (selection) => setState(() => _sortBy = selection.first),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.check),
                  label: const Text('Apply filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSection({
    required String label,
    required RangeValues range,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label (${range.start.toStringAsFixed(0)} – ${range.end.toStringAsFixed(0)})'),
        RangeSlider(
          min: 1,
          max: 5,
          divisions: 4,
          values: range,
          labels: RangeLabels(range.start.toStringAsFixed(0), range.end.toStringAsFixed(0)),
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _buildRoommatePreferenceSection() {
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    
    return currentUserAsync.when(
      data: (currentUser) {
        if (currentUser == null) return const SizedBox.shrink();
        
        final currentPref = currentUser.roommatePreference ?? 'any';
        String displayLabel = 'No preference';
        if (currentPref == 'male_only') {
          displayLabel = 'Men only';
        } else if (currentPref == 'female_only') {
          displayLabel = 'Women only';
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roommate Preference',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current: $displayLabel',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'This affects who you see and who can see you',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showRoommatePreferenceDialog(currentUser),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _showRoommatePreferenceDialog(UserProfile currentUser) async {
    final currentPref = currentUser.roommatePreference ?? 'any';
    String? selectedPref = currentPref;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String getCurrentLabel(String pref) {
            if (pref == 'male_only') return 'Men only';
            if (pref == 'female_only') return 'Women only';
            return 'No preference';
          }
          
          return AlertDialog(
            title: const Text('Change Roommate Preference?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Changing your preference will affect:\n• Who you can see\n• Who can see your profile',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current preference: ${getCurrentLabel(currentPref)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...FormOptions.roommatePreferences.map((pref) {
                    final value = FormOptions.roommatePreferenceValues[pref]!;
                    return RadioListTile<String>(
                      title: Text(pref),
                      subtitle: Text(
                        value == 'male_only'
                            ? 'Only see men • Only visible to users looking for men'
                            : value == 'female_only'
                                ? 'Only see women • Only visible to users looking for women'
                                : 'See everyone • Only visible to users with "No preference"',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      value: value,
                      groupValue: selectedPref,
                      onChanged: (val) => setState(() => selectedPref = val),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedPref == currentPref
                    ? null
                    : () => Navigator.pop(context, selectedPref),
                child: const Text('Confirm Change'),
              ),
            ],
          );
        },
      ),
    );
    
    if (result != null && result != currentPref) {
      // Update the user's roommate preference in the database
      await ref.read(databaseServiceProvider).users
        .update({'roommate_preference': result})
        .eq('id', currentUser.id);
      
      // Refresh the profile
      ref.invalidate(currentUserProfileProvider);
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Roommate preference updated! Matches will refresh.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
