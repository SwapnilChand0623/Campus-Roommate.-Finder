import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_summary.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class DatabaseService {
  DatabaseService(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get users => _client.from('users');
  SupabaseQueryBuilder get messages => _client.from('messages');
  SupabaseQueryBuilder get favorites => _client.from('favorites');
  SupabaseQueryBuilder get likes => _client.from('likes');

  Future<UserProfile?> fetchCurrentUserProfile(String uid) async {
    final response = await users.select().eq('id', uid).maybeSingle();
    if (response == null) return null;
    return UserProfile.fromMap(response as Map<String, dynamic>);
  }

  Future<UserProfile?> fetchUserById(String uid) async {
    final response = await users.select().eq('id', uid).maybeSingle();
    if (response == null) return null;
    return UserProfile.fromMap(response as Map<String, dynamic>);
  }

  Future<void> upsertProfile(UserProfile profile) async {
    await users.upsert(profile.toMap());
  }

  Future<List<UserProfile>> fetchMatches(String uid) async {
    final response = await users
        .select()
        .neq('id', uid)
        .order('updated_at', ascending: false)
        .limit(100);
    final data = response as List<dynamic>;
    return data.map((e) => UserProfile.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<UserProfile>> fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final response = await users.select().inFilter('id', ids);
    final data = response as List<dynamic>;
    return data.map((e) => UserProfile.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<Message>> fetchMessages(String partnerId) async {
    final currentUserId = _client.auth.currentUser!.id;
    final response = await messages
        .select()
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .or('sender_id.eq.$partnerId,receiver_id.eq.$partnerId')
        .order('timestamp', ascending: true);

    final data = response as List<dynamic>;
    return data
        .map((e) => Message.fromMap(e as Map<String, dynamic>, currentUserId: currentUserId))
        .toList();
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final currentUserId = _client.auth.currentUser!.id;
    
    // Prevent self-messaging
    if (receiverId == currentUserId) {
      throw Exception('Cannot send message to yourself');
    }
    
    await messages.insert({
      'sender_id': currentUserId,
      'receiver_id': receiverId,
      'content': content,
    });
  }

  Future<void> deleteConversation(String partnerId) async {
    final currentUserId = _client.auth.currentUser!.id;
    await messages
        .delete()
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$partnerId),and(sender_id.eq.$partnerId,receiver_id.eq.$currentUserId)');
  }

  Future<void> addFavorite(String userId) async {
    final currentUserId = _client.auth.currentUser!.id;
    await favorites.insert({
      'user_id': currentUserId,
      'favorite_id': userId,
    });
  }

  Future<void> removeFavorite(String userId) async {
    final currentUserId = _client.auth.currentUser!.id;
    await favorites.delete().eq('user_id', currentUserId).eq('favorite_id', userId);
  }

  Future<List<String>> fetchFavoriteIds() async {
    final currentUserId = _client.auth.currentUser!.id;
    final response = await favorites.select('favorite_id').eq('user_id', currentUserId);
    final data = response as List<dynamic>;
    return data.map((e) => e['favorite_id'] as String).toList();
  }

  Future<List<UserProfile>> fetchFavoriteProfiles() async {
    final ids = await fetchFavoriteIds();
    return fetchUsersByIds(ids);
  }

  Future<void> likeUser(String userId, String likedUserId) async {
    final existing = await likes
        .select('id')
        .eq('user_id', userId)
        .eq('liked_user_id', likedUserId)
        .maybeSingle();

    if (existing != null) {
      return;
    }

    await likes.insert({
      'user_id': userId,
      'liked_user_id': likedUserId,
    });
  }

  Future<void> removeLike(String likedUserId) async {
    final currentUserId = _client.auth.currentUser!.id;
    await likes.delete().eq('user_id', currentUserId).eq('liked_user_id', likedUserId);
  }

  /// Remove a mutual match - removes BOTH users' likes
  /// Use this when unmatching from the Matches screen
  Future<void> removeMatch(String userId, String otherUserId) async {
    try {
      // Use Postgres function to delete both sides with elevated privileges
      await _client.rpc('unmatch_users', params: {
        'user1': userId,
        'user2': otherUserId,
      });
    } catch (e) {
      print('Error removing match via RPC: $e');
      rethrow;
    }
  }

  Future<bool> isMutualLike(String userId, String otherUserId) async {
    final existing = await likes
        .select('id')
        .eq('user_id', otherUserId)
        .eq('liked_user_id', userId)
        .maybeSingle();
    return existing != null;
  }

  Future<List<UserProfile>> fetchLikedUsers(String userId) async {
    final response = await likes.select('liked_user_id').eq('user_id', userId);
    final data = response as List<dynamic>;
    final ids = data
        .map((row) => row['liked_user_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();
    if (ids.isEmpty) return [];
    return fetchUsersByIds(ids);
  }

  Future<List<String>> fetchLikedUserIds(String userId) async {
    final response = await likes.select('liked_user_id').eq('user_id', userId);
    final data = response as List<dynamic>;
    return data
        .map((row) => row['liked_user_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();
  }

  Future<List<UserProfile>> fetchMutualMatches(String userId) async {
    final myLikesResponse = await likes.select('liked_user_id').eq('user_id', userId);
    final likedMeResponse = await likes.select('user_id').eq('liked_user_id', userId);

    final myLikesData = myLikesResponse as List<dynamic>;
    final likedMeData = likedMeResponse as List<dynamic>;

    final myLikedIds = myLikesData
        .map((row) => row['liked_user_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    final likedMeIds = likedMeData
        .map((row) => row['user_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    final mutualIds = myLikedIds.intersection(likedMeIds).toList();
    if (mutualIds.isEmpty) return [];
    return fetchUsersByIds(mutualIds);
  }

  Future<List<ConversationSummary>> fetchConversationSummaries() async {
    final currentUserId = _client.auth.currentUser!.id;
    final response = await messages
        .select('id,sender_id,receiver_id,content,timestamp')
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .order('timestamp', ascending: false);

    final data = response as List<dynamic>;
    final Map<String, Message> latestMessages = {};

    for (final raw in data) {
      final message = Message.fromMap(raw as Map<String, dynamic>, currentUserId: currentUserId);
      final partnerId = message.senderId == currentUserId ? message.receiverId : message.senderId;
      latestMessages.putIfAbsent(partnerId, () => message);
    }

    final partnerProfiles = await fetchUsersByIds(latestMessages.keys.toList());
    final profileMap = {for (final profile in partnerProfiles) profile.id: profile};

    return latestMessages.entries
        .map((entry) => ConversationSummary(
              partner: profileMap[entry.key],
              lastMessage: entry.value,
            ))
        .where((summary) => summary.partner != null)
        .cast<ConversationSummary>()
        .toList();
  }

  Stream<List<Message>> watchMessages(String partnerId) {
    final currentUserId = _client.auth.currentUser!.id;
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: true)
        .map((snapshot) {
          final messagesForConversation = snapshot
              .where((row) {
                final map = row as Map<String, dynamic>;
                final senderId = map['sender_id'] as String?;
                final receiverId = map['receiver_id'] as String?;
                return (senderId == currentUserId && receiverId == partnerId) ||
                    (senderId == partnerId && receiverId == currentUserId);
              })
              .map((row) =>
                  Message.fromMap(row as Map<String, dynamic>, currentUserId: currentUserId))
              .toList();

          messagesForConversation
              .sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messagesForConversation;
        });
  }
}
