import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/vnpay_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../payment/vnpay_payment_page.dart';

/// Màn hình xác nhận đặt sân cuối cùng
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isConfirming = false;

  Future<void> _onConfirm() async {
    setState(() => _isConfirming = true);

    final user = context.read<AuthViewModel>().currentUser;
    final court = context.read<CourtViewModel>().selectedCourt;
    final bookingVm = context.read<BookingViewModel>();

    if (user == null || court == null) {
      setState(() => _isConfirming = false);
      return;
    }

    final offPeak = court.pricePerHour;
    final peak = court.peakPricePerHour;
    final total = bookingVm.totalPriceWithCourtPrices(offPeak, peak);
    final deposit = total * 0.5;

    // Tạo URL thanh toán VNPay
    final paymentUrl = VNPayService.buildPaymentUrl(
      bookingId: DateTime.now().millisecondsSinceEpoch % 100000,
      amount: deposit,
      orderInfo: 'Dat san ${court.name} - SportZone',
    );

    setState(() => _isConfirming = false);

    // Mở màn VNPay
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VnPayPaymentPage(
          paymentUrl: paymentUrl,
          onResult: (result) => _handlePaymentResult(result),
        ),
      ),
    );
  }

  Future<void> _handlePaymentResult(VNPayResult result) async {
    if (!result.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Thanh toán thành công → confirm booking
    setState(() => _isConfirming = true);

    final user = context.read<AuthViewModel>().currentUser;
    final court = context.read<CourtViewModel>().selectedCourt;
    final bookingVm = context.read<BookingViewModel>();
    final notifVm = context.read<NotificationViewModel>();

    if (user == null || court == null) {
      setState(() => _isConfirming = false);
      return;
    }

    try {
      final bookingId = await bookingVm.confirmBooking(
        userId: user.id,
        courtId: court.id,
      );

      await notifVm.createNotification(
        userId: user.id,
        title: 'Đặt sân thành công',
        body: 'Bạn đã đặt sân ${court.name} thành công. Mã đặt sân: #$bookingId',
        type: 'booking',
        bookingId: bookingId,
      );

      await NotificationService().showNotification(
        title: 'Đặt sân thành công',
        body: 'Sân ${court.name} đã được giữ chỗ cho bạn!',
        id: bookingId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đặt sân thành công! Mã GD: ${result.transactionNo}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xác nhận đặt sân: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final court = context.watch<CourtViewModel>().selectedCourt;
    final user = context.watch<AuthViewModel>().currentUser;

    final offPeak = court?.pricePerHour ?? 100000;
    final peak = court?.peakPricePerHour ?? 200000;
    final total = vm.totalPriceWithCourtPrices(offPeak, peak);

    final slots = vm.selectedSlots;
    final sorted = [...slots]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Xác nhận đặt sân',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thông tin đặt sân',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (court != null) ...[
                    _row('Sân', court.name),
                    _row('Địa chỉ', court.address),
                  ],
                  if (sorted.isNotEmpty) ...[
                    _row('Ngày', sorted.first.date),
                    _row('Giờ',
                        '${sorted.first.startTime} - ${sorted.last.endTime}'),
                    _row('Thời lượng', '${sorted.length}h'),
                  ],
                  if (user != null) _row('Khách', user.name),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thanh toán',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ...sorted.map((slot) {
                    final price = slot.isPeak ? peak : offPeak;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            '${slot.startTime}-${slot.endTime}${slot.isPeak ? ' (giờ vàng)' : ''}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_fmt(price)}đ',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Add-ons
                  ...vm.selectedAddons.entries
                      .where((e) => e.value)
                      .map((e) {
                    final addonLabels = {
                      'racket': 'Thuê vợt',
                      'ball': 'Nhặt bóng',
                      'water': 'Nước suối',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            addonLabels[e.key] ?? e.key,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                          const Spacer(),
                          Text(
                            '+${_fmt(BookingViewModel.addonPrices[e.key]!)}đ',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng tiền',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(
                        '${_fmt(total)}đ',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cọc 50%',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      Text(
                        '${_fmt(total * 0.5)}đ',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                child: _isConfirming
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white)))
                    : const Text('XÁC NHẬN & THANH TOÁN CỌC'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ),
          ],
        ),
      );

  String _fmt(double price) => NumberFormat('#,###', 'vi_VN').format(price);
}
