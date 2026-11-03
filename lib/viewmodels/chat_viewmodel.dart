import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/court.dart';
import '../services/firestore_service.dart';

/// ViewModel cho chức năng chat với chủ sân
class ChatViewModel extends ChangeNotifier {
  final FirestoreService _db;

  final Map<int, List<Message>> _messagesByCourtId = {};
  final Map<int, Court> _chattedCourts = {};
  final Map<int, String?> _lastMessages = {};
  bool _isLoading = false;
  int? _currentUserId; // lưu để tự reload sau khi gửi tin

  ChatViewModel(this._db);

  Map<int, List<Message>> get messagesByCourtId => _messagesByCourtId;
  Map<int, Court> get chattedCourts => _chattedCourts;
  bool get isLoading => _isLoading;

  List<Message> getMessages(int courtId) =>
      _messagesByCourtId[courtId] ?? [];

  String? getLastMessage(int courtId) => _lastMessages[courtId];

  // ─── Load ──────────────────────────────────────────────────────────────────

  /// Tải danh sách sân user đã chat
  Future<void> loadChattedCourts(int userId) async {
    _currentUserId = userId;
    _isLoading = true;
    notifyListeners();
    try {
      final rows = await _db.getChattedCourts(userId);
      _chattedCourts.clear();
      _lastMessages.clear();
      for (final row in rows) {
        final court = Court.fromMap(row);
        _chattedCourts[court.id] = court;
        _lastMessages[court.id] = row['last_message'] as String?;
      }
    } catch (e) {
      debugPrint('ChatViewModel.loadChattedCourts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải tin nhắn của một sân
  Future<void> loadMessages(int courtId, int userId) async {
    try {
      final messages = await _db.getMessagesByCourtAndUser(courtId, userId);
      _messagesByCourtId[courtId] = messages;
      notifyListeners();
    } catch (e) {
      debugPrint('ChatViewModel.loadMessages error: $e');
    }
  }

  // ─── Send ──────────────────────────────────────────────────────────────────

  /// Gửi tin nhắn và trigger auto-reply sau 1.5s
  Future<void> sendMessage(int courtId, int userId, String text) async {
    if (text.trim().isEmpty) return;

    // Tin nhắn từ user
    final userMsg = Message(
      id: 0,
      courtId: courtId,
      userId: userId,
      isFromUser: true,
      text: text.trim(),
      timestamp: DateTime.now().toIso8601String(),
    );
    final msgId = await _db.insertMessage(userMsg);
    final savedMsg = userMsg.copyWith(id: msgId);

    _messagesByCourtId[courtId] = [
      ...(_messagesByCourtId[courtId] ?? []),
      savedMsg,
    ];
    // Reload chat list ngay sau khi user gửi → tab Chat cập nhật
    if (_currentUserId != null) {
      await loadChattedCourts(_currentUserId!);
    } else {
      notifyListeners();
    }

    // Auto-reply sau 1.5s
    Timer(const Duration(milliseconds: 1500), () async {
      final replyText = _generateAutoReply(text);
      final replyMsg = Message(
        id: 0,
        courtId: courtId,
        userId: userId,
        isFromUser: false,
        text: replyText,
        timestamp: DateTime.now().toIso8601String(),
      );
      final replyId = await _db.insertMessage(replyMsg);
      final savedReply = replyMsg.copyWith(id: replyId);

      _messagesByCourtId[courtId] = [
        ...(_messagesByCourtId[courtId] ?? []),
        savedReply,
      ];
      // Reload lại để cập nhật last message
      if (_currentUserId != null) {
        await loadChattedCourts(_currentUserId!);
      } else {
        notifyListeners();
      }
    });
  }

  // ─── Auto-reply logic ──────────────────────────────────────────────────────

  /// Tạo tin nhắn tự động từ "chủ sân" dựa trên nội dung tin nhắn
  String _generateAutoReply(String userText) {
    final lower = userText.toLowerCase();
    if (lower.contains('giá') || lower.contains('tiền') || lower.contains('phí')) {
      return 'Giá sân off-peak từ 70k-130k/giờ, giờ vàng 17:00-21:00 từ 150k-230k/giờ. Bạn muốn đặt sân cho ngày nào ạ?';
    }
    if (lower.contains('vợt') || lower.contains('thuê')) {
      return 'Sân có cho thuê vợt 30k/chiếc và bóng 50k/thùng. Vui lòng chọn khi đặt sân nhé!';
    }
    if (lower.contains('giờ') || lower.contains('mở') || lower.contains('đóng')) {
      return 'Sân mở cửa từ 05:00 đến 23:00 mỗi ngày, kể cả cuối tuần và ngày lễ.';
    }
    if (lower.contains('huỷ') || lower.contains('cancel') || lower.contains('hoàn')) {
      return 'Chính sách huỷ: huỷ trước 24h được hoàn 100% tiền cọc. Huỷ trong vòng 24h không hoàn cọc.';
    }
    if (lower.contains('đỗ xe') || lower.contains('parking') || lower.contains('gửi xe')) {
      return 'Sân có bãi đỗ xe miễn phí cho khách đặt sân, đủ chỗ cho ô tô và xe máy.';
    }
    if (lower.contains('cảm ơn') || lower.contains('thanks') || lower.contains('ok')) {
      return 'Không có gì ạ! Chúc bạn thi đấu vui vẻ. Mọi thắc mắc cứ nhắn tin cho chúng tôi nhé!';
    }
    if (lower.contains('đặt') || lower.contains('book')) {
      return 'Bạn có thể đặt sân trực tiếp trên ứng dụng SportZone. Chọn ngày, giờ và xác nhận thanh toán cọc là xong!';
    }
    return 'Cảm ơn bạn đã liên hệ với SportZone! Chúng tôi sẽ phản hồi sớm nhất có thể. Để đặt sân nhanh, bạn có thể dùng tính năng đặt sân ngay trên app.';
  }
}
