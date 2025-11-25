import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;
  static const _bucket = 'profile-photos';

  Future<String> uploadProfilePhoto(File file) async {
    final userId = _client.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final fileName = 'avatars/$userId/${const Uuid().v4()}.$ext';

    final bytes = await file.readAsBytes();
    await _client.storage.from(_bucket).uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from(_bucket).getPublicUrl(fileName);
  }

  Future<String> uploadRoomPhoto(File file) async {
    final userId = _client.auth.currentUser!.id;
    final ext = file.path.split('.').last;
    final fileName = 'room/$userId/${const Uuid().v4()}.$ext';

    final bytes = await file.readAsBytes();
    await _client.storage.from(_bucket).uploadBinary(fileName, bytes, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from(_bucket).getPublicUrl(fileName);
  }

  Future<void> deleteProfilePhoto(String path) async {
    await _client.storage.from(_bucket).remove([path]);
  }
}
