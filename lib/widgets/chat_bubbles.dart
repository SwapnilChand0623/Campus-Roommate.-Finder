import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isMine ? Theme.of(context).colorScheme.primary : Colors.grey.shade200;
    final textColor = isMine ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Card(
          color: bubbleColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('h:mm a').format(message.timestamp.toLocal()),
                  style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
