import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/conversation_summary.dart';
import '../models/message.dart';
import 'supabase_providers.dart';

final conversationListProvider = AsyncNotifierProvider<ConversationListNotifier, List<ConversationSummary>>(
  ConversationListNotifier.new,
);

class ConversationListNotifier extends AsyncNotifier<List<ConversationSummary>> {
  @override
  Future<List<ConversationSummary>> build() async {
    final db = ref.watch(databaseServiceProvider);
    return db.fetchConversationSummaries();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final db = ref.watch(databaseServiceProvider);
    state = await AsyncValue.guard(() => db.fetchConversationSummaries());
  }
}

final chatMessagesProvider = StreamProvider.family<List<Message>, String>((ref, partnerId) {
  final db = ref.watch(databaseServiceProvider);
  return db.watchMessages(partnerId);
});
