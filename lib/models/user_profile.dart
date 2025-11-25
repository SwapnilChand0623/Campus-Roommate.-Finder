import 'dart:convert';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.age,
    required this.major,
    required this.year,
    required this.bio,
    required this.photoUrl,
    required this.budgetMin,
    required this.budgetMax,
    required this.sleepSchedule,
    required this.cleanliness,
    required this.noiseTolerance,
    required this.smoking,
    required this.pets,
    required this.guests,
    required this.personalityType,
    required this.studyHabits,
    required this.roommateExpectations,
    this.gender,
    this.roommatePreference,
    this.pronouns,
    required this.moveInDate,
    required this.socialLinks,
    required this.profileCompleted,
    this.universityName,
    this.housingStatus = 'on_campus',
    this.housingPreference = 'either',
    this.city,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.maxDistanceMiles = 20,
    this.roomPhotos = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? email;
  final String fullName;
  final int? age;
  final String? major;
  final String? year;
  final String? bio;
  final String? photoUrl;
  final int? budgetMin;
  final int? budgetMax;
  final String? sleepSchedule;
  final int? cleanliness;
  final int? noiseTolerance;
  final String? smoking;
  final String? pets;
  final String? guests;
  final String? personalityType;
  final String? studyHabits;
  final String? roommateExpectations;
  final String? gender; // 'male' | 'female' | 'other'
  final String? roommatePreference; // 'male_only' | 'female_only' | 'any'
  final String? pronouns; // Separate from gender
  final DateTime? moveInDate;
  final Map<String, dynamic>? socialLinks;
  final bool profileCompleted;
  final String? universityName;
  final String housingStatus; // 'on_campus' or 'off_campus'
  final String housingPreference; // 'on_campus', 'off_campus', or 'either'
  final String? city;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final int maxDistanceMiles;
  final List<String> roomPhotos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasPhoto => (photoUrl ?? '').isNotEmpty;

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    int? age,
    String? major,
    String? year,
    String? bio,
    String? photoUrl,
    int? budgetMin,
    int? budgetMax,
    String? sleepSchedule,
    int? cleanliness,
    int? noiseTolerance,
    String? smoking,
    String? pets,
    String? guests,
    String? personalityType,
    String? studyHabits,
    String? roommateExpectations,
    String? gender,
    String? roommatePreference,
    String? pronouns,
    DateTime? moveInDate,
    Map<String, dynamic>? socialLinks,
    bool? profileCompleted,
    String? universityName,
    String? housingStatus,
    String? housingPreference,
    String? city,
    String? zipCode,
    double? latitude,
    double? longitude,
    int? maxDistanceMiles,
    List<String>? roomPhotos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      major: major ?? this.major,
      year: year ?? this.year,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      budgetMin: budgetMin ?? this.budgetMin,
      budgetMax: budgetMax ?? this.budgetMax,
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      cleanliness: cleanliness ?? this.cleanliness,
      noiseTolerance: noiseTolerance ?? this.noiseTolerance,
      smoking: smoking ?? this.smoking,
      pets: pets ?? this.pets,
      guests: guests ?? this.guests,
      personalityType: personalityType ?? this.personalityType,
      studyHabits: studyHabits ?? this.studyHabits,
      roommateExpectations: roommateExpectations ?? this.roommateExpectations,
      gender: gender ?? this.gender,
      roommatePreference: roommatePreference ?? this.roommatePreference,
      pronouns: pronouns ?? this.pronouns,
      moveInDate: moveInDate ?? this.moveInDate,
      socialLinks: socialLinks ?? this.socialLinks,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      universityName: universityName ?? this.universityName,
      housingStatus: housingStatus ?? this.housingStatus,
      housingPreference: housingPreference ?? this.housingPreference,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxDistanceMiles: maxDistanceMiles ?? this.maxDistanceMiles,
      roomPhotos: roomPhotos ?? this.roomPhotos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'age': age,
      'major': major,
      'year': year,
      'bio': bio,
      'photo_url': photoUrl,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'sleep_schedule': sleepSchedule,
      'cleanliness': cleanliness,
      'noise_tolerance': noiseTolerance,
      'smoking': smoking,
      'pets': pets,
      'guests': guests,
      'personality_type': personalityType,
      'study_habits': studyHabits,
      'roommate_expectations': roommateExpectations,
      'gender': gender,
      'roommate_preference': roommatePreference,
      'pronouns': pronouns,
      'move_in_date': moveInDate?.toIso8601String(),
      'social_links': socialLinks == null ? null : jsonEncode(socialLinks),
      'profile_completed': profileCompleted,
      'university_name': universityName,
      'housing_status': housingStatus,
      'housing_preference': housingPreference,
      'city': city,
      'zip_code': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'max_distance_miles': maxDistanceMiles,
      'room_photos': roomPhotos,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    }..removeWhere((key, value) => value == null);
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final rawRoomPhotos = map['room_photos'];
    final roomPhotos = rawRoomPhotos is List
        ? rawRoomPhotos
            .where((e) => e != null)
            .map((e) => e.toString())
            .toList()
        : <String>[];

    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String? ?? '',
      age: map['age'] as int?,
      major: map['major'] as String?,
      year: map['year'] as String?,
      bio: map['bio'] as String?,
      photoUrl: map['photo_url'] as String?,
      budgetMin: map['budget_min'] as int?,
      budgetMax: map['budget_max'] as int?,
      sleepSchedule: map['sleep_schedule'] as String?,
      cleanliness: map['cleanliness'] as int?,
      noiseTolerance: map['noise_tolerance'] as int?,
      smoking: map['smoking'] as String?,
      pets: map['pets'] as String?,
      guests: map['guests'] as String?,
      personalityType: map['personality_type'] as String?,
      studyHabits: map['study_habits'] as String?,
      roommateExpectations: map['roommate_expectations'] as String?,
      gender: map['gender'] as String?,
      roommatePreference: map['roommate_preference'] as String?,
      pronouns: map['pronouns'] as String?,
      moveInDate:
          map['move_in_date'] == null ? null : DateTime.tryParse(map['move_in_date'] as String),
      socialLinks: map['social_links'] == null
          ? null
          : (map['social_links'] is Map<String, dynamic>
              ? map['social_links'] as Map<String, dynamic>
              : jsonDecode(map['social_links'].toString()) as Map<String, dynamic>),
      profileCompleted: (map['profile_completed'] as bool?) ?? false,
      universityName: map['university_name'] as String?,
      housingStatus: map['housing_status'] as String? ?? 'on_campus',
      housingPreference: map['housing_preference'] as String? ?? 'either',
      city: map['city'] as String?,
      zipCode: map['zip_code'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      maxDistanceMiles: map['max_distance_miles'] as int? ?? 20,
      roomPhotos: roomPhotos,
      createdAt: map['created_at'] == null ? null : DateTime.tryParse(map['created_at'] as String),
      updatedAt: map['updated_at'] == null ? null : DateTime.tryParse(map['updated_at'] as String),
    );
  }
}
