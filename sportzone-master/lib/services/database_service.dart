import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/court.dart';
import '../models/time_slot.dart';
import '../models/booking.dart';
import '../models/message.dart';
import '../models/app_notification.dart';

/// Singleton service quản lý toàn bộ SQLite CRUD cho SportZone
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  /// Khởi tạo database – tạo bảng và seed nếu lần đầu
  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'sportzone.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onOpen: (db) async => await _seedIfEmpty(db),
    );
  }

  Database get db => _db!;

  // ─── MIGRATIONS ──────────────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v2: thêm booking_id vào notifications
      await db.execute(
          'ALTER TABLE notifications ADD COLUMN booking_id INTEGER');
    }
  }

  // ─── CREATE TABLES ────────────────────────────────────────────────────────

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT    NOT NULL,
        email      TEXT    NOT NULL UNIQUE,
        password   TEXT    NOT NULL,
        phone      TEXT,
        avatar     TEXT,
        created_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE courts (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        name                TEXT    NOT NULL,
        type                TEXT    NOT NULL,
        address             TEXT    NOT NULL,
        lat                 REAL    NOT NULL,
        lng                 REAL    NOT NULL,
        price_per_hour      REAL    NOT NULL,
        peak_price_per_hour REAL    NOT NULL,
        description         TEXT,
        images              TEXT,
        rating              REAL    DEFAULT 0.0,
        review_count        INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE time_slots (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        court_id     INTEGER NOT NULL,
        date         TEXT    NOT NULL,
        start_time   TEXT    NOT NULL,
        end_time     TEXT    NOT NULL,
        is_available INTEGER DEFAULT 1,
        FOREIGN KEY (court_id) REFERENCES courts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE bookings (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        court_id    INTEGER NOT NULL,
        user_id     INTEGER NOT NULL,
        date        TEXT    NOT NULL,
        start_time  TEXT    NOT NULL,
        end_time    TEXT    NOT NULL,
        total_price REAL    NOT NULL,
        status      TEXT    DEFAULT 'confirmed',
        addons      TEXT,
        created_at  TEXT    NOT NULL,
        FOREIGN KEY (court_id) REFERENCES courts(id),
        FOREIGN KEY (user_id)  REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        court_id   INTEGER NOT NULL,
        user_id    INTEGER NOT NULL,
        booking_id INTEGER,
        rating     REAL    NOT NULL,
        comment    TEXT,
        created_at TEXT    NOT NULL,
        FOREIGN KEY (court_id) REFERENCES courts(id),
        FOREIGN KEY (user_id)  REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        court_id     INTEGER NOT NULL,
        user_id      INTEGER NOT NULL,
        is_from_user INTEGER DEFAULT 1,
        text         TEXT    NOT NULL,
        timestamp    TEXT    NOT NULL,
        FOREIGN KEY (court_id) REFERENCES courts(id),
        FOREIGN KEY (user_id)  REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id    INTEGER NOT NULL,
        title      TEXT    NOT NULL,
        body       TEXT    NOT NULL,
        type       TEXT    NOT NULL,
        is_read    INTEGER DEFAULT 0,
        created_at TEXT    NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Seed ngay sau khi tạo bảng
    await _seedIfEmpty(db);
  }

  // ─── SEED DATA ─────────────────────────────────────────────────────────────

  Future<void> _seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM courts'),
    );
    if (count != null && count > 0) return; // Đã có data

    final rng = Random(42); // seed cố định để kết quả nhất quán
    final batch = db.batch();

    // 15 sân mẫu
    final courts = _getSeedCourts();
    for (final c in courts) {
      batch.insert('courts', c);
    }
    await batch.commit(noResult: true);

    // Lấy lại IDs vừa insert
    final courtRows = await db.query('courts', columns: ['id']);
    final courtIds = courtRows.map((r) => r['id'] as int).toList();

    // Tạo time_slots cho mỗi sân × 7 ngày × 18 slot/ngày (05:00–22:00)
    final now = DateTime.now();
    final slotBatch = db.batch();
    for (final courtId in courtIds) {
      for (int d = 0; d < 7; d++) {
        final date = now.add(Duration(days: d));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        for (int h = 5; h < 23; h++) {
          final startTime =
              '${h.toString().padLeft(2, '0')}:00';
          final endTime =
              '${(h + 1).toString().padLeft(2, '0')}:00';
          // ~30% slot ngẫu nhiên không available để demo
          final isAvailable = rng.nextDouble() > 0.30 ? 1 : 0;
          slotBatch.insert('time_slots', {
            'court_id': courtId,
            'date': dateStr,
            'start_time': startTime,
            'end_time': endTime,
            'is_available': isAvailable,
          });
        }
      }
    }
    await slotBatch.commit(noResult: true);
  }

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

  // ─── USERS ─────────────────────────────────────────────────────────────────

  /// Insert user mới, trả về id
  Future<int> insertUser(User user) async {
    return await db.insert('users', user.toMap());
  }

  /// Lấy user theo email
  Future<User?> getUserByEmail(String email) async {
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Lấy user theo id
  Future<User?> getUserById(int id) async {
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  /// Cập nhật thông tin user
  Future<void> updateUser(User user) async {
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ─── COURTS ────────────────────────────────────────────────────────────────

  /// Lấy tất cả sân (optionally filtered by type)
  Future<List<Court>> getCourts() async {
    final maps = await db.query('courts', orderBy: 'rating DESC');
    return maps.map((m) => Court.fromMap(m)).toList();
  }

  /// Lọc sân theo loại
  Future<List<Court>> getCourtsByType(String type) async {
    if (type == 'all') return getCourts();
    final maps = await db.query(
      'courts',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'rating DESC',
    );
    return maps.map((m) => Court.fromMap(m)).toList();
  }

  /// Tìm kiếm sân theo từ khoá
  Future<List<Court>> searchCourts(String query) async {
    final maps = await db.rawQuery(
      'SELECT * FROM courts WHERE name LIKE ? OR address LIKE ? ORDER BY rating DESC',
      ['%$query%', '%$query%'],
    );
    return maps.map((m) => Court.fromMap(m)).toList();
  }

  /// Lấy sân theo id
  Future<Court?> getCourtById(int id) async {
    final maps = await db.query(
      'courts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Court.fromMap(maps.first);
  }

  /// Lấy danh sách sân của Owner
  Future<List<Court>> getCourtsByOwner(int ownerId) async {
    final maps = await db.query(
      'courts',
      where: 'owner_id = ? OR owner_id IS NULL',
      whereArgs: [ownerId],
      orderBy: 'rating DESC',
    );
    return maps.map((m) => Court.fromMap(m)).toList();
  }

  /// Thêm sân mới (Owner)
  Future<int> insertCourt(Court court) async {
    final id = await db.insert('courts', court.toMap());
    // Tạo time slots 7 ngày
    final now = DateTime.now();
    final batch = db.batch();
    for (int d = 0; d < 7; d++) {
      final date = now.add(Duration(days: d));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      for (int h = 5; h < 23; h++) {
        final startTime = '${h.toString().padLeft(2, '0')}:00';
        final endTime = '${(h + 1).toString().padLeft(2, '0')}:00';
        batch.insert('time_slots', {
          'court_id': id,
          'date': dateStr,
          'start_time': startTime,
          'end_time': endTime,
          'is_available': 1,
        });
      }
    }
    await batch.commit(noResult: true);
    return id;
  }

  /// Cập nhật thông tin sân (Owner)
  Future<void> updateCourt(Court court) async {
    await db.update(
      'courts',
      court.toMap(),
      where: 'id = ?',
      whereArgs: [court.id],
    );
  }

  /// Xóa sân (Owner)
  Future<void> deleteCourt(int courtId) async {
    await db.delete('courts', where: 'id = ?', whereArgs: [courtId]);
    await db.delete('time_slots', where: 'court_id = ?', whereArgs: [courtId]);
  }

  /// Cập nhật rating sân sau khi có review mới
  Future<void> updateCourtRating(int courtId) async {
    await db.rawUpdate('''
      UPDATE courts
      SET rating = (
        SELECT COALESCE(AVG(rating), 0) FROM reviews WHERE court_id = ?
      ),
      review_count = (
        SELECT COUNT(*) FROM reviews WHERE court_id = ?
      )
      WHERE id = ?
    ''', [courtId, courtId, courtId]);
  }

  // ─── TIME SLOTS ────────────────────────────────────────────────────────────

  /// Lấy time slots của sân theo ngày
  Future<List<TimeSlot>> getTimeSlots(int courtId, String date) async {
    final maps = await db.query(
      'time_slots',
      where: 'court_id = ? AND date = ?',
      whereArgs: [courtId, date],
      orderBy: 'start_time ASC',
    );
    return maps.map((m) => TimeSlot.fromMap(m)).toList();
  }

  /// Cập nhật is_available của một slot
  Future<void> updateTimeSlotAvailability(int slotId, bool available) async {
    await db.update(
      'time_slots',
      {'is_available': available ? 1 : 0},
      where: 'id = ?',
      whereArgs: [slotId],
    );
  }

  /// Bulk update nhiều slot cùng lúc (khi xác nhận/huỷ booking)
  Future<void> bulkUpdateTimeSlots({
    required int courtId,
    required String date,
    required List<String> startTimes,
    required bool available,
  }) async {
    final placeholders = startTimes.map((_) => '?').join(', ');
    await db.rawUpdate(
      '''UPDATE time_slots SET is_available = ?
         WHERE court_id = ? AND date = ? AND start_time IN ($placeholders)''',
      [available ? 1 : 0, courtId, date, ...startTimes],
    );
  }

  // ─── BOOKINGS ──────────────────────────────────────────────────────────────

  /// Insert booking mới, trả về id
  Future<int> insertBooking(Booking booking) async {
    return await db.insert('bookings', booking.toMap());
  }

  /// Lấy tất cả booking của user (JOIN với courts)
  Future<List<Booking>> getUserBookings(int userId) async {
    final maps = await db.rawQuery('''
      SELECT b.*, c.name as court_name, c.type as court_type
      FROM bookings b
      JOIN courts c ON b.court_id = c.id
      WHERE b.user_id = ?
      ORDER BY b.created_at DESC
    ''', [userId]);
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  /// Cập nhật status của booking
  Future<void> updateBookingStatus(int bookingId, String status) async {
    await db.update(
      'bookings',
      {'status': status},
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  /// Cập nhật thông tin hoàn tiền khi huỷ booking
  Future<void> updateBookingRefund({
    required int bookingId,
    required String status,
    required double refundAmount,
    required String refundStatus,
    required String refundReason,
  }) async {
    await db.update(
      'bookings',
      {
        'status': status,
        'refund_amount': refundAmount,
        'refund_status': refundStatus,
        'refund_reason': refundReason,
      },
      where: 'id = ?',
      whereArgs: [bookingId],
    );
  }

  /// Lấy tất cả đặt sân của các sân do Owner quản lý
  Future<List<Booking>> getBookingsByCourtIds(List<int> courtIds) async {
    if (courtIds.isEmpty) return [];
    final placeholders = courtIds.map((_) => '?').join(',');
    final maps = await db.rawQuery('''
      SELECT b.*, c.name as court_name, c.type as court_type
      FROM bookings b
      JOIN courts c ON b.court_id = c.id
      WHERE b.court_id IN ($placeholders)
      ORDER BY b.created_at DESC
    ''', courtIds);
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  /// Lấy tất cả lượt đặt sân trên hệ thống (Admin)
  Future<List<Booking>> getAllBookings() async {
    final maps = await db.rawQuery('''
      SELECT b.*, c.name as court_name, c.type as court_type
      FROM bookings b
      JOIN courts c ON b.court_id = c.id
      ORDER BY b.created_at DESC
    ''');
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  /// Lấy tất cả người dùng (Admin)
  Future<List<User>> getAllUsers() async {
    final maps = await db.query('users', orderBy: 'created_at DESC');
    return maps.map((m) => User.fromMap(m)).toList();
  }

  // ─── REVIEWS ───────────────────────────────────────────────────────────────

  /// Insert review mới
  Future<int> insertReview({
    required int courtId,
    required int userId,
    required int? bookingId,
    required double rating,
    String? comment,
  }) async {
    final id = await db.insert('reviews', {
      'court_id': courtId,
      'user_id': userId,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'created_at': DateTime.now().toIso8601String(),
    });
    await updateCourtRating(courtId);
    return id;
  }

  /// Lấy reviews của sân
  Future<List<Map<String, dynamic>>> getReviewsByCourt(int courtId) async {
    return await db.rawQuery('''
      SELECT r.*, u.name as user_name
      FROM reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.court_id = ?
      ORDER BY r.created_at DESC
    ''', [courtId]);
  }

  /// Kiểm tra user đã review booking chưa
  Future<bool> hasReviewed(int bookingId) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM reviews WHERE booking_id = ?',
        [bookingId],
      ),
    );
    return (count ?? 0) > 0;
  }

  // ─── MESSAGES ──────────────────────────────────────────────────────────────

  /// Insert tin nhắn mới
  Future<int> insertMessage(Message message) async {
    return await db.insert('messages', message.toMap());
  }

  /// Lấy messages của sân + user (sorted by time)
  Future<List<Message>> getMessagesByCourtAndUser(
      int courtId, int userId) async {
    final maps = await db.query(
      'messages',
      where: 'court_id = ? AND user_id = ?',
      whereArgs: [courtId, userId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => Message.fromMap(m)).toList();
  }

  /// Lấy các sân user đã chat (distinct court_id)
  Future<List<Map<String, dynamic>>> getChattedCourts(int userId) async {
    return await db.rawQuery('''
      SELECT c.*, m.text as last_message, m.timestamp as last_timestamp
      FROM courts c
      JOIN messages m ON c.id = m.court_id
      WHERE m.user_id = ?
        AND m.timestamp = (
          SELECT MAX(timestamp) FROM messages
          WHERE court_id = c.id AND user_id = ?
        )
      ORDER BY m.timestamp DESC
    ''', [userId, userId]);
  }

  // ─── NOTIFICATIONS ─────────────────────────────────────────────────────────

  /// Insert thông báo mới
  Future<int> insertNotification(AppNotification notification) async {
    return await db.insert('notifications', notification.toMap());
  }

  /// Lấy thông báo của user
  Future<List<AppNotification>> getNotificationsByUser(int userId) async {
    final maps = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => AppNotification.fromMap(m)).toList();
  }

  /// Đánh dấu thông báo đã đọc
  Future<void> markNotificationRead(int notifId) async {
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notifId],
    );
  }

  /// Đánh dấu tất cả thông báo của user đã đọc
  Future<void> markAllNotificationsRead(int userId) async {
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Lấy số thông báo chưa đọc
  Future<int> getUnreadCount(int userId) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM notifications WHERE user_id = ? AND is_read = 0',
        [userId],
      ),
    );
    return count ?? 0;
  }
}
