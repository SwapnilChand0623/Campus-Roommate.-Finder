class FormOptions {
  static const academicYears = [
    'Freshman UG',
    'Sophomore UG',
    'Junior UG',
    'Senior UG',
    '1st Grad',
    '2nd Grad',
    '3rd Grad',
    '1st PhD',
    '2nd PhD',
    '3rd PhD',
    '4th PhD',
    'Other',
  ];

  static const sleepSchedules = [
    'Early bird',
    'Night owl',
    'Flexible',
  ];

  static const studyHabits = ['Library', 'Home', 'Both'];

  // NEW GENDER SYSTEM
  static const genders = ['Male', 'Female', 'Other'];
  
  static const roommatePreferences = [
    'Men only',
    'Women only',
    'No preference',
  ];
  
  // Map display labels to database values
  static const roommatePreferenceValues = {
    'Men only': 'male_only',
    'Women only': 'female_only',
    'No preference': 'any',
  };
  
  static const genderValues = {
    'Male': 'male',
    'Female': 'female',
    'Other': 'other',
  };

  // Pronouns (separate from gender)
  static const pronounOptions = ['He/Him', 'She/Her', 'They/Them', 'Other'];

  static const yesNoOptions = ['Yes', 'No'];

  static const personalityTypes = ['Introvert', 'Extrovert', 'Ambivert'];

  static const smokingPreferences = ['Non-smoker', 'Smoker', 'Social smoker'];

  static const petsPreferences = ['No pets', 'Pets ok', 'Allergic'];

  static const guestTolerance = ['Rarely', 'Sometimes', 'Often'];
}
