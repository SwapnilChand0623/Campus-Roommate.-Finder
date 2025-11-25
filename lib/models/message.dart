class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isMine = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isMine;

  factory Message.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final senderId = map['sender_id'] as String;
    return Message(
      id: map['id'] as String,
      senderId: senderId,
      receiverId: map['receiver_id'] as String,
      content: map['content'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      isMine: currentUserId != null && senderId == currentUserId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
