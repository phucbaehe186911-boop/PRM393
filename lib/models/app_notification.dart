/// Model thông báo trong app (đặt tên AppNotification để tránh conflict với dart:ui)
class AppNotification {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type; // 'booking' | 'cancel' | 'reminder' | 'system'
  final bool isRead;
  final String createdAt; // ISO 8601
  final int? bookingId; // nullable — link tới lịch đặt liên quan

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.bookingId,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] as int,
        userId: map['user_id'] as int,
        title: map['title'] as String,
        body: map['body'] as String,
        type: map['type'] as String,
        isRead: (map['is_read'] as int) == 1,
        createdAt: map['created_at'] as String,
        bookingId: map['booking_id'] as int?,
      );

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'is_read': isRead ? 1 : 0,
        'created_at': createdAt,
        if (bookingId != null) 'booking_id': bookingId,
      };

  factory AppNotification.fromFirestore(Map<String, dynamic> data) =>
      AppNotification(
        id: data['id'] as int,
        userId: data['userId'] as int,
        title: data['title'] as String,
        body: data['body'] as String,
        type: data['type'] as String,
        isRead: data['isRead'] as bool,
        createdAt: data['createdAt'] as String,
        bookingId: data['bookingId'] as int?,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': isRead,
        'createdAt': createdAt,
        if (bookingId != null) 'bookingId': bookingId,
      };

  AppNotification copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    String? createdAt,
    int? bookingId,
  }) =>
      AppNotification(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        bookingId: bookingId ?? this.bookingId,
      );
}
