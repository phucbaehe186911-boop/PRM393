/// Model đại diện cho một khung giờ của sân
class TimeSlot {
  final int id;
  final int courtId;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:MM
  final String endTime; // HH:MM
  final bool isAvailable;

  const TimeSlot({
    required this.id,
    required this.courtId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) => TimeSlot(
        id: map['id'] as int,
        courtId: map['court_id'] as int,
        date: map['date'] as String,
        startTime: map['start_time'] as String,
        endTime: map['end_time'] as String,
        isAvailable: (map['is_available'] as int) == 1,
      );

  Map<String, dynamic> toMap() => {
        'court_id': courtId,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'is_available': isAvailable ? 1 : 0,
      };

  factory TimeSlot.fromFirestore(Map<String, dynamic> data) => TimeSlot(
        id: data['id'] as int,
        courtId: data['courtId'] as int,
        date: data['date'] as String,
        startTime: data['startTime'] as String,
        endTime: data['endTime'] as String,
        isAvailable: data['isAvailable'] as bool,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'courtId': courtId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'isAvailable': isAvailable,
      };

  TimeSlot copyWith({
    int? id,
    int? courtId,
    String? date,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) =>
      TimeSlot(
        id: id ?? this.id,
        courtId: courtId ?? this.courtId,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isAvailable: isAvailable ?? this.isAvailable,
      );

  /// Kiểm tra giờ có phải peak hour không (17:00 – 21:00)
  bool get isPeak {
    final hour = int.tryParse(startTime.split(':')[0]) ?? 0;
    return hour >= 17 && hour < 21;
  }
}
