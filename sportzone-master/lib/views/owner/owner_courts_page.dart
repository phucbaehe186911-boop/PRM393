import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/court.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';

/// Màn hình quản lý sân của Chủ sân (Owner) - Xem danh sách, Thêm, Sửa, Xoá
class OwnerCourtsPage extends StatefulWidget {
  const OwnerCourtsPage({super.key});

  @override
  State<OwnerCourtsPage> createState() => _OwnerCourtsPageState();
}

class _OwnerCourtsPageState extends State<OwnerCourtsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<CourtViewModel>().loadOwnerCourts(user.id);
      }
    });
  }

  Future<void> _onDeleteCourt(Court court) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Xác nhận xoá sân',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc chắn muốn xoá sân "${court.name}" khỏi hệ thống không? Toàn bộ lịch đặt sẽ bị gỡ bỏ.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
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
            child: const Text('Xoá sân'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        await context.read<CourtViewModel>().deleteCourt(court.id, user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xoá sân "${court.name}"'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Quản lý sân của tôi',
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
            tooltip: 'Xem giao diện khách hàng',
            icon: const Icon(Icons.home_outlined),
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            tooltip: 'Xem doanh thu & đơn huỷ',
            icon: const Icon(Icons.monetization_on_outlined,
                color: AppColors.primary),
            onPressed: () => context.push('/owner/bookings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sân mới',
            style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () => context.push('/owner/court/add'),
      ),
      body: Consumer<CourtViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final courts = vm.ownerCourts;

          if (courts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_tennis_outlined,
                      size: 56, color: AppColors.textDisabled),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn chưa đăng ký sân thể thao nào',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bấm nút "Thêm sân mới" bên dưới để bắt đầu nhận đặt sân',
                    style: TextStyle(fontSize: 12, color: AppColors.textDisabled),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/owner/court/add'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm sân đầu tiên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 80),
            itemCount: courts.length,
            itemBuilder: (context, index) {
              final court = courts[index];
              return _OwnerCourtCard(
                court: court,
                onEdit: () => context.push('/owner/court/edit/${court.id}'),
                onDelete: () => _onDeleteCourt(court),
                onView: () => context.push('/court/${court.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

class _OwnerCourtCard extends StatelessWidget {
  final Court court;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _OwnerCourtCard({
    required this.court,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  String _formatPrice(double p) =>
      '${NumberFormat('#,###', 'vi_VN').format(p)}đ';

  @override
  Widget build(BuildContext context) {
    final imgUrl = court.images.isNotEmpty ? court.images.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius:
                    const BorderRadius.only(topLeft: Radius.circular(4)),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.sports_tennis,
                                color: AppColors.primary),
                          ),
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.sports_tennis,
                              color: AppColors.primary),
                        ),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              court.typeLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.star,
                              size: 13, color: AppColors.star),
                          const SizedBox(width: 2),
                          Text(
                            court.rating > 0
                                ? court.rating.toStringAsFixed(1)
                                : 'Mới',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        court.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        court.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatPrice(court.pricePerHour),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text('/h  •  Giờ vàng: ',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.textSecondary)),
                          Text(
                            _formatPrice(court.peakPricePerHour),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined, size: 15),
                  label: const Text('Xem sân', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Sửa', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 15),
                  label: const Text('Xoá', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

