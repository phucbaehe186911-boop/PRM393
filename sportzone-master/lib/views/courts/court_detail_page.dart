import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/review.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/time_slot_cell.dart';

/// Màn hình chi tiết sân + booking matrix 2D
class CourtDetailPage extends StatefulWidget {
  final int courtId;
  const CourtDetailPage({super.key, required this.courtId});

  @override
  State<CourtDetailPage> createState() => _CourtDetailPageState();
}

class _CourtDetailPageState extends State<CourtDetailPage> {
  int _imageIndex = 0;
  late String _selectedDate;
  late List<String> _dateStrings;

  @override
  void initState() {
    super.initState();
    _initDates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourtViewModel>().loadCourtById(widget.courtId);
      context.read<CourtViewModel>().loadReviews(widget.courtId);
      context.read<BookingViewModel>().loadTimeSlots(
            widget.courtId,
            _selectedDate,
          );
    });
  }

  void _initDates() {
    final now = DateTime.now();
    _dateStrings = List.generate(7, (i) {
      final d = now.add(Duration(days: i));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    });
    _selectedDate = _dateStrings.first;
  }

  String _dayOfWeek(String dateStr) {
    final d = DateTime.parse(dateStr);
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return days[d.weekday - 1];
  }

  String _dayNumber(String dateStr) {
    final d = DateTime.parse(dateStr);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CourtViewModel>();
    final bookingVm = context.watch<BookingViewModel>();
    final court = vm.selectedCourt;

    if (court == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

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
          onPressed: () {
            bookingVm.clearSelection();
            context.pop();
          },
        ),
        title: Text(
          court.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                context.push('/chat/${widget.courtId}'),
            icon: const Icon(Icons.chat_bubble_outline,
                size: 16, color: AppColors.primary),
            label: const Text(
              'Liên hệ',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image slider
                _buildImageSlider(court.images),

                // Court info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              court.typeLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StarRating(rating: court.rating, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${court.rating.toStringAsFixed(1)} (${court.reviewCount})',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        court.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              court.address,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pricing
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                                child: _priceItem('Giờ thường',
                                    court.pricePerHour, AppColors.textPrimary)),
                            Container(
                                width: 1,
                                height: 36,
                                color: AppColors.border),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _priceItem('Giờ vàng (17-21h)',
                                    court.peakPricePerHour, AppColors.peak)),
                          ],
                        ),
                      ),

                      if (court.description != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          court.description!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                      ],

                      const SizedBox(height: 20),
                      // Date strip
                      const Text(
                        'Chọn ngày',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDateStrip(),

                      const SizedBox(height: 16),
                      // Slot legend
                      _buildLegend(),
                      const SizedBox(height: 12),

                      // Time slot matrix
                      const Text(
                        'Chọn khung giờ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBookingMatrix(bookingVm, court.pricePerHour,
                          court.peakPricePerHour),

                      // ── Reviews section ─────────────────────
                      const SizedBox(height: 24),
                      _buildReviewsSection(context),
                      const SizedBox(height: 80), // padding for checkout bar
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Checkout bar
          if (bookingVm.selectedSlots.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _CheckoutBar(
                court: court,
                onCheckout: () => context.push('/booking-cart'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSlider(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.surfaceDim,
        child: const Center(
            child: Icon(Icons.sports_tennis,
                color: AppColors.textDisabled, size: 40)),
      );
    }
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _imageIndex = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: images[i],
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.surfaceDim),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceDim,
                child: const Icon(Icons.sports_tennis,
                    color: AppColors.textDisabled),
              ),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (i) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _imageIndex
                          ? Colors.white
                          : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _dateStrings.map((dateStr) {
          final isSelected = dateStr == _selectedDate;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = dateStr);
              context.read<BookingViewModel>().selectDate(dateStr);
              context.read<BookingViewModel>().loadTimeSlots(
                    widget.courtId,
                    dateStr,
                  );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  Text(
                    _dayOfWeek(dateStr),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _dayNumber(dateStr),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _legendItem(AppColors.surface, 'Trống'),
        _legendItem(AppColors.primary, 'Đang chọn'),
        _legendItem(AppColors.surfaceDim, 'Đã đặt'),
        _legendItem(AppColors.peakLight, 'Giờ vàng', border: AppColors.peakBorder),
      ],
    );
  }

  Widget _legendItem(Color color, String label, {Color? border}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: border ?? AppColors.border),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
        ],
      );

  Widget _buildBookingMatrix(
      BookingViewModel vm, double offPeak, double peak) {
    if (vm.isLoadingSlots) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator.adaptive(),
      ));
    }

    final slots = vm.timeSlotsForDate;
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('Không có khung giờ nào cho ngày này',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: slots.map((slot) {
          return Column(
            children: [
              Text(
                slot.startTime,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              TimeSlotCell(
                slot: slot,
                isSelected: vm.isSlotSelected(slot),
                offPeakPrice: offPeak,
                peakPrice: peak,
                onTap: () => vm.toggleSlotSelection(slot),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewsSection(BuildContext context) {
    return Consumer<CourtViewModel>(
      builder: (_, vm, __) {
        final reviews = vm.reviews;
        final court = vm.selectedCourt;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            Row(
              children: [
                const Text(
                  'Đánh giá',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (court != null)
                  Row(
                    children: [
                      StarRating(rating: court.rating, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        '${court.rating.toStringAsFixed(1)} · ${court.reviewCount} đánh giá',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Loading ──────────────────────────────────────
            if (vm.isLoadingReviews)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: CircularProgressIndicator.adaptive()),
              )

            // ── Empty ────────────────────────────────────────
            else if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.star_border,
                        size: 32, color: AppColors.textDisabled),
                    SizedBox(height: 6),
                    Text('Chưa có đánh giá nào',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              )

            // ── Review list ──────────────────────────────────
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < reviews.length; i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border),
                      _ReviewTile(review: reviews[i]),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _priceItem(String label, double price, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(
            '${_priceShort(price)}/giờ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      );

  String _priceShort(double price) {
    if (price >= 1000) return '${(price / 1000).toStringAsFixed(0)}k';
    return NumberFormat('#,###', 'vi_VN').format(price) + 'đ';
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  (review.userName?.isNotEmpty == true
                          ? review.userName![0]
                          : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName ?? 'Người dùng',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
              StarRating(rating: review.rating, size: 12),
              const SizedBox(width: 4),
              Text(
                review.rating.toStringAsFixed(1),
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.comment!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }
}

class _CheckoutBar extends StatelessWidget {
  final dynamic court;
  final VoidCallback onCheckout;
  const _CheckoutBar({required this.court, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();
    final offPeak = court.pricePerHour as double;
    final peak = court.peakPricePerHour as double;
    final total = vm.totalPriceWithCourtPrices(offPeak, peak);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${vm.selectedSlots.length} khung giờ đã chọn',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
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
          ),
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('Đặt sân'),
          ),
        ],
      ),
    );
  }

  String _fmt(double price) =>
      NumberFormat('#,###', 'vi_VN').format(price);
}
