import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_colors.dart';
import '../models/booking.dart';

/// Tile hiển thị thông tin một lượt đặt sân trong danh sách
class BookingTile extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final bool? hasReviewed;
  final VoidCallback? onTap;

  const BookingTile({
    super.key,
    required this.booking,
    this.onCancel,
    this.onReview,
    this.hasReviewed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    booking.courtName ?? 'Sân ${booking.courtId}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _StatusBadge(
                  status: booking.status,
                  refundStatus: booking.refundStatus,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.calendar_today_outlined, _formatDate(booking.date)),
            const SizedBox(height: 4),
            _infoRow(
              Icons.access_time_outlined,
              '${booking.startTime} - ${booking.endTime}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _formatPrice(booking.totalPrice),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.textDisabled),
                if (onCancel != null)
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Huỷ đặt'),
                  ),
                if (onReview != null)
                  ElevatedButton(
                    onPressed: hasReviewed == true ? null : onReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    child: Text(
                      hasReviewed == true ? 'Đã đánh giá' : 'Đánh giá',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy (EEE)', 'vi').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatPrice(double price) {
    return '${NumberFormat('#,###', 'vi_VN').format(price)}đ';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String? refundStatus;
  const _StatusBadge({required this.status, this.refundStatus});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = AppColors.success;
        label = 'Đã đặt';
        break;
      case 'cancelled':
        if (refundStatus == 'refunded') {
          color = AppColors.primary;
          label = 'Đã huỷ • Hoàn tiền';
        } else {
          color = AppColors.error;
          label = 'Đã huỷ';
        }
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
