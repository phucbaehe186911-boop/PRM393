import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import '../../viewmodels/auth_viewmodel.dart';

/// Màn hình đăng nhập
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthViewModel>().clearError();

    final success = await context.read<AuthViewModel>().login(
          _emailCtrl.text,
          _passwordCtrl.text,
        );

    if (success && mounted) {
      final user = context.read<AuthViewModel>().currentUser;
      _navigateForUserRole(user);
    }
  }

  void _navigateForUserRole(dynamic user) {
    if (user?.isAdmin == true) {
      context.go('/admin/dashboard');
    } else if (user?.isOwner == true) {
      context.go('/owner/courts');
    } else {
      context.go('/home');
    }
  }

  Future<void> _quickLogin(String email, String password) async {
    setState(() {
      _emailCtrl.text = email;
      _passwordCtrl.text = password;
    });
    context.read<AuthViewModel>().clearError();

    final success = await context.read<AuthViewModel>().login(email, password);
    if (success && mounted) {
      final user = context.read<AuthViewModel>().currentUser;
      final roleTitle = user?.isAdmin == true
          ? '🛡️ Quản Trị Viên (Admin)'
          : user?.isOwner == true
              ? '🏟️ Chủ Sân (Owner)'
              : '👤 Khách hàng (User)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đăng nhập thành công: $roleTitle'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
      _navigateForUserRole(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.sports_tennis,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'SportZone',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      AppStrings.loginTitle,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  Consumer<AuthViewModel>(
                    builder: (_, vm, __) {
                      if (vm.errorMessage == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vm.errorMessage!,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.error),
                        ),
                      );
                    },
                  ),

                  // Email field
                  const Text('Email',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('example@email.com'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password field
                  const Text(AppStrings.passwordLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onLogin(),
                    decoration: _inputDecoration('Nhập mật khẩu').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return AppStrings.fieldRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Login button
                  Consumer<AuthViewModel>(
                    builder: (_, vm, __) => ElevatedButton(
                      onPressed: vm.isLoading ? null : _onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.white)))
                          : const Text(AppStrings.loginButton),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Navigate to register
                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text(
                      AppStrings.noAccount,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 12),

                  // ── Quick Fill Demo Accounts ─────────────────────────
                  const Text(
                    'CHỌN VAI TRÒ ĐỂ ĐĂNG NHẬP NGAY (1 CHẠM):',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Chủ Sân (Owner)
                  OutlinedButton(
                    onPressed: () =>
                        _quickLogin('owner@sportzone.com', 'owner123'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.sports_tennis,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🏟️ CHỦ SÂN (Owner)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary),
                              ),
                              Text(
                                'owner@sportzone.com • Quản lý sân, doanh thu & đơn huỷ',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quản Trị Viên (Admin)
                  OutlinedButton(
                    onPressed: () =>
                        _quickLogin('admin@sportzone.com', 'admin123'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.admin_panel_settings,
                              color: Colors.red, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🛡️ QUẢN TRỊ VIÊN (Admin)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red),
                              ),
                              Text(
                                'admin@sportzone.com • Quản trị hệ thống, toàn bộ sân & user',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.red),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Khách hàng (User)
                  OutlinedButton(
                    onPressed: () =>
                        _quickLogin('user@sportzone.com', 'user123'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue, width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.person,
                              color: Colors.blue, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '👤 KHÁCH HÀNG (User)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blue),
                              ),
                              Text(
                                'user@sportzone.com • Tìm kiếm sân, đặt sân & huỷ sân',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textDisabled, fontSize: 13),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      );
}
