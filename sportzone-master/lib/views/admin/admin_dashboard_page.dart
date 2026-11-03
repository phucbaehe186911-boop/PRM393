import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/court.dart';
import '../../models/user.dart';
import '../../models/booking.dart';
import '../../services/firestore_service.dart';
import '../../viewmodels/court_viewmodel.dart';

/// Màn hình Quản trị viên (Admin Dashboard)
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _loading = true;
  List<User> _users = [];
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _loading = true);
    try {
      final db = FirestoreService();
      final users = await db.getAllUsers();
      final bookings = await db.getAllBookings();
      if (mounted) {
        setState(() {
          _users = users;
          _bookings = bookings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatPrice(double p) =>
      '${NumberFormat('#,###', 'vi_VN').format(p)}đ';

  @override
  Widget build(BuildContext context) {
    final courtVm = context.watch<CourtViewModel>();
    final courts = courtVm.courts;

    final totalRevenue = _bookings.fold<double>(
        0, (sum, b) => sum + (b.status == 'confirmed' ? b.totalPrice : 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Bảng điều khiển Admin',
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
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Xem giao diện khách hàng',
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Thống kê tổng quan ──────────────────────────────────
                  const Text(
                    'TỔNG QUAN HỆ THỐNG',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(
                        title: 'Tổng số sân',
                        value: '${courts.length}',
                        icon: Icons.sports_tennis,
                        color: AppColors.primary,
                      ),
                      _StatCard(
                        title: 'Người dùng',
                        value: '${_users.length}',
                        icon: Icons.people_outline,
                        color: Colors.blue,
                      ),
                      _StatCard(
                        title: 'Lượt đặt sân',
                        value: '${_bookings.length}',
                        icon: Icons.calendar_month_outlined,
                        color: Colors.orange,
                      ),
                      _StatCard(
                        title: 'Tổng giá trị GD',
                        value: _formatPrice(totalRevenue),
                        icon: Icons.monetization_on_outlined,
                        color: AppColors.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Danh sách Người dùng ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DANH SÁCH TÀI KHOẢN HỆ THỐNG',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5),
                      ),
                      Text('${_users.length} tài khoản',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textDisabled)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, thickness: 1, color: AppColors.border),
                      itemBuilder: (context, i) {
                        final u = _users[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: _getRoleColor(u.role).withValues(alpha: 0.15),
                            child: Icon(
                              _getRoleIcon(u.role),
                              size: 16,
                              color: _getRoleColor(u.role),
                            ),
                          ),
                          title: Text(
                            u.name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${u.email}  •  ${u.phone ?? 'Chưa có SĐT'}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRoleColor(u.role).withValues(alpha: 0.1),
                              border: Border.all(
                                  color: _getRoleColor(u.role).withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              u.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _getRoleColor(u.role),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Phân bố môn thể thao ─────────────────────────────────
                  const Text(
                    'PHÂN BỐ SÂN THEO MÔN THỂ THAO',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        _SportRow(
                          label: 'Pickleball',
                          count: courts.where((c) => c.type == 'pickleball').length,
                          total: courts.length,
                          icon: '🏓',
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _SportRow(
                          label: 'Cầu lông',
                          count: courts.where((c) => c.type == 'badminton').length,
                          total: courts.length,
                          icon: '🏸',
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _SportRow(
                          label: 'Bóng đá',
                          count: courts.where((c) => c.type == 'football').length,
                          total: courts.length,
                          icon: '⚽',
                        ),
                        const Divider(height: 16, color: AppColors.border),
                        _SportRow(
                          label: 'Tennis',
                          count: courts.where((c) => c.type == 'tennis').length,
                          total: courts.length,
                          icon: '🎾',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'owner':
        return AppColors.primary;
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'owner':
        return Icons.storefront;
      default:
        return Icons.person;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SportRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final String icon;

  const _SportRow({
    required this.label,
    required this.count,
    required this.total,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (count / total) : 0.0;
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.background,
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('$count sân',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

