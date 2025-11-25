import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/geocoding_service.dart';
import '../services/matching_service.dart';
import '../services/storage_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DatabaseService(client);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StorageService(client);
});

final matchingServiceProvider = Provider<MatchingService>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return MatchingService(db);
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});
