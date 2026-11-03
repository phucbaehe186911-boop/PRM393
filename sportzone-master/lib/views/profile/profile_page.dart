import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Màn hình hồ sơ người dùng
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameCtrl.text = user?.name ?? '';
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      await context.read<AuthViewModel>().updateAvatar(file.path);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await context
        .read<AuthViewModel>()
        .updateProfile(_nameCtrl.text.trim(), _phoneCtrl.text.trim());
    setState(() { _isSaving = false; _isEditing = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu thành công'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('Đăng xuất',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(AppStrings.logoutConfirm),
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
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthViewModel>().logout();
      if (mounted) context.go('/login');
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
        title: const Text(
          AppStrings.profileTitle,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            child: Text(
              _isEditing ? 'Hủy' : 'Sửa',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, vm, _) {
          final user = vm.currentUser;
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── Header ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryMuted, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: user.avatar != null
                                  ? FileImage(File(user.avatar!))
                                  : null,
                              child: user.avatar == null
                                  ? const Icon(Icons.person,
                                      size: 40, color: AppColors.primary)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 13, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.primaryMuted),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          user.isAdmin
                              ? '🛡️ QUẢN TRỊ VIÊN'
                              : user.isOwner
                                  ? '🏟️ CHỦ SÂN'
                                  : '👤 KHÁCH HÀNG',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Chuyển đổi vai trò test nhanh ────────────────
                      _sectionLabel('Chuyển đổi vai trò test nhanh (1 chạm)'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _roleSwitchButton(
                                label: '👤 Khách',
                                isActive: user.isUser,
                                activeColor: Colors.blue,
                                onTap: () async {
                                  await vm.switchRole('user');
                                  _nameCtrl.text = vm.currentUser?.name ?? '';
                                  _phoneCtrl.text = vm.currentUser?.phone ?? '';
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Đã chuyển sang vai trò: 👤 Khách hàng (User)'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _roleSwitchButton(
                                label: '🏟️ Chủ Sân',
                                isActive: user.isOwner,
                                activeColor: AppColors.primary,
                                onTap: () async {
                                  await vm.switchRole('owner');
                                  _nameCtrl.text = vm.currentUser?.name ?? '';
                                  _phoneCtrl.text = vm.currentUser?.phone ?? '';
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Đã chuyển sang vai trò: 🏟️ Chủ Sân (Owner)'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _roleSwitchButton(
                                label: '🛡️ Admin',
                                isActive: user.isAdmin,
                                activeColor: Colors.red,
                                onTap: () async {
                                  await vm.switchRole('admin');
                                  _nameCtrl.text = vm.currentUser?.name ?? '';
                                  _phoneCtrl.text = vm.currentUser?.phone ?? '';
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Đã chuyển sang vai trò: 🛡️ Quản Trị Viên (Admin)'),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Thông tin cá nhân ─────────────────────
                      _sectionLabel('Thông tin cá nhân'),
                      const SizedBox(height: 6),
                      _infoCard([
                        _infoRow(
                          icon: Icons.person_outline,
                          label: AppStrings.nameLabel,
                          child: _isEditing
                              ? TextField(
                                  controller: _nameCtrl,
                                  decoration: _inputDec('Họ và tên'),
                                  style: const TextStyle(fontSize: 13),
                                )
                              : Text(user.name,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary)),
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.phone_outlined,
                          label: AppStrings.phoneLabel,
                          child: _isEditing
                              ? TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: _inputDec('Số điện thoại'),
                                  style: const TextStyle(fontSize: 13),
                                )
                              : Text(
                                  user.phone?.isNotEmpty == true
                                      ? user.phone!
                                      : '—',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary)),
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          child: Text(user.email,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ),
                      ]),

                      if (_isEditing) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(AppStrings.saveChanges,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ── Hoạt động ─────────────────────────────
                      _sectionLabel('Hoạt động'),
                      const SizedBox(height: 6),
                      _infoCard([
                        _actionRow(
                          icon: Icons.calendar_today_outlined,
                          label: AppStrings.myBookings,
                          onTap: () => context.push('/my-bookings'),
                        ),
                      ]),

                      if (user.isOwner || user.isAdmin) ...[
                        const SizedBox(height: 16),
                        _sectionLabel('Dành cho Chủ Sân'),
                        const SizedBox(height: 6),
                        _infoCard([
                          _actionRow(
                            icon: Icons.sports_tennis,
                            label: 'Quản lý sân của tôi (Thêm / Sửa / Xoá)',
                            iconColor: AppColors.primary,
                            onTap: () => context.push('/owner/courts'),
                          ),
                          _divider(),
                          _actionRow(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Doanh thu & Quản lý hoàn tiền',
                            iconColor: AppColors.primary,
                            onTap: () => context.push('/owner/bookings'),
                          ),
                        ]),
                      ],

                      if (user.isAdmin) ...[
                        const SizedBox(height: 16),
                        _sectionLabel('Dành cho Quản Trị Viên'),
                        const SizedBox(height: 6),
                        _infoCard([
                          _actionRow(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'Bảng điều khiển Admin',
                            iconColor: Colors.red,
                            onTap: () => context.push('/admin/dashboard'),
                          ),
                        ]),
                      ],

                      const SizedBox(height: 16),

                      // ── Tài khoản ─────────────────────────────
                      _sectionLabel('Tài khoản'),
                      const SizedBox(height: 6),
                      _infoCard([
                        _actionRow(
                          icon: Icons.logout,
                          label: AppStrings.logoutButton,
                          labelColor: AppColors.error,
                          iconColor: AppColors.error,
                          onTap: _logout,
                          showArrow: false,
                        ),
                      ]),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 2),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _infoCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(children: children),
      );

  Widget _infoRow({
    required IconData icon,
    required String label,
    required Widget child,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  child,
                ],
              ),
            ),
          ],
        ),
      );

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = AppColors.textSecondary,
    Color labelColor = AppColors.textPrimary,
    bool showArrow = true,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: labelColor)),
              ),
              if (showArrow)
                const Icon(Icons.chevron_right,
                    size: 16, color: AppColors.textDisabled),
            ],
          ),
        ),
      );

  Widget _divider() => const Divider(
      height: 1, thickness: 1, color: AppColors.border, indent: 40);

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textDisabled, fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  Widget _roleSwitchButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? activeColor : AppColors.border,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive ? activeColor : AppColors.textSecondary,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'ĐANG CHỌN',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
