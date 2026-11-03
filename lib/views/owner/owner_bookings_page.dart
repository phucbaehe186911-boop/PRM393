import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/booking.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';

/// Màn hình Doanh thu & Quản lý đơn đặt sân của Chủ sân (Owner)
/// Hiển thị tiền nhận được, các đơn hoàn tiền nếu khách huỷ trước thời hạn
class OwnerBookingsPage extends StatefulWidget {
  const OwnerBookingsPage({super.key});

  @override
  State<OwnerBookingsPage> createState() => _OwnerBookingsPageState();
}

class _OwnerBookingsPageState extends State<OwnerBookingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      final courtVm = context.read<CourtViewModel>();
      await courtVm.loadOwnerCourts(user.id);
      final courtIds = courtVm.ownerCourts.map((c) => c.id).toList();
      if (mounted) {
        await context.read<BookingViewModel>().loadOwnerBookings(courtIds);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatPrice(double p) =>
      '${NumberFormat('#,###', 'vi_VN').format(p)}đ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Doanh thu & Quản lý đặt sân',
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Consumer<BookingViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoadingOwnerBookings) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final allBookings = vm.ownerBookings;
          final confirmed =
              allBookings.where((b) => b.status == 'confirmed').toList();
          final cancelled =
              allBookings.where((b) => b.status == 'cancelled').toList();

          return Column(
            children: [
              // ── Metrics Thống kê Doanh thu & Hoàn tiền ───────────────────
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Doanh thu nhận được
                        Expanded(
                          child: _MetricCard(
                            title: 'Doanh thu thực nhận',
                            value: _formatPrice(vm.ownerTotalRevenue),
                            subtitle: '${vm.ownerConfirmedCount} đơn xác nhận',
                            color: AppColors.success,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tiền đã hoàn trả
                        Expanded(
                          child: _MetricCard(
                            title: 'Tiền đã hoàn trả',
                            value: _formatPrice(vm.ownerTotalRefunded),
                            subtitle: '${vm.ownerCancelledCount} đơn huỷ sân',
                            color: AppColors.primary,
                            icon: Icons.assignment_return_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Banner chính sách hoàn tiền
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.5),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Quy định: Khách huỷ trước giờ chơi ≥ 6 tiếng được hoàn 100% tiền cọc. Huỷ < 6 tiếng: Chủ sân giữ trọn tiền cọc.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textPrimary,
                                  height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Bar ──────────────────────────────────────────────────
              Container(
                color: AppColors.surface,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: 'Đang hoạt động (${confirmed.length})'),
                    Tab(text: 'Đã huỷ & Hoàn tiền (${cancelled.length})'),
                    Tab(text: 'Tất cả (${allBookings.length})'),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),

              // ── Danh sách đơn đặt ─────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _OwnerBookingList(
                      bookings: confirmed,
                      emptyText: 'Chưa có lượt đặt sân nào đang hoạt động',
                    ),
                    _OwnerBookingList(
                      bookings: cancelled,
                      emptyText: 'Chưa có lượt đặt nào bị huỷ',
                      isCancelledTab: true,
                    ),
                    _OwnerBookingList(
                      bookings: allBookings,
                      emptyText: 'Chưa có dữ liệu đặt sân',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

class _OwnerBookingList extends StatelessWidget {
  final List<Booking> bookings;
  final String emptyText;
  final bool isCancelledTab;

  const _OwnerBookingList({
    required this.bookings,
    required this.emptyText,
    this.isCancelledTab = false,
  });

  String _formatPrice(double p) =>
      '${NumberFormat('#,###', 'vi_VN').format(p)}đ';

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy (EEE)', 'vi').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined,
                size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 10),
            Text(
              emptyText,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: bookings.length,
      itemBuilder: (context, i) {
        final b = bookings[i];
        final isCancelled = b.status == 'cancelled';
        final isRefunded = b.refundStatus == 'refunded';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(
              color: isCancelled
                  ? (isRefunded ? AppColors.primary.withValues(alpha: 0.4) : AppColors.error.withValues(alpha: 0.4))
                  : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      b.courtName ?? 'Sân #${b.courtId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  _buildStatusBadge(b),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(_formatDate(b.date),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${b.startTime} - ${b.endTime}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng giá trị đơn:',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        _formatPrice(b.totalPrice),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isCancelled
                            ? (isRefunded ? 'Đã hoàn cho khách:' : 'Tiền cọc giữ lại:')
                            : 'Tiền cọc đã nhận (50%):',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? (isRefunded ? AppColors.primary : AppColors.success)
                              : AppColors.success,
                        ),
                      ),
                      Text(
                        isCancelled
                            ? (isRefunded
                                ? '-${_formatPrice(b.refundAmount)}'
                                : '+${_formatPrice(b.totalPrice * 0.5)}')
                            : '+${_formatPrice(b.totalPrice * 0.5)}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isCancelled
                              ? (isRefunded ? AppColors.primary : AppColors.success)
                              : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (b.refundReason != null && b.refundReason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'Lý do hoàn/giữ cọc: ${b.refundReason}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(Booking b) {
    if (b.status == 'confirmed') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.success),
          borderRadius: BorderRadius.circular(2),
        ),
        child: const Text(
          'Đã nhận cọc',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.success),
        ),
      );
    } else {
      final isRefunded = b.refundStatus == 'refunded';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: (isRefunded ? AppColors.primary : AppColors.error)
              .withValues(alpha: 0.1),
          border: Border.all(
              color: isRefunded ? AppColors.primary : AppColors.error),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          isRefunded ? 'Đã hoàn tiền' : 'Huỷ • Không hoàn',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isRefunded ? AppColors.primary : AppColors.error,
          ),
        ),
      );
    }
  }
}
