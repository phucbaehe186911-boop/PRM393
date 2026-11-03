import 'dart:convert';

/// Model đại diện cho một lượt đặt sân
class Booking {
  final int id;
  final int courtId;
  final int userId;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final double totalPrice;
  final String status; // 'confirmed' | 'cancelled'
  final Map<String, bool> addons; // {"racket":true,"ball":false}
  final String createdAt;
  // Trường join từ query JOIN với bảng courts
  final String? courtName;
  final String? courtType;
  // Hoàn tiền khi huỷ sân trước thời hạn
  final double refundAmount;
  final String? refundStatus; // 'refunded' | 'non_refundable' | 'pending'
  final String? refundReason;

  const Booking({
    required this.id,
    required this.courtId,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.addons,
    required this.createdAt,
    this.courtName,
    this.courtType,
    this.refundAmount = 0.0,
    this.refundStatus,
    this.refundReason,
  });

  factory Booking.fromMap(Map<String, dynamic> map) => Booking(
        id: map['id'] as int,
        courtId: map['court_id'] as int,
        userId: map['user_id'] as int,
        date: map['date'] as String,
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String,
        totalPrice: (map['total_price'] as num).toDouble(),
        status: map['status'] as String? ?? 'confirmed',
        addons: map['addons'] != null
            ? Map<String, bool>.from(jsonDecode(map['addons'] as String))
            : {},
        createdAt: map['created_at'] as String,
        courtName: map['court_name'] as String?,
        courtType: map['court_type'] as String?,
        refundAmount: (map['refund_amount'] as num?)?.toDouble() ?? 0.0,
        refundStatus: map['refund_status'] as String?,
        refundReason: map['refund_reason'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'court_id': courtId,
        'user_id': userId,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'total_price': totalPrice,
        'status': status,
        'addons': jsonEncode(addons),
        'created_at': createdAt,
        'refund_amount': refundAmount,
        'refund_status': refundStatus,
        'refund_reason': refundReason,
      };

  factory Booking.fromFirestore(Map<String, dynamic> data) => Booking(
        id: data['id'] as int,
        courtId: data['courtId'] as int,
        userId: data['userId'] as int,
        date: data['date'] as String,
        startTime: data['startTime'] as String,
        endTime: data['endTime'] as String,
        totalPrice: (data['totalPrice'] as num).toDouble(),
        status: data['status'] as String? ?? 'confirmed',
        addons: data['addons'] != null
            ? Map<String, bool>.from(data['addons'] as Map)
            : {},
        createdAt: data['createdAt'] as String,
        courtName: data['courtName'] as String?,
        courtType: data['courtType'] as String?,
        refundAmount: (data['refundAmount'] as num?)?.toDouble() ?? 0.0,
        refundStatus: data['refundStatus'] as String?,
        refundReason: data['refundReason'] as String?,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'courtId': courtId,
        'userId': userId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'totalPrice': totalPrice,
        'status': status,
        'addons': addons,
        'createdAt': createdAt,
        if (courtName != null) 'courtName': courtName,
        if (courtType != null) 'courtType': courtType,
        'refundAmount': refundAmount,
        if (refundStatus != null) 'refundStatus': refundStatus,
        if (refundReason != null) 'refundReason': refundReason,
      };

  Booking copyWith({
    int? id,
    int? courtId,
    int? userId,
    String? date,
    String? startTime,
    String? endTime,
    double? totalPrice,
    String? status,
    Map<String, bool>? addons,
    String? createdAt,
    String? courtName,
    String? courtType,
    double? refundAmount,
    String? refundStatus,
    String? refundReason,
  }) =>
      Booking(
        id: id ?? this.id,
        courtId: courtId ?? this.courtId,
        userId: userId ?? this.userId,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        totalPrice: totalPrice ?? this.totalPrice,
        status: status ?? this.status,
        addons: addons ?? this.addons,
        createdAt: createdAt ?? this.createdAt,
        courtName: courtName ?? this.courtName,
        courtType: courtType ?? this.courtType,
        refundAmount: refundAmount ?? this.refundAmount,
        refundStatus: refundStatus ?? this.refundStatus,
        refundReason: refundReason ?? this.refundReason,
      );
}
