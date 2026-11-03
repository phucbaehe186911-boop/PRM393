import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/court.dart';
import '../models/time_slot.dart';
import '../models/booking.dart';
import '../models/message.dart';
import '../models/app_notification.dart';

/// Singleton service quản lý toàn bộ Firestore CRUD cho SportZone.
/// Mirrors DatabaseService API exactly — ViewModels need only swap the import.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _seeded = false;

  // ── Local In-Memory Fallback Cache (đảm bảo app luôn chạy mượt kể cả khi offline)
  static final List<User> _localUsers = [
    User(
      id: 1,
      name: 'Quản Trị Viên',
      email: 'admin@sportzone.com',
      password: sha256.convert(utf8.encode('admin123')).toString(),
      phone: '0900000001',
      role: 'admin',
      createdAt: '2026-01-01T00:00:00.000',
    ),
    User(
      id: 2,
      name: 'Chủ Sân SportZone',
      email: 'owner@sportzone.com',
      password: sha256.convert(utf8.encode('owner123')).toString(),
      phone: '0901234567',
      role: 'owner',
      createdAt: '2026-01-01T00:00:00.000',
    ),
    User(
      id: 3,
      name: 'Nguyễn Văn A',
      email: 'user@sportzone.com',
      password: sha256.convert(utf8.encode('user123')).toString(),
      phone: '0987654321',
      role: 'user',
      createdAt: '2026-01-01T00:00:00.000',
    ),
  ];
  static List<Court> _localCourts = [];
  static final List<Booking> _localBookings = [];

  void _initLocalCourts() {
    if (_localCourts.isNotEmpty) return;
    final list = _getSeedCourts();
    _localCourts = list.asMap().entries.map((entry) {
      final i = entry.key;
      final c = entry.value;
      final List<String> images =
          List<String>.from(jsonDecode(c['images'] as String) as List);
      return Court(
        id: i + 1,
        name: c['name'],
        type: c['type'],
        address: c['address'],
        lat: c['lat'],
        lng: c['lng'],
        pricePerHour: c['price_per_hour'],
        peakPricePerHour: c['peak_price_per_hour'],
        description: c['description'],
        images: images,
        rating: c['rating'],
        reviewCount: c['review_count'],
        ownerId: 2,
      );
    }).toList();
  }

  void _saveLocalUser(User user) {
    final idx = _localUsers.indexWhere((u) =>
        u.id == user.id || u.email.toLowerCase() == user.email.toLowerCase());
    if (idx != -1) {
      _localUsers[idx] = user;
    } else {
      _localUsers.add(user);
    }
  }

  String _hashPassword(String pw) {
    return sha256.convert(utf8.encode(pw)).toString();
  }

  // ── Counter ───────────────────────────────────────────────────────────────

  /// Atomically increments [field] in _counters/counters and returns the new value.
  Future<int> _nextId(String field) async {
    final ref = _db.collection('_counters').doc('counters');
    int result = 0;
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final cur = snap.exists ? ((snap.data()?[field] as int?) ?? 0) : 0;
      result = cur + 1;
      tx.set(ref, {field: result}, SetOptions(merge: true));
    });
    return result;
  }

  Future<void> _initializeIfNeeded() async {
    if (_seeded) return;
    await _seedUsersIfEmpty();
    await _seedCourtsIfEmpty();
    _seeded = true;
  }

  // ── Seed ─────────────────────────────────────────────────────────────────

  /// Tạo sẵn 3 tài khoản mặc định (Admin, Owner, User)
  Future<void> _seedUsersIfEmpty() async {
    try {
      final snap = await _db.collection('users').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now().toIso8601String();
      final defaultUsers = [
        User(
          id: 1,
          name: 'Quản Trị Viên',
          email: 'admin@sportzone.com',
          password: _hashPassword('admin123'),
          phone: '0900000001',
          role: 'admin',
          createdAt: now,
        ),
        User(
          id: 2,
          name: 'Chủ Sân SportZone',
          email: 'owner@sportzone.com',
          password: _hashPassword('owner123'),
          phone: '0901234567',
          role: 'owner',
          createdAt: now,
        ),
        User(
          id: 3,
          name: 'Nguyễn Văn A',
          email: 'user@sportzone.com',
          password: _hashPassword('user123'),
          phone: '0987654321',
          role: 'user',
          createdAt: now,
        ),
      ];

      final batch = _db.batch();
      for (final u in defaultUsers) {
        batch.set(_db.collection('users').doc(u.id.toString()), u.toFirestore());
      }
      await batch.commit();

      await _db.collection('_counters').doc('counters').set({
        'nextUserId': 3,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService._seedUsersIfEmpty error: $e');
    }
  }

  Future<void> _seedCourtsIfEmpty() async {
    // 1. Check if courts already exist
    final existing = await _db.collection('courts').limit(1).get();
    if (existing.docs.isNotEmpty) return;

    // 2. Init counters document with all fields = 0
    await _db.collection('_counters').doc('counters').set({
      'nextUserId': 3,
      'nextCourtId': 15,
      'nextBookingId': 0,
      'nextReviewId': 0,
      'nextMessageId': 0,
      'nextNotificationId': 0,
      'nextTimeSlotId': 0,
    }, SetOptions(merge: true));

    // 3. Batch-insert 15 courts (IDs 1–15), transforming snake_case → camelCase
    //    and decoding JSON-encoded images → List<String>
    final courts = _getSeedCourts();
    final courtBatch = _db.batch();
    for (int i = 0; i < courts.length; i++) {
      final c = courts[i];
      final courtId = i + 1;
      final List<String> images =
          List<String>.from(jsonDecode(c['images'] as String) as List);
      courtBatch.set(
        _db.collection('courts').doc(courtId.toString()),
        {
          'id': courtId,
          'name': c['name'],
          'type': c['type'],
          'address': c['address'],
          'lat': c['lat'],
          'lng': c['lng'],
          'pricePerHour': c['price_per_hour'],
          'peakPricePerHour': c['peak_price_per_hour'],
          'description': c['description'],
          'images': images,
          'rating': c['rating'],
          'reviewCount': c['review_count'],
          'ownerId': 2, // Gán cho tài khoản Owner mặc định quản lý
        },
      );
    }
    await courtBatch.commit();

    // 4. Batch-insert time slots for 15 courts × 7 days × 18 slots (05:00–22:00)
    //    Commits every 400 operations to stay under Firestore's 500-op limit.
    final rng = Random(42);
    final now = DateTime.now();
    WriteBatch slotBatch = _db.batch();
    int batchCount = 0;
    int totalSlots = 0;

    for (int courtIdx = 0; courtIdx < 15; courtIdx++) {
      final courtId = courtIdx + 1;
      for (int d = 0; d < 7; d++) {
        final date = now.add(Duration(days: d));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        for (int h = 5; h < 23; h++) {
          final startTime = '${h.toString().padLeft(2, '0')}:00';
          final endTime = '${(h + 1).toString().padLeft(2, '0')}:00';
          final isAvailable = rng.nextDouble() > 0.30;
          totalSlots++;
          slotBatch.set(
            _db.collection('time_slots').doc(totalSlots.toString()),
            {
              'id': totalSlots,
              'courtId': courtId,
              'date': dateStr,
              'startTime': startTime,
              'endTime': endTime,
              'isAvailable': isAvailable,
            },
          );
          batchCount++;
          if (batchCount >= 400) {
            await slotBatch.commit();
            slotBatch = _db.batch();
            batchCount = 0;
          }
        }
      }
    }
    // Commit any remaining slots
    if (batchCount > 0) {
      await slotBatch.commit();
    }

    // 5. Update the time-slot counter to the total inserted
    await _db.collection('_counters').doc('counters').update({
      'nextTimeSlotId': totalSlots,
    });
  }

  /// Verbatim copy of _getSeedCourts() from database_service.dart
  List<Map<String, dynamic>> _getSeedCourts() {
    final pickleballImages = jsonEncode([
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800',
      'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=800',
    ]);
    final badmintonImages = jsonEncode([
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      'https://images.unsplash.com/photo-1544473244-3ae36ea44df4?w=800',
    ]);
    final footballImages = jsonEncode([
      'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800',
      'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?w=800',
    ]);
    final tennisImages = jsonEncode([
      'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?w=800',
      'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800',
    ]);

    return [
      // ── 5 Pickleball – Hà Nội ─────────────────────────────────────────
      {
        'name': 'Cụm sân Pickleball Yên Xá',
        'type': 'pickleball',
        'address': 'Đường Yên Xá, Thanh Xuân, Hà Nội',
        'lat': 20.9956,
        'lng': 105.8027,
        'price_per_hour': 80000.0,
        'peak_price_per_hour': 180000.0,
        'description':
            'Cụm 6 sân pickleball tiêu chuẩn thi đấu, trong nhà có máy lạnh. Thảm cao su chất lượng cao, ánh sáng đạt chuẩn thi đấu quốc tế.',
        'images': pickleballImages,
        'rating': 4.8,
        'review_count': 42,
      },
      {
        'name': 'Sân Pickleball Cầu Giấy',
        'type': 'pickleball',
        'address': 'Phố Trần Thái Tông, Cầu Giấy, Hà Nội',
        'lat': 21.0359,
        'lng': 105.7847,
        'price_per_hour': 90000.0,
        'peak_price_per_hour': 190000.0,
        'description':
            'Sân pickleball ngoài trời có mái che, bãi đỗ xe rộng rãi. Gần khu văn phòng, thích hợp chơi buổi trưa và tối.',
        'images': pickleballImages,
        'rating': 4.5,
        'review_count': 28,
      },
      {
        'name': 'SportZone Đống Đa',
        'type': 'pickleball',
        'address': 'Phố Tây Sơn, Đống Đa, Hà Nội',
        'lat': 21.0278,
        'lng': 105.8412,
        'price_per_hour': 85000.0,
        'peak_price_per_hour': 185000.0,
        'description':
            'Trung tâm thể thao đa năng với 4 sân pickleball, phòng thay đồ đầy đủ tiện nghi, café thể thao.',
        'images': pickleballImages,
        'rating': 4.6,
        'review_count': 35,
      },
      {
        'name': 'Sân Pickleball Hai Bà Trưng',
        'type': 'pickleball',
        'address': 'Phố Bùi Thị Xuân, Hai Bà Trưng, Hà Nội',
        'lat': 21.0062,
        'lng': 105.8562,
        'price_per_hour': 80000.0,
        'peak_price_per_hour': 170000.0,
        'description':
            'Sân pickleball trong nhà, sàn gỗ cứng cao cấp, điều hoà nhiệt độ. Cho thuê vợt và bóng chất lượng tốt.',
        'images': pickleballImages,
        'rating': 4.3,
        'review_count': 19,
      },
      {
        'name': 'Cụm sân Pickleball Hoàng Mai',
        'type': 'pickleball',
        'address': 'Phố Giải Phóng, Hoàng Mai, Hà Nội',
        'lat': 20.9742,
        'lng': 105.8456,
        'price_per_hour': 75000.0,
        'peak_price_per_hour': 160000.0,
        'description':
            'Cụm 8 sân pickleball lớn nhất phía Nam Hà Nội, bãi đỗ xe ô tô miễn phí, khu vực khán giả.',
        'images': pickleballImages,
        'rating': 4.7,
        'review_count': 61,
      },
      // ── 4 Cầu lông – Hà Nội ───────────────────────────────────────────
      {
        'name': 'Nhà thi đấu Cầu lông Mỹ Đình',
        'type': 'badminton',
        'address': 'Đường Lê Đức Thọ, Nam Từ Liêm, Hà Nội',
        'lat': 21.0197,
        'lng': 105.7648,
        'price_per_hour': 70000.0,
        'peak_price_per_hour': 150000.0,
        'description':
            'Nhà thi đấu cầu lông chuyên nghiệp 12 sân, sàn gỗ thi đấu, ánh sáng LED tiêu chuẩn BWF.',
        'images': badmintonImages,
        'rating': 4.9,
        'review_count': 87,
      },
      {
        'name': 'Sân cầu lông Nam Từ Liêm',
        'type': 'badminton',
        'address': 'Phố Trần Hữu Dực, Nam Từ Liêm, Hà Nội',
        'lat': 21.0127,
        'lng': 105.7551,
        'price_per_hour': 65000.0,
        'peak_price_per_hour': 140000.0,
        'description':
            'Sân cầu lông bình dân, giá hợp lý, đông khách. Có cửa hàng bán dụng cụ thể thao.',
        'images': badmintonImages,
        'rating': 4.2,
        'review_count': 33,
      },
      {
        'name': 'Cầu lông Hà Đông Arena',
        'type': 'badminton',
        'address': 'Đường Quang Trung, Hà Đông, Hà Nội',
        'lat': 20.9636,
        'lng': 105.7783,
        'price_per_hour': 60000.0,
        'peak_price_per_hour': 130000.0,
        'description':
            'Khu phức hợp thể thao 20 sân cầu lông, có huấn luyện viên, nhà hàng ẩm thực trong khuôn viên.',
        'images': badmintonImages,
        'rating': 4.4,
        'review_count': 52,
      },
      {
        'name': 'Sân cầu lông Long Biên',
        'type': 'badminton',
        'address': 'Phố Ngô Gia Tự, Long Biên, Hà Nội',
        'lat': 21.0513,
        'lng': 105.9048,
        'price_per_hour': 65000.0,
        'peak_price_per_hour': 135000.0,
        'description':
            'Sân cầu lông khu vực Long Biên, thoáng mát, bãi đỗ xe tiện lợi, mở cửa đến 23:00.',
        'images': badmintonImages,
        'rating': 4.1,
        'review_count': 24,
      },
      // ── 3 Bóng đá – TP.HCM ────────────────────────────────────────────
      {
        'name': 'Sân bóng đá Bình Thạnh',
        'type': 'football',
        'address': 'Đường Đinh Bộ Lĩnh, Bình Thạnh, TP.HCM',
        'lat': 10.8016,
        'lng': 106.7142,
        'price_per_hour': 500000.0,
        'peak_price_per_hour': 800000.0,
        'description':
            'Sân bóng đá 7 người, cỏ nhân tạo thế hệ 3, hệ thống đèn LED chiếu sáng ban đêm, thay đồ tiện nghi.',
        'images': footballImages,
        'rating': 4.5,
        'review_count': 48,
      },
      {
        'name': 'Sân bóng đá Gò Vấp',
        'type': 'football',
        'address': 'Đường Lê Đức Thọ, Gò Vấp, TP.HCM',
        'lat': 10.8380,
        'lng': 106.6647,
        'price_per_hour': 450000.0,
        'peak_price_per_hour': 750000.0,
        'description':
            'Sân 7 người và sân 5 người, cỏ nhân tạo, có lưới bảo vệ an toàn, khán đài cho cổ động viên.',
        'images': footballImages,
        'rating': 4.3,
        'review_count': 31,
      },
      {
        'name': 'Sân bóng đá Quận 7',
        'type': 'football',
        'address': 'Đường Nguyễn Thị Thập, Quận 7, TP.HCM',
        'lat': 10.7291,
        'lng': 106.7175,
        'price_per_hour': 550000.0,
        'peak_price_per_hour': 850000.0,
        'description':
            'Khu thể thao cao cấp Phú Mỹ Hưng, 3 sân 7 người, cỏ tự nhiên chất lượng cao, hồ bơi và spa.',
        'images': footballImages,
        'rating': 4.8,
        'review_count': 73,
      },
      // ── 3 Tennis – TP.HCM ─────────────────────────────────────────────
      {
        'name': 'Sân Tennis Quận 1',
        'type': 'tennis',
        'address': 'Đường Đinh Tiên Hoàng, Quận 1, TP.HCM',
        'lat': 10.7769,
        'lng': 106.7009,
        'price_per_hour': 120000.0,
        'peak_price_per_hour': 220000.0,
        'description':
            'Sân tennis trung tâm thành phố, mặt sân hard court tiêu chuẩn quốc tế, dịch vụ huấn luyện viên.',
        'images': tennisImages,
        'rating': 4.6,
        'review_count': 39,
      },
      {
        'name': 'Tennis Club Quận 3',
        'type': 'tennis',
        'address': 'Đường Võ Văn Tần, Quận 3, TP.HCM',
        'lat': 10.7769,
        'lng': 106.6831,
        'price_per_hour': 130000.0,
        'peak_price_per_hour': 230000.0,
        'description':
            'Câu lạc bộ tennis cao cấp, 6 sân clay và 4 sân hard, phòng gym, quán café đẳng cấp.',
        'images': tennisImages,
        'rating': 4.7,
        'review_count': 55,
      },
      {
        'name': 'Sân Tennis Phú Nhuận',
        'type': 'tennis',
        'address': 'Đường Hoàng Văn Thụ, Phú Nhuận, TP.HCM',
        'lat': 10.7998,
        'lng': 106.6836,
        'price_per_hour': 110000.0,
        'peak_price_per_hour': 200000.0,
        'description':
            'Sân tennis trong nhà có mái che, ánh sáng tốt, thích hợp chơi cả ngày lẫn đêm.',
        'images': tennisImages,
        'rating': 4.4,
        'review_count': 27,
      },
    ];
  }

  // ── Users ─────────────────────────────────────────────────────────────────

  /// Insert user mới, trả về id
  Future<int> insertUser(User user) async {
    int id = user.id > 0 ? user.id : (_localUsers.length + 1);
    try {
      id = await _nextId('nextUserId').timeout(const Duration(seconds: 2));
    } catch (_) {}
    final newUser = user.copyWith(id: id);
    _saveLocalUser(newUser);
    try {
      await _db
          .collection('users')
          .doc(id.toString())
          .set(newUser.toFirestore())
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('FirestoreService.insertUser stored locally: $e');
    }
    return id;
  }

  /// Lấy user theo email
  Future<User?> getUserByEmail(String email) async {
    final lower = email.trim().toLowerCase();
    try {
      final snap = await _db
          .collection('users')
          .where('email', isEqualTo: lower)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 2));
      if (snap.docs.isNotEmpty) {
        final u = User.fromFirestore(snap.docs.first.data());
        _saveLocalUser(u);
        return u;
      }
    } catch (e) {
      debugPrint('FirestoreService.getUserByEmail local fallback: $e');
    }
    return _localUsers
        .where((u) => u.email.toLowerCase() == lower)
        .firstOrNull;
  }

  /// Lấy user theo id
  Future<User?> getUserById(int id) async {
    try {
      final snap = await _db
          .collection('users')
          .where('id', isEqualTo: id)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 2));
      if (snap.docs.isNotEmpty) {
        final u = User.fromFirestore(snap.docs.first.data());
        _saveLocalUser(u);
        return u;
      }
    } catch (e) {
      debugPrint('FirestoreService.getUserById local fallback: $e');
    }
    return _localUsers.where((u) => u.id == id).firstOrNull;
  }

  /// Cập nhật thông tin user
  Future<void> updateUser(User user) async {
    try {
      final snap = await _db
          .collection('users')
          .where('id', isEqualTo: user.id)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;
      await snap.docs.first.reference.update({
        'name': user.name,
        'phone': user.phone,
        'avatar': user.avatar,
      });
    } catch (e) {
      debugPrint('FirestoreService.updateUser error: $e');
      rethrow;
    }
  }

  // ── Courts ────────────────────────────────────────────────────────────────

  /// Lấy tất cả sân, lazy-seeds on first call
  Future<List<Court>> getCourts() async {
    _initLocalCourts();
    try {
      await _initializeIfNeeded().timeout(const Duration(seconds: 3));
      final snap =
          await _db.collection('courts').get().timeout(const Duration(seconds: 3));
      if (snap.docs.isNotEmpty) {
        final courts =
            snap.docs.map((d) => Court.fromFirestore(d.data())).toList();
        courts.sort((a, b) => b.rating.compareTo(a.rating));
        _localCourts = courts;
        return courts;
      }
    } catch (e) {
      debugPrint('FirestoreService.getCourts local fallback: $e');
    }
    return List.from(_localCourts);
  }

  /// Lấy sân theo id
  Future<Court?> getCourtById(int id) async {
    _initLocalCourts();
    try {
      final snap = await _db
          .collection('courts')
          .where('id', isEqualTo: id)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 2));
      if (snap.docs.isNotEmpty) {
        return Court.fromFirestore(snap.docs.first.data());
      }
    } catch (e) {
      debugPrint('FirestoreService.getCourtById local fallback: $e');
    }
    return _localCourts.where((c) => c.id == id).firstOrNull;
  }

  /// Tìm kiếm sân theo từ khoá (client-side filter)
  Future<List<Court>> searchCourts(String query) async {
    final all = await getCourts();
    final lower = query.toLowerCase();
    final courts = all
        .where((c) =>
            c.name.toLowerCase().contains(lower) ||
            c.address.toLowerCase().contains(lower))
        .toList();
    courts.sort((a, b) => b.rating.compareTo(a.rating));
    return courts;
  }

  /// Lọc sân theo loại
  Future<List<Court>> getCourtsByType(String type) async {
    final all = await getCourts();
    if (type == 'all') return all;
    final courts = all.where((c) => c.type == type).toList();
    courts.sort((a, b) => b.rating.compareTo(a.rating));
    return courts;
  }

  /// Lấy danh sách sân của một Owner
  Future<List<Court>> getCourtsByOwner(int ownerId) async {
    final all = await getCourts();
    final courts = all
        .where((c) => c.ownerId == ownerId || (ownerId == 2 && c.ownerId == null))
        .toList();
    courts.sort((a, b) => b.rating.compareTo(a.rating));
    return courts;
  }

  /// Thêm sân mới (Owner)
  Future<int> insertCourt(Court court) async {
    _initLocalCourts();
    int id = _localCourts.length + 1;
    try {
      id = await _nextId('nextCourtId').timeout(const Duration(seconds: 2));
    } catch (_) {}

    final newCourt = court.copyWith(id: id);
    _localCourts.insert(0, newCourt);

    try {
      await _db
          .collection('courts')
          .doc(id.toString())
          .set(newCourt.toFirestore())
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('FirestoreService.insertCourt saved locally: $e');
    }

    return id;
  }

  /// Cập nhật thông tin sân (Owner)
  Future<void> updateCourt(Court court) async {
    _initLocalCourts();
    final idx = _localCourts.indexWhere((c) => c.id == court.id);
    if (idx != -1) {
      _localCourts[idx] = court;
    }
    try {
      await _db
          .collection('courts')
          .doc(court.id.toString())
          .set(court.toFirestore(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('FirestoreService.updateCourt updated locally: $e');
    }
  }

  /// Xóa sân (Owner)
  Future<void> deleteCourt(int courtId) async {
    _initLocalCourts();
    _localCourts.removeWhere((c) => c.id == courtId);
    try {
      await _db
          .collection('courts')
          .doc(courtId.toString())
          .delete()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('FirestoreService.deleteCourt deleted locally: $e');
    }
  }

  // ── Time Slots ────────────────────────────────────────────────────────────

  /// Lấy time slots của sân theo ngày, sorted by startTime ASC
  Future<List<TimeSlot>> getTimeSlots(int courtId, String date) async {
    try {
      final snap = await _db
          .collection('time_slots')
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .get();
      final slots =
          snap.docs.map((d) => TimeSlot.fromFirestore(d.data())).toList();
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      return slots;
    } catch (e) {
      debugPrint('FirestoreService.getTimeSlots error: $e');
      rethrow;
    }
  }

  /// Bulk update nhiều slot cùng lúc
  Future<void> bulkUpdateTimeSlots({
    required int courtId,
    required String date,
    required List<String> startTimes,
    required bool available,
  }) async {
    try {
      final snap = await _db
          .collection('time_slots')
          .where('courtId', isEqualTo: courtId)
          .where('date', isEqualTo: date)
          .get();
      final toUpdate = snap.docs
          .where((d) => startTimes.contains(d.data()['startTime']))
          .toList();
      final batch = _db.batch();
      for (final doc in toUpdate) {
        batch.update(doc.reference, {'isAvailable': available});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService.bulkUpdateTimeSlots error: $e');
      rethrow;
    }
  }

  // ── Bookings ──────────────────────────────────────────────────────────────

  /// Insert booking mới, denormalizes courtName/courtType, trả về id
  Future<int> insertBooking(Booking booking) async {
    try {
      final id = await _nextId('nextBookingId');
      final court = await getCourtById(booking.courtId);
      final newBooking = booking.copyWith(
        id: id,
        courtName: court?.name,
        courtType: court?.type,
      );
      await _db
          .collection('bookings')
          .doc(id.toString())
          .set(newBooking.toFirestore());
      return id;
    } catch (e) {
      debugPrint('FirestoreService.insertBooking error: $e');
      rethrow;
    }
  }

  /// Lấy tất cả booking của user, sorted by createdAt DESC
  Future<List<Booking>> getUserBookings(int userId) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
      final bookings =
          snap.docs.map((d) => Booking.fromFirestore(d.data())).toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    } catch (e) {
      debugPrint('FirestoreService.getUserBookings error: $e');
      rethrow;
    }
  }

  /// Cập nhật status của booking
  Future<void> updateBookingStatus(int bookingId, String status) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('id', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;
      await snap.docs.first.reference.update({'status': status});
    } catch (e) {
      debugPrint('FirestoreService.updateBookingStatus error: $e');
      rethrow;
    }
  }

  /// Cập nhật trạng thái và hoàn tiền khi huỷ booking
  Future<void> updateBookingRefund({
    required int bookingId,
    required String status,
    required double refundAmount,
    required String refundStatus,
    required String refundReason,
  }) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('id', isEqualTo: bookingId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;
      await snap.docs.first.reference.update({
        'status': status,
        'refundAmount': refundAmount,
        'refundStatus': refundStatus,
        'refundReason': refundReason,
      });
    } catch (e) {
      debugPrint('FirestoreService.updateBookingRefund error: $e');
      rethrow;
    }
  }

  /// Lấy tất cả đặt sân thuộc danh sách courtIds (Owner)
  Future<List<Booking>> getBookingsByCourtIds(List<int> courtIds) async {
    try {
      if (courtIds.isEmpty) return [];
      final snap = await _db.collection('bookings').get();
      final bookings = snap.docs
          .map((d) => Booking.fromFirestore(d.data()))
          .where((b) => courtIds.contains(b.courtId))
          .toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    } catch (e) {
      debugPrint('FirestoreService.getBookingsByCourtIds error: $e');
      rethrow;
    }
  }

  /// Lấy tất cả bookings trên hệ thống (Admin)
  Future<List<Booking>> getAllBookings() async {
    try {
      final snap = await _db.collection('bookings').get();
      final bookings = snap.docs
          .map((d) => Booking.fromFirestore(d.data()))
          .toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    } catch (e) {
      debugPrint('FirestoreService.getAllBookings error: $e');
      rethrow;
    }
  }

  /// Lấy tất cả users trên hệ thống (Admin)
  Future<List<User>> getAllUsers() async {
    try {
      await _initializeIfNeeded();
      final snap = await _db.collection('users').get();
      return snap.docs.map((d) => User.fromFirestore(d.data())).toList();
    } catch (e) {
      debugPrint('FirestoreService.getAllUsers error: $e');
      rethrow;
    }
  }

  // ── Reviews ───────────────────────────────────────────────────────────────

  /// Insert review mới, stores bookingId directly in Firestore map
  Future<int> insertReview({
    required int courtId,
    required int userId,
    int? bookingId,
    required double rating,
    String? comment,
  }) async {
    try {
      final id = await _nextId('nextReviewId');
      final user = await getUserById(userId);
      final map = <String, dynamic>{
        'id': id,
        'courtId': courtId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
        'createdAt': DateTime.now().toIso8601String(),
        'userName': user?.name,
        'bookingId': ?bookingId,
      };
      await _db.collection('reviews').doc(id.toString()).set(map);
      await updateCourtRating(courtId);
      return id;
    } catch (e) {
      debugPrint('FirestoreService.insertReview error: $e');
      rethrow;
    }
  }

  /// Lấy reviews của sân; returns snake_case maps compatible with Review.fromMap
  Future<List<Map<String, dynamic>>> getReviewsByCourt(int courtId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('courtId', isEqualTo: courtId)
          .get();
      final maps = snap.docs.map((d) {
        final data = d.data();
        return <String, dynamic>{
          'id': data['id'],
          'court_id': data['courtId'],
          'user_id': data['userId'],
          'rating': data['rating'],
          'comment': data['comment'],
          'created_at': data['createdAt'],
          'user_name': data['userName'],
        };
      }).toList();
      maps.sort((a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String));
      return maps;
    } catch (e) {
      debugPrint('FirestoreService.getReviewsByCourt error: $e');
      rethrow;
    }
  }

  /// Kiểm tra user đã review booking chưa
  Future<bool> hasReviewed(int bookingId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('bookingId', isEqualTo: bookingId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FirestoreService.hasReviewed error: $e');
      rethrow;
    }
  }

  /// Cập nhật rating sân sau khi có review mới
  Future<void> updateCourtRating(int courtId) async {
    try {
      final snap = await _db
          .collection('reviews')
          .where('courtId', isEqualTo: courtId)
          .get();
      final ratings = snap.docs
          .map((d) => (d.data()['rating'] as num).toDouble())
          .toList();
      final avg = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;
      final courtSnap = await _db
          .collection('courts')
          .where('id', isEqualTo: courtId)
          .limit(1)
          .get();
      if (courtSnap.docs.isNotEmpty) {
        await courtSnap.docs.first.reference.update({
          'rating': avg,
          'reviewCount': ratings.length,
        });
      }
    } catch (e) {
      debugPrint('FirestoreService.updateCourtRating error: $e');
      rethrow;
    }
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Insert tin nhắn mới
  Future<int> insertMessage(Message message) async {
    try {
      final id = await _nextId('nextMessageId');
      final newMessage = message.copyWith(id: id);
      await _db
          .collection('messages')
          .doc(id.toString())
          .set(newMessage.toFirestore());
      return id;
    } catch (e) {
      debugPrint('FirestoreService.insertMessage error: $e');
      rethrow;
    }
  }

  /// Lấy messages của sân + user, sorted by timestamp ASC
  Future<List<Message>> getMessagesByCourtAndUser(
      int courtId, int userId) async {
    try {
      final snap = await _db
          .collection('messages')
          .where('courtId', isEqualTo: courtId)
          .where('userId', isEqualTo: userId)
          .get();
      final messages =
          snap.docs.map((d) => Message.fromFirestore(d.data())).toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    } catch (e) {
      debugPrint('FirestoreService.getMessagesByCourtAndUser error: $e');
      rethrow;
    }
  }

  /// Lấy các sân user đã chat.
  /// Returns snake_case maps compatible with Court.fromMap, plus last_message/last_timestamp.
  /// 'images' is jsonEncoded string (Court.fromMap calls jsonDecode on it).
  Future<List<Map<String, dynamic>>> getChattedCourts(int userId) async {
    try {
      // Fetch all messages for userId
      final msgSnap = await _db
          .collection('messages')
          .where('userId', isEqualTo: userId)
          .get();

      // Group by courtId, keeping the latest text + timestamp per court
      final Map<int, Map<String, String>> latestByCourtId = {};
      for (final doc in msgSnap.docs) {
        final data = doc.data();
        final courtId = data['courtId'] as int;
        final ts = data['timestamp'] as String;
        if (!latestByCourtId.containsKey(courtId) ||
            ts.compareTo(latestByCourtId[courtId]!['ts']!) > 0) {
          latestByCourtId[courtId] = {
            'text': data['text'] as String,
            'ts': ts,
          };
        }
      }

      // For each courtId fetch court document and build snake_case map
      final result = <Map<String, dynamic>>[];
      for (final entry in latestByCourtId.entries) {
        final court = await getCourtById(entry.key);
        if (court == null) continue;
        result.add({
          'id': court.id,
          'name': court.name,
          'type': court.type,
          'address': court.address,
          'lat': court.lat,
          'lng': court.lng,
          'price_per_hour': court.pricePerHour,
          'peak_price_per_hour': court.peakPricePerHour,
          'description': court.description,
          'images': jsonEncode(court.images),
          'rating': court.rating,
          'review_count': court.reviewCount,
          'last_message': entry.value['text'],
          'last_timestamp': entry.value['ts'],
        });
      }

      result.sort((a, b) => (b['last_timestamp'] as String)
          .compareTo(a['last_timestamp'] as String));
      return result;
    } catch (e) {
      debugPrint('FirestoreService.getChattedCourts error: $e');
      rethrow;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  /// Insert thông báo mới
  Future<int> insertNotification(AppNotification notif) async {
    try {
      final id = await _nextId('nextNotificationId');
      final newNotif = notif.copyWith(id: id);
      await _db
          .collection('notifications')
          .doc(id.toString())
          .set(newNotif.toFirestore());
      return id;
    } catch (e) {
      debugPrint('FirestoreService.insertNotification error: $e');
      rethrow;
    }
  }

  /// Lấy thông báo của user, sorted by createdAt DESC
  Future<List<AppNotification>> getNotificationsByUser(int userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      final notifs = snap.docs
          .map((d) => AppNotification.fromFirestore(d.data()))
          .toList();
      notifs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifs;
    } catch (e) {
      debugPrint('FirestoreService.getNotificationsByUser error: $e');
      rethrow;
    }
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markNotificationRead(int notifId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('id', isEqualTo: notifId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return;
      await snap.docs.first.reference.update({'isRead': true});
    } catch (e) {
      debugPrint('FirestoreService.markNotificationRead error: $e');
      rethrow;
    }
  }

  /// Đánh dấu tất cả thông báo của user đã đọc
  Future<void> markAllNotificationsRead(int userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirestoreService.markAllNotificationsRead error: $e');
      rethrow;
    }
  }

  /// Lấy số thông báo chưa đọc
  Future<int> getUnreadCount(int userId) async {
    try {
      final snap = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snap.docs.length;
    } catch (e) {
      debugPrint('FirestoreService.getUnreadCount error: $e');
      rethrow;
    }
  }
}
