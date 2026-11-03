import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../models/booking.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';
import '../../viewmodels/notification_viewmodel.dart';
import '../../widgets/booking_tile.dart';
import '../../widgets/star_rating.dart';

/// Màn hình lịch đặt sân của người dùng
class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<BookingViewModel>().loadUserBookings(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onCancel(Booking booking) async {
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

    if (confirmed != true) return;

    final user = context.read<AuthViewModel>().currentUser;
    final bookingVm = context.read<BookingViewModel>();
    final notifVm = context.read<NotificationViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    await bookingVm.cancelBooking(booking);

    if (user != null && mounted) {
      await notifVm.createNotification(
            userId: user.id,
            title: 'Huỷ đặt sân thành công',
            body: 'Bạn đã huỷ đặt sân ${booking.courtName ?? ''}. Tiền cọc sẽ được hoàn theo chính sách.',
            type: 'cancel',
            bookingId: booking.id,
          );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(AppStrings.bookingCancelled),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  Future<void> _onReview(Booking booking) async {
    double rating = 5;
    final commentCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: Text(
            'Đánh giá ${booking.courtName ?? 'sân'}',
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRating(
                rating: rating,
                size: 32,
                onChanged: (r) => setDialogState(() => rating = r),
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
                    borderSide:
                        const BorderSide(color: AppColors.border),
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
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: AppColors.border),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
                tabs: const [
                  Tab(text: AppStrings.upcoming),
                  Tab(text: AppStrings.completed),
                  Tab(text: AppStrings.cancelled),
                ],
              ),
            ],
          ),
        ),
        title: const Text(
          AppStrings.myBookings,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ),
      body: Consumer<BookingViewModel>(
        builder: (_, vm, __) {
          if (vm.isLoadingBookings) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final now = DateTime.now();
          final nowStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

          final upcoming = vm.userBookings
              .where((b) =>
                  b.status == 'confirmed' && b.date.compareTo(nowStr) >= 0)
              .toList();
          final completed = vm.userBookings
              .where((b) =>
                  b.status == 'confirmed' && b.date.compareTo(nowStr) < 0)
              .toList();
          final cancelled = vm.userBookings
              .where((b) => b.status == 'cancelled')
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _BookingList(
                bookings: upcoming,
                emptyMessage: 'Chưa có lịch đặt sân sắp tới',
                onCancel: _onCancel,
              ),
              _BookingList(
                bookings: completed,
                emptyMessage: 'Chưa có trận đấu nào',
                onReview: _onReview,
              ),
              _BookingList(
                bookings: cancelled,
                emptyMessage: 'Chưa có đặt sân nào bị huỷ',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyMessage;
  final Future<void> Function(Booking)? onCancel;
  final Future<void> Function(Booking)? onReview;

  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    this.onCancel,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (ctx, i) {
        final booking = bookings[i];
        final reviewed =
            context.read<BookingViewModel>().isReviewed(booking.id);
        return BookingTile(
          booking: booking,
          onTap: () => ctx.push('/booking-detail/${booking.id}'),
          onCancel: onCancel != null ? () => onCancel!(booking) : null,
          onReview: onReview != null ? () => onReview!(booking) : null,
          hasReviewed: reviewed,
        );
      },
    );
  }
}
