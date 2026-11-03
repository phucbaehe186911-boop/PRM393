import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/time_slot.dart';
import '../services/firestore_service.dart';

/// ViewModel cho quy trình đặt sân (cart, checkout, lịch sử, huỷ)
class BookingViewModel extends ChangeNotifier {
  final FirestoreService _db;

  // Cache time slots theo ngày
  Map<String, List<TimeSlot>> _timeSlotsByDate = {};
  String _selectedDate = '';
  List<TimeSlot> _selectedSlots = [];
  bool _isLoadingSlots = false;

  // Add-ons: racket=vợt, ball=bóng, water=nước
  Map<String, bool> _selectedAddons = {
    'racket': false,
    'ball': false,
    'water': false,
  };

  // Giá add-ons (VNĐ)
  static const Map<String, double> addonPrices = {
    'racket': 30000,
    'ball': 50000,
    'water': 20000,
  };

  // My bookings
  List<Booking> _userBookings = [];
  bool _isLoadingBookings = false;
  final Set<int> _reviewedBookingIds = {};

  // Owner bookings & revenue
  List<Booking> _ownerBookings = [];
  bool _isLoadingOwnerBookings = false;

  BookingViewModel(this._db);

  String get selectedDate => _selectedDate;
  List<TimeSlot> get selectedSlots => List.unmodifiable(_selectedSlots);
  bool get isLoadingSlots => _isLoadingSlots;
  Map<String, bool> get selectedAddons => Map.unmodifiable(_selectedAddons);
  List<Booking> get userBookings => _userBookings;
  bool get isLoadingBookings => _isLoadingBookings;

  List<Booking> get ownerBookings => _ownerBookings;
  bool get isLoadingOwnerBookings => _isLoadingOwnerBookings;

  /// Doanh thu thực nhận của Owner: Tổng cọc (50% tổng đơn) của các đơn confirmed trừ các đơn đã hoàn tiền
  double get ownerTotalRevenue {
    double revenue = 0.0;
    for (final b in _ownerBookings) {
      if (b.status == 'confirmed') {
        revenue += (b.totalPrice * 0.5);
      } else if (b.status == 'cancelled' && b.refundStatus == 'non_refundable') {
        // Khách huỷ muộn không được hoàn tiền -> Owner vẫn được hưởng khoản cọc này
        revenue += (b.totalPrice * 0.5);
      }
    }
    return revenue;
  }

  /// Tổng tiền đã hoàn trả cho khách (huỷ trước thời hạn)
  double get ownerTotalRefunded {
    double refunded = 0.0;
    for (final b in _ownerBookings) {
      if (b.refundStatus == 'refunded') {
        refunded += b.refundAmount;
      }
    }
    return refunded;
  }

  int get ownerConfirmedCount =>
      _ownerBookings.where((b) => b.status == 'confirmed').length;

  int get ownerCancelledCount =>
      _ownerBookings.where((b) => b.status == 'cancelled').length;

  List<TimeSlot> get timeSlotsForDate =>
      _timeSlotsByDate[_selectedDate] ?? [];

  // ─── Tính tổng tiền ────────────────────────────────────────────────────────

  /// Tổng tiền slot đã chọn + add-ons
  double get totalPrice {
    double total = _selectedSlots.fold(0, (sum, slot) {
      return sum + (slot.isPeak ? _peakPrice(slot) : _offPeakPrice(slot));
    });
    addonPrices.forEach((key, price) {
      if (_selectedAddons[key] == true) total += price;
    });
    return total;
  }

  /// Tiền cọc 50%
  double get depositAmount => totalPrice * 0.5;

  // ─── Time Slots ────────────────────────────────────────────────────────────

  /// Tải time slots của sân theo ngày
  Future<void> loadTimeSlots(int courtId, String date) async {
    _selectedDate = date;
    if (_timeSlotsByDate.containsKey(date)) {
      notifyListeners();
      return;
    }

    _isLoadingSlots = true;
    notifyListeners();

    try {
      final slots = await _db.getTimeSlots(courtId, date);
      _timeSlotsByDate[date] = slots;
    } catch (e) {
      debugPrint('BookingViewModel.loadTimeSlots error: $e');
    } finally {
      _isLoadingSlots = false;
      notifyListeners();
    }
  }

  /// Thay đổi ngày đang xem
  void selectDate(String date) {
    _selectedDate = date;
    notifyListeners();
  }

  // ─── Slot selection ────────────────────────────────────────────────────────

  /// Chọn/bỏ chọn một slot
  void toggleSlotSelection(TimeSlot slot) {
    if (!slot.isAvailable) return;
    final index = _selectedSlots.indexWhere((s) => s.id == slot.id);
    if (index == -1) {
      _selectedSlots.add(slot);
    } else {
      _selectedSlots.removeAt(index);
    }
    notifyListeners();
  }

  bool isSlotSelected(TimeSlot slot) =>
      _selectedSlots.any((s) => s.id == slot.id);

  // ─── Add-ons ───────────────────────────────────────────────────────────────

  void toggleAddon(String key) {
    if (_selectedAddons.containsKey(key)) {
      _selectedAddons[key] = !(_selectedAddons[key] ?? false);
      notifyListeners();
    }
  }

  // ─── Clear ─────────────────────────────────────────────────────────────────

  /// Reset toàn bộ selection (sau checkout hoặc navigate away)
  void clearSelection() {
    _selectedSlots = [];
    _selectedAddons = {'racket': false, 'ball': false, 'water': false};
    notifyListeners();
  }

  /// Reset cache time slots (khi cần refresh)
  void clearSlotCache() {
    _timeSlotsByDate = {};
    notifyListeners();
  }

  // ─── Confirm Booking ───────────────────────────────────────────────────────

  /// Xác nhận đặt sân – insert booking, update time slots, trả về booking id
  Future<int> confirmBooking({
    required int userId,
    required int courtId,
  }) async {
    if (_selectedSlots.isEmpty) throw Exception('Chưa chọn slot');

    // Sắp xếp slots theo giờ
    final sorted = List<TimeSlot>.from(_selectedSlots)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final booking = Booking(
      id: 0,
      courtId: courtId,
      userId: userId,
      date: sorted.first.date,
      startTime: sorted.first.startTime,
      endTime: sorted.last.endTime,
      totalPrice: totalPrice,
      status: 'confirmed',
      addons: Map<String, bool>.from(_selectedAddons),
      createdAt: DateTime.now().toIso8601String(),
    );

    final bookingId = await _db.insertBooking(booking);

    // Update time slots → not available
    await _db.bulkUpdateTimeSlots(
      courtId: courtId,
      date: sorted.first.date,
      startTimes: sorted.map((s) => s.startTime).toList(),
      available: false,
    );

    // Xoá cache ngày đó để force reload
    _timeSlotsByDate.remove(sorted.first.date);

    clearSelection();
    return bookingId;
  }

  // ─── My Bookings ───────────────────────────────────────────────────────────

  /// Tải lịch sử đặt sân của user
  Future<void> loadUserBookings(int userId) async {
    _isLoadingBookings = true;
    notifyListeners();
    try {
      _userBookings = await _db.getUserBookings(userId);
      // Load trạng thái đã review từ DB cho từng booking
      for (final b in _userBookings) {
        if (b.status == 'confirmed') {
          final reviewed = await _db.hasReviewed(b.id);
          if (reviewed) _reviewedBookingIds.add(b.id);
        }
      }
    } catch (e) {
      debugPrint('BookingViewModel.loadUserBookings error: $e');
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  /// Huỷ booking với cơ chế hoàn tiền trước thời hạn
  Future<Booking> cancelBooking(Booking booking) async {
    // Tính toán thời gian chênh lệch để xét hoàn tiền
    double refundAmount = 0.0;
    String refundStatus = 'non_refundable';
    String refundReason = '';

    try {
      final dateParts = booking.date.split('-');
      final timeParts = booking.startTime.split(':');
      final matchDateTime = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final now = DateTime.now();
      final diff = matchDateTime.difference(now);

      // Quy định: Hủy trước giờ chơi >= 6 tiếng -> Hoàn 100% tiền cọc (50% tổng đơn)
      if (diff.inHours >= 6) {
        refundAmount = booking.totalPrice * 0.5;
        refundStatus = 'refunded';
        refundReason =
            'Huỷ trước ${diff.inHours} giờ (quy định >= 6h): Hoàn 100% tiền cọc (${(booking.totalPrice * 0.5).toInt()}đ)';
      } else if (diff.inMinutes > 0) {
        refundAmount = 0.0;
        refundStatus = 'non_refundable';
        refundReason =
            'Huỷ sát giờ (${diff.inHours}h ${diff.inMinutes % 60}m < 6h): Không hoàn lại tiền cọc';
      } else {
        refundAmount = 0.0;
        refundStatus = 'non_refundable';
        refundReason = 'Đã quá giờ thi đấu: Không hoàn cọc';
      }
    } catch (e) {
      debugPrint('Error calculating refund: $e');
    }

    await _db.updateBookingRefund(
      bookingId: booking.id,
      status: 'cancelled',
      refundAmount: refundAmount,
      refundStatus: refundStatus,
      refundReason: refundReason,
    );

    // Tính các start times từ startTime → endTime (mỗi block 1h)
    final startTimes = _expandTimeRange(booking.startTime, booking.endTime);
    await _db.bulkUpdateTimeSlots(
      courtId: booking.courtId,
      date: booking.date,
      startTimes: startTimes,
      available: true,
    );

    final updated = booking.copyWith(
      status: 'cancelled',
      refundAmount: refundAmount,
      refundStatus: refundStatus,
      refundReason: refundReason,
    );

    // Cập nhật local list
    final index = _userBookings.indexWhere((b) => b.id == booking.id);
    if (index != -1) {
      _userBookings[index] = updated;
    }

    final ownerIndex = _ownerBookings.indexWhere((b) => b.id == booking.id);
    if (ownerIndex != -1) {
      _ownerBookings[ownerIndex] = updated;
    }

    notifyListeners();
    return updated;
  }

  /// Tải danh sách đơn đặt sân cho các sân do Owner quản lý
  Future<void> loadOwnerBookings(List<int> courtIds) async {
    _isLoadingOwnerBookings = true;
    notifyListeners();
    try {
      _ownerBookings = await _db.getBookingsByCourtIds(courtIds);
    } catch (e) {
      debugPrint('BookingViewModel.loadOwnerBookings error: $e');
    } finally {
      _isLoadingOwnerBookings = false;
      notifyListeners();
    }
  }

  // ─── Reviews ───────────────────────────────────────────────────────────────

  /// Kiểm tra booking đã được đánh giá chưa (từ cache, không cần async)
  bool isReviewed(int bookingId) => _reviewedBookingIds.contains(bookingId);

  /// Gửi đánh giá sân
  Future<void> submitReview({
    required int courtId,
    required int userId,
    required int? bookingId,
    required double rating,
    String? comment,
  }) async {
    await _db.insertReview(
      courtId: courtId,
      userId: userId,
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
    // Cập nhật cache ngay lập tức
    if (bookingId != null) {
      _reviewedBookingIds.add(bookingId);
      notifyListeners();
    }
  }

  /// Kiểm tra booking đã được đánh giá chưa (query DB trực tiếp)
  Future<bool> hasReviewed(int bookingId) async {
    return await _db.hasReviewed(bookingId);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Expand time range thành danh sách start times (1h block)
  List<String> _expandTimeRange(String startTime, String endTime) {
    final List<String> times = [];
    int startH = int.parse(startTime.split(':')[0]);
    int endH = int.parse(endTime.split(':')[0]);
    for (int h = startH; h < endH; h++) {
      times.add('${h.toString().padLeft(2, '0')}:00');
    }
    return times;
  }

  double _peakPrice(TimeSlot slot) {
    // Peak price không được lưu trong TimeSlot, cần lấy từ court
    // Tạm dùng multiplier 2.25x so với off-peak
    return _offPeakPrice(slot) * 2.25;
  }

  double _offPeakPrice(TimeSlot slot) {
    // Giá mặc định – sẽ được override từ CourtDetailPage với giá thực tế
    return 100000;
  }

  /// Tính giá đúng dựa vào pricePerHour của sân
  double calculateSlotPrice(TimeSlot slot, double offPeak, double peakPrice) {
    return slot.isPeak ? peakPrice : offPeak;
  }

  /// Tổng tiền với giá sân cụ thể
  double totalPriceWithCourtPrices(double offPeak, double peak) {
    double total = _selectedSlots.fold(0, (sum, slot) {
      return sum + (slot.isPeak ? peak : offPeak);
    });
    addonPrices.forEach((key, price) {
      if (_selectedAddons[key] == true) total += price;
    });
    return total;
  }
}
