/// Model đại diện cho tin nhắn trong chat
class Message {
  final int id;
  final int courtId;
  final int userId;
  final bool isFromUser; // true = user gửi, false = chủ sân reply (mock)
  final String text;
  final String timestamp; // ISO 8601

  const Message({
    required this.id,
    required this.courtId,
    required this.userId,
    required this.isFromUser,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as int,
        courtId: map['court_id'] as int,
        userId: map['user_id'] as int,
        isFromUser: (map['is_from_user'] as int) == 1,
        text: map['text'] as String,
        timestamp: map['timestamp'] as String,
      );

  Map<String, dynamic> toMap() => {
        'court_id': courtId,
        'user_id': userId,
        'is_from_user': isFromUser ? 1 : 0,
        'text': text,
        'timestamp': timestamp,
      };

  factory Message.fromFirestore(Map<String, dynamic> data) => Message(
        id: data['id'] as int,
        courtId: data['courtId'] as int,
        userId: data['userId'] as int,
        isFromUser: data['isFromUser'] as bool,
        text: data['text'] as String,
        timestamp: data['timestamp'] as String,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'courtId': courtId,
        'userId': userId,
        'isFromUser': isFromUser,
        'text': text,
        'timestamp': timestamp,
      };

  Message copyWith({
    int? id,
    int? courtId,
    int? userId,
    bool? isFromUser,
    String? text,
    String? timestamp,
  }) =>
      Message(
        id: id ?? this.id,
        courtId: courtId ?? this.courtId,
        userId: userId ?? this.userId,
        isFromUser: isFromUser ?? this.isFromUser,
        text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp,
      );
}
