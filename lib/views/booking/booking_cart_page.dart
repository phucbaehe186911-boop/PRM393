import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';

/// Màn hình giỏ đặt sân – review selection và chọn add-ons
class BookingCartPage extends StatelessWidget {
  const BookingCartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final courtVm = context.watch<CourtViewModel>();
    final court = courtVm.selectedCourt;

    final offPeak = court?.pricePerHour ?? 100000;
    final peak = court?.peakPricePerHour ?? 200000;
    final total = vm.totalPriceWithCourtPrices(offPeak, peak);

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
          'Giỏ đặt sân',
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
            // Court name
            if (court != null) ...[
              Text(court.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(court.address,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
            ],

            // Selected slots
            const Text('Khung giờ đã chọn',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ...vm.selectedSlots.map((slot) {
              final price = slot.isPeak ? peak : offPeak;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (slot.isPeak)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.peakLight,
                          border: Border.all(color: AppColors.peakBorder),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('Giờ vàng',
                            style: TextStyle(
                                fontSize: 9,
                                color: AppColors.peak,
                                fontWeight: FontWeight.w600)),
                      ),
                    const Spacer(),
                    Text(
                      '${_fmt(price)}đ',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Add-ons
            const Text('Dịch vụ thêm',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            _AddonToggle(
              label: 'Thuê vợt',
              price: BookingViewModel.addonPrices['racket']!,
              selected: vm.selectedAddons['racket'] ?? false,
              onTap: () => vm.toggleAddon('racket'),
            ),
            const SizedBox(height: 6),
            _AddonToggle(
              label: 'Nhặt bóng',
              price: BookingViewModel.addonPrices['ball']!,
              selected: vm.selectedAddons['ball'] ?? false,
              onTap: () => vm.toggleAddon('ball'),
            ),
            const SizedBox(height: 6),
            _AddonToggle(
              label: 'Nước suối thùng',
              price: BookingViewModel.addonPrices['water']!,
              selected: vm.selectedAddons['water'] ?? false,
              onTap: () => vm.toggleAddon('water'),
            ),

            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 12),

            // Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
                const Text('Tiền cọc 50%',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  '${_fmt(total * 0.5)}đ',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/checkout'),
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
                child: const Text('XÁC NHẬN ĐẶT SÂN'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double price) => NumberFormat('#,###', 'vi_VN').format(price);
}

class _AddonToggle extends StatelessWidget {
  final String label;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  const _AddonToggle({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '+${NumberFormat('#,###', 'vi_VN').format(price)}đ',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
