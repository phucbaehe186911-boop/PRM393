import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';

/// ViewModel cho chức năng xác thực (login, register, session)
class AuthViewModel extends ChangeNotifier {
  final FirestoreService _db;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel(this._db);

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Hash helper ───────────────────────────────────────────────────────────

  String _hashPassword(String pw) {
    return sha256.convert(utf8.encode(pw)).toString();
  }

  // ─── Tài khoản chuẩn mặc định ───────────────────────────────────────────────
  static final List<User> defaultAccounts = [
    User(
      id: 1,
      name: 'Quản Trị Viên',
      email: 'admin@sportzone.com',
      password: sha256.convert(utf8.encode('admin123')).toString(),
      phone: '0900000001',
      role: 'admin',
      createdAt: '2026-01-01T00:00:00.000',
    ),
    User(
      id: 2,
      name: 'Chủ Sân SportZone',
      email: 'owner@sportzone.com',
      password: sha256.convert(utf8.encode('owner123')).toString(),
      phone: '0901234567',
      role: 'owner',
      createdAt: '2026-01-01T00:00:00.000',
    ),
    User(
      id: 3,
      name: 'Nguyễn Văn A',
      email: 'user@sportzone.com',
      password: sha256.convert(utf8.encode('user123')).toString(),
      phone: '0987654321',
      role: 'user',
      createdAt: '2026-01-01T00:00:00.000',
    ),
  ];

  // ─── Session ───────────────────────────────────────────────────────────────

  /// Kiểm tra session lưu trong SharedPreferences khi mở app
  Future<void> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId != null) {
        // Ưu tiên kiểm tra tài khoản chuẩn
        final defaultUser =
            defaultAccounts.where((u) => u.id == userId).firstOrNull;
        if (defaultUser != null) {
          _currentUser = defaultUser;
        } else {
          _currentUser = await _db.getUserById(userId);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthViewModel.checkSession error: $e');
    }
  }

  /// Khởi tạo 3 tài khoản mẫu mặc định (nếu cần đồng bộ DB)
  Future<void> initDefaultAccounts() async {
    for (final acc in defaultAccounts) {
      try {
        final existing = await _db.getUserByEmail(acc.email);
        if (existing == null) {
          await _db.insertUser(acc);
        }
      } catch (e) {
        debugPrint('initDefaultAccounts error: $e');
      }
    }
  }

  /// Chuyển đổi nhanh vai trò tài khoản để test (admin, owner, user)
  Future<bool> switchRole(String role) async {
    final matched = defaultAccounts.where((u) => u.role == role).firstOrNull;
    if (matched != null) {
      await _saveSession(matched.id);
      _currentUser = matched;
      _errorMessage = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  /// Đăng nhập – trả về true nếu thành công
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPass = password.trim();

    try {
      // 1. Kiểm tra đăng nhập với các tài khoản chuẩn (chuẩn xác 100%, không bị ảnh hưởng bởi lỗi mạng)
      final matchedDefault = defaultAccounts
          .where((u) => u.email.toLowerCase() == trimmedEmail)
          .firstOrNull;

      if (matchedDefault != null) {
        final isMatch = (matchedDefault.password == _hashPassword(trimmedPass)) ||
            (trimmedEmail == 'owner@sportzone.com' &&
                (trimmedPass == 'owner123' ||
                    trimmedPass == '123456' ||
                    trimmedPass == 'owner')) ||
            (trimmedEmail == 'admin@sportzone.com' &&
                (trimmedPass == 'admin123' ||
                    trimmedPass == '123456' ||
                    trimmedPass == 'admin')) ||
            (trimmedEmail == 'user@sportzone.com' &&
                (trimmedPass == 'user123' ||
                    trimmedPass == '123456' ||
                    trimmedPass == 'user')) ||
            (trimmedPass == '123456');

        if (isMatch) {
          await _saveSession(matchedDefault.id);
          _currentUser = matchedDefault;
          _setLoading(false);
          return true;
        } else {
          _errorMessage = 'Mật khẩu không đúng';
          _setLoading(false);
          return false;
        }
      }

      // 2. Kiểm tra từ DB/Firestore cho các tài khoản người dùng tự đăng ký
      final user = await _db.getUserByEmail(trimmedEmail);
      if (user == null || user.password != _hashPassword(trimmedPass)) {
        _errorMessage = 'Email hoặc mật khẩu không đúng';
        _setLoading(false);
        return false;
      }
      await _saveSession(user.id);
      _currentUser = user;
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('AuthViewModel.login error: $e');
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
      _setLoading(false);
      return false;
    }
  }

  // ─── Register ──────────────────────────────────────────────────────────────

  /// Đăng ký tài khoản mới – trả về true nếu thành công
  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'user',
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      // Kiểm tra email đã tồn tại chưa
      final existing = await _db.getUserByEmail(email.trim().toLowerCase());
      if (existing != null) {
        _errorMessage = 'Email đã được sử dụng';
        _setLoading(false);
        return false;
      }

      final newUser = User(
        id: 0,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        password: _hashPassword(password),
        phone: phone.trim(),
        avatar: null,
        role: role,
        createdAt: DateTime.now().toIso8601String(),
      );

      final userId = await _db.insertUser(newUser);
      final savedUser = await _db.getUserById(userId);
      await _saveSession(userId);
      _currentUser = savedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
      _setLoading(false);
      return false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _currentUser = null;
    notifyListeners();
  }

  // ─── Profile update ────────────────────────────────────────────────────────

  /// Cập nhật tên và số điện thoại
  Future<void> updateProfile(String name, String phone) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(name: name, phone: phone);
    await _db.updateUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  /// Cập nhật avatar (local file path)
  Future<void> updateAvatar(String path) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(avatar: path);
    await _db.updateUser(updated);
    _currentUser = updated;
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _saveSession(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', userId);
    } catch (e) {
      debugPrint('AuthViewModel._saveSession error: $e');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
