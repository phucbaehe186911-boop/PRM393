import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';
import '../../widgets/court_card.dart';

/// Màn hình danh sách sân với tìm kiếm và lọc theo loại
class CourtListPage extends StatefulWidget {
  const CourtListPage({super.key});

  @override
  State<CourtListPage> createState() => _CourtListPageState();
}

class _CourtListPageState extends State<CourtListPage> {
  final _searchCtrl = TextEditingController();

  static const _types = [
    ('all', AppStrings.allTypes),
    ('pickleball', AppStrings.pickleball),
    ('badminton', AppStrings.badminton),
    ('football', AppStrings.football),
    ('tennis', AppStrings.tennis),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourtViewModel>().loadCourts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SportZone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Tìm sân thể thao gần bạn',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Consumer<AuthViewModel>(
            builder: (_, authVm, __) {
              final user = authVm.currentUser;
              if (user == null) return const SizedBox.shrink();
              if (user.isAdmin) {
                return TextButton.icon(
                  onPressed: () => context.push('/admin/dashboard'),
                  icon: const Icon(Icons.admin_panel_settings,
                      size: 16, color: Colors.red),
                  label: const Text('Admin',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red)),
                );
              }
              if (user.isOwner) {
                return TextButton.icon(
                  onPressed: () => context.push('/owner/courts'),
                  icon: const Icon(Icons.storefront, size: 16),
                  label: const Text('Sân của tôi',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      floatingActionButton: Consumer<AuthViewModel>(
        builder: (_, authVm, __) {
          final user = authVm.currentUser;
          if (user != null && (user.isOwner || user.isAdmin)) {
            return FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add),
              label: const Text('Thêm sân',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => context.push('/owner/court/add'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      body: Column(
        children: [
          // Banner vai trò đặc biệt
          Consumer<AuthViewModel>(
            builder: (_, authVm, __) {
              final user = authVm.currentUser;
              if (user == null) return const SizedBox.shrink();
              if (user.isOwner) {
                return Container(
                  width: double.infinity,
                  color: AppColors.primary.withValues(alpha: 0.08),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Chế độ Chủ Sân: Quản lý sân & Doanh thu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/owner/courts'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Vào quản lý >',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }
              if (user.isAdmin) {
                return Container(
                  width: double.infinity,
                  color: Colors.red.withValues(alpha: 0.08),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings,
                          size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Chế độ Admin: Quản trị sàn & toàn bộ hệ thống',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/admin/dashboard'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Vào Dashboard >',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => context.read<CourtViewModel>().search(v),
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                hintStyle: const TextStyle(
                    color: AppColors.textDisabled, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.textSecondary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchCtrl.clear();
                          context.read<CourtViewModel>().search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // Type filter chips
          Consumer<CourtViewModel>(
            builder: (_, vm, __) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: _types.map((t) {
                  final selected = vm.selectedType == t.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => vm.filterByType(t.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surface,
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Court grid
          Expanded(
            child: Consumer<CourtViewModel>(
              builder: (_, vm, __) {
                if (vm.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  );
                }
                if (vm.filteredCourts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sports_tennis,
                            size: 48, color: AppColors.textDisabled),
                        const SizedBox(height: 12),
                        const Text(
                          AppStrings.noCourtsFound,
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                        if (vm.searchQuery.isNotEmpty ||
                            vm.selectedType != 'all')
                          TextButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              vm.search('');
                              vm.filterByType('all');
                            },
                            child: const Text('Xoá bộ lọc'),
                          ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: vm.filteredCourts.length,
                  itemBuilder: (ctx, i) {
                    final court = vm.filteredCourts[i];
                    return CourtCard(
                      court: court,
                      onTap: () => ctx.push('/court/${court.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
