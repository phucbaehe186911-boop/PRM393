import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/booking.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../core/app_strings.dart';
import '../../widgets/star_rating.dart';

/// Màn hình chi tiết một lượt đặt sân
class BookingDetailPage extends StatefulWidget {
  final int bookingId;
  const BookingDetailPage({super.key, required this.bookingId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Booking? _booking;
  bool _loading = true;
  bool _hasReviewed = false;
  bool _checkedIn = false; // demo bypass: mở khóa review cho upcoming booking

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;
    final vm = context.read<BookingViewModel>();
    var booking =
        vm.userBookings.where((b) => b.id == widget.bookingId).firstOrNull;
    if (booking == null) {
      await vm.loadUserBookings(user.id);
      booking =
          vm.userBookings.where((b) => b.id == widget.bookingId).firstOrNull;
    }
    if (mounted) setState(() { _booking = booking; _loading = false; });
  }

  Future<void> _onCancel() async {
    final booking = _booking;
    if (booking == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Huỷ đặt sân',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(AppStrings.cancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Huỷ đặt'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final user = context.read<AuthViewModel>().currentUser;
    final bookingVm = context.read<BookingViewModel>();
    final notifVm = context.read<NotificationViewModel>();
    final updated = await bookingVm.cancelBooking(booking);
    if (user != null && mounted) {
      final refundNotice = updated.refundStatus == 'refunded'
          ? 'Tiền cọc ${NumberFormat('#,###', 'vi_VN').format(updated.refundAmount)}đ đã được hoàn lại thành công.'
          : 'Đơn huỷ sát giờ (< 6h), tiền cọc không được hoàn lại theo chính sách.';
      await notifVm.createNotification(
        userId: user.id,
        title: updated.refundStatus == 'refunded'
            ? 'Huỷ sân & Hoàn tiền thành công'
            : 'Huỷ đặt sân thành công',
        body: 'Bạn đã huỷ đặt sân ${booking.courtName ?? ''}. $refundNotice',
        type: 'cancel',
        bookingId: booking.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.refundStatus == 'refunded'
                  ? 'Đã huỷ sân và hoàn ${NumberFormat('#,###', 'vi_VN').format(updated.refundAmount)}đ tiền cọc!'
                  : 'Đã huỷ đặt sân (Không đủ điều kiện hoàn cọc do huỷ sát giờ).',
            ),
            backgroundColor: updated.refundStatus == 'refunded'
                ? AppColors.success
                : AppColors.warning,
          ),
        );
        setState(() => _booking = updated);
      }
    }
  }

  Future<void> _onReview() async {
    final booking = _booking;
    if (booking == null) return;
    double rating = 5;
    final commentCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text('Đánh giá ${booking.courtName ?? 'sân'}',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRating(
                rating: rating,
                size: 32,
                onChanged: (r) => setDialog(() => rating = r),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: AppStrings.reviewPlaceholder,
                  hintStyle: const TextStyle(
                      color: AppColors.textDisabled, fontSize: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bỏ qua'),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = context.read<AuthViewModel>().currentUser;
                if (user != null) {
                  await context.read<BookingViewModel>().submitReview(
                        courtId: booking.courtId,
                        userId: user.id,
                        bookingId: booking.id,
                        rating: rating,
                        comment: commentCtrl.text.trim().isEmpty
                            ? null
                            : commentCtrl.text.trim(),
                      );
                  // Reload courts để rating cập nhật trên danh sách
                  await context.read<CourtViewModel>().loadCourts();
                  setState(() => _hasReviewed = true);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text(AppStrings.submitReview),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        title: const Text(
          'Chi tiết đặt sân',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _booking == null
              ? const Center(child: Text('Không tìm thấy lịch đặt'))
              : _buildDetail(_booking!),
    );
  }

  Widget _buildDetail(Booking b) {
    final isUpcoming = b.status == 'confirmed' &&
        b.date.compareTo(_todayStr()) >= 0 &&
        !_checkedIn;
    final isCompleted = b.status == 'confirmed' &&
        (b.date.compareTo(_todayStr()) < 0 || _checkedIn);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tên sân + status ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.courtName ?? 'Sân ${b.courtId}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    _StatusBadge(status: b.status),
                  ],
                ),
                if (b.courtType != null) ...[
                  const SizedBox(height: 2),
                  Text(b.courtType!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: AppColors.border,
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.tag, 'Mã đặt sân', '#${b.id}'),
                const SizedBox(height: 6),
                _infoRow(Icons.calendar_today_outlined, 'Ngày',
                    _formatDate(b.date)),
                const SizedBox(height: 6),
                _infoRow(Icons.access_time_outlined, 'Giờ chơi',
                    '${b.startTime} – ${b.endTime}'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Thanh toán ────────────────────────────────────
          _sectionLabel('Thanh toán'),
          const SizedBox(height: 6),
          _card([
            _row('Tổng tiền', _formatPrice(b.totalPrice),
                valueStyle: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            if (b.addons.entries.any((e) => e.value)) ...[
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _row('Phụ kiện',
                  b.addons.entries
                      .where((e) => e.value)
                      .map((e) => _addonLabel(e.key))
                      .join(', ')),
            ],
          ]),

          const SizedBox(height: 12),

          // ── Thông tin đặt ─────────────────────────────────
          _sectionLabel('Thông tin đặt'),
          const SizedBox(height: 6),
          _card([
            _row('Thời gian đặt', _formatDateTime(b.createdAt)),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            _row('Trạng thái', _statusLabel(b.status)),
          ]),

          if (b.status == 'cancelled') ...[
            const SizedBox(height: 12),
            _sectionLabel('Thông tin hoàn tiền huỷ sân'),
            const SizedBox(height: 6),
            _card([
              _row(
                'Số tiền hoàn',
                b.refundAmount > 0
                    ? _formatPrice(b.refundAmount)
                    : '0đ (Không hoàn)',
                valueStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: b.refundAmount > 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _row(
                'Trạng thái hoàn',
                b.refundStatus == 'refunded'
                    ? 'Đã hoàn tiền'
                    : 'Không đủ điều kiện hoàn',
                valueStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: b.refundStatus == 'refunded'
                      ? AppColors.success
                      : AppColors.textSecondary,
                ),
              ),
              if (b.refundReason != null && b.refundReason!.isNotEmpty) ...[
                const Divider(height: 1, thickness: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chi tiết:',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.refundReason!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]),
          ],

          const SizedBox(height: 20),

          // ── Actions ───────────────────────────────────────
          if (isUpcoming) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _checkedIn = true),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Check-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Huỷ đặt sân'),
              ),
            ),
          ],
          if (isCompleted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasReviewed ? null : _onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: Text(_hasReviewed ? 'Đã đánh giá' : 'Đánh giá sân'),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(children: children),
      );

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      );

  Widget _row(String label, String value, {TextStyle? valueStyle}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(value,
                style: valueStyle ??
                    const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
          ],
        ),
      );

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy (EEEE)', 'vi').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String iso) {
    try {
      return DateFormat('HH:mm dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _formatPrice(double p) =>
      '${NumberFormat('#,###', 'vi_VN').format(p)}đ';

  String _statusLabel(String status) {
    switch (status) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return status;
    }
  }

  String _addonLabel(String key) {
    switch (key) {
      case 'racket':
        return 'Vợt';
      case 'ball':
        return 'Bóng';
      case 'shoes':
        return 'Giày';
      default:
        return key;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        label = 'Đã xác nhận';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Đã huỷ';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
