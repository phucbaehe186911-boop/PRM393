import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../models/time_slot.dart';

/// Cell trong booking matrix – hiển thị trạng thái và giá của một khung giờ
class TimeSlotCell extends StatelessWidget {
  final TimeSlot slot;
  final bool isSelected;
  final double offPeakPrice;
  final double peakPrice;
  final VoidCallback? onTap;

  const TimeSlotCell({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.offPeakPrice,
    required this.peakPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = _getDecoration();
    final priceText = _getPriceText();
    final textColor = _getTextColor();

    return GestureDetector(
      onTap: slot.isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 62,
        height: 48,
        decoration: decoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              priceText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (!slot.isAvailable)
              Text(
                'Đã đặt',
                style: TextStyle(
                  fontSize: 8,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (isSelected)
              Text(
                'Đã chọn',
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getDecoration() {
    if (isSelected) {
      return BoxDecoration(
        color: AppColors.primary,
        border: Border.all(color: AppColors.primary),
      );
    }
    if (!slot.isAvailable) {
      return BoxDecoration(
        color: AppColors.surfaceDim,
        border: Border.all(color: AppColors.border),
      );
    }
    if (slot.isPeak) {
      return BoxDecoration(
        color: AppColors.peakLight,
        border: Border.all(color: AppColors.peakBorder),
      );
    }
    return BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
    );
  }

  String _getPriceText() {
    final price = slot.isPeak ? peakPrice : offPeakPrice;
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}k';
    return '${price.toInt()}';
  }

  Color _getTextColor() {
    if (isSelected) return Colors.white;
    if (!slot.isAvailable) return AppColors.textDisabled;
    if (slot.isPeak) return AppColors.peak;
    return AppColors.textSecondary;
  }
}
