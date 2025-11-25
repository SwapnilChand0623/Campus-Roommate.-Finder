import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/chat_provider.dart';
import 'chat_room.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return conversationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Unable to load chats: $error')),
      data: (conversations) {
        if (conversations.isEmpty) {
          return const Center(child: Text('No conversations yet. Start a chat from the match feed!'));
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(conversationListProvider.notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final partner = conversation.partner;
              if (partner == null) return const SizedBox.shrink();
              final lastMessage = conversation.lastMessage;
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: partner.hasPhoto ? NetworkImage(partner.photoUrl!) : null,
                  child: partner.hasPhoto ? null : const Icon(Icons.person),
                ),
                title: Text(partner.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  lastMessage.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(DateFormat('MMM d').format(lastMessage.timestamp.toLocal())),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(partnerId: partner.id, partnerName: partner.fullName),
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
          ),
        );
      },
    );
  }
}
