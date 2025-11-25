import 'message.dart';
import 'user_profile.dart';

class ConversationSummary {
  ConversationSummary({required this.partner, required this.lastMessage});

  final UserProfile? partner;
  final Message lastMessage;
}
