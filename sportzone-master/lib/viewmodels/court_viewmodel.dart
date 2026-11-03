import 'package:flutter/foundation.dart';
import '../models/court.dart';
import '../models/review.dart';
import '../services/firestore_service.dart';

/// ViewModel cho danh sách sân, tìm kiếm và lọc
class CourtViewModel extends ChangeNotifier {
  final FirestoreService _db;

  List<Court> _courts = [];
  List<Court> _filteredCourts = [];
  List<Court> _ownerCourts = [];
  String _selectedType = 'all';
  String _searchQuery = '';
  bool _isLoading = false;
  Court? _selectedCourt;
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;

  CourtViewModel(this._db);

  List<Court> get courts => _courts;
  List<Court> get filteredCourts => _filteredCourts;
  List<Court> get ownerCourts => _ownerCourts;
  String get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  Court? get selectedCourt => _selectedCourt;
  List<Review> get reviews => _reviews;
  bool get isLoadingReviews => _isLoadingReviews;

  // ─── Load ──────────────────────────────────────────────────────────────────

  /// Tải danh sách tất cả sân từ DB
  Future<void> loadCourts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _courts = await _db.getCourts();
      _applyFilter();
    } catch (e) {
      debugPrint('CourtViewModel.loadCourts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải danh sách sân của một Owner
  Future<void> loadOwnerCourts(int ownerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _ownerCourts = await _db.getCourtsByOwner(ownerId);
    } catch (e) {
      debugPrint('CourtViewModel.loadOwnerCourts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Thêm sân mới (Owner)
  Future<int> addCourt(Court court, int ownerId) async {
    final courtWithOwner = court.copyWith(ownerId: ownerId);
    final id = await _db.insertCourt(courtWithOwner);
    await loadCourts();
    await loadOwnerCourts(ownerId);
    return id;
  }

  /// Sửa thông tin sân (Owner)
  Future<void> updateCourt(Court court, int ownerId) async {
    await _db.updateCourt(court);
    await loadCourts();
    await loadOwnerCourts(ownerId);
    if (_selectedCourt?.id == court.id) {
      _selectedCourt = court;
    }
  }

  /// Xóa sân (Owner)
  Future<void> deleteCourt(int courtId, int ownerId) async {
    await _db.deleteCourt(courtId);
    await loadCourts();
    await loadOwnerCourts(ownerId);
    if (_selectedCourt?.id == courtId) {
      _selectedCourt = null;
    }
  }

  /// Tải thông tin một sân theo id
  Future<void> loadCourtById(int id) async {
    _selectedCourt = await _db.getCourtById(id);
    notifyListeners();
  }

  /// Tải danh sách reviews của sân
  Future<void> loadReviews(int courtId) async {
    _isLoadingReviews = true;
    notifyListeners();
    try {
      final maps = await _db.getReviewsByCourt(courtId);
      _reviews = maps.map((m) => Review.fromMap(m)).toList();
    } catch (e) {
      debugPrint('CourtViewModel.loadReviews error: $e');
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  // ─── Filter & Search ───────────────────────────────────────────────────────

  /// Lọc sân theo loại
  void filterByType(String type) {
    _selectedType = type;
    _applyFilter();
    notifyListeners();
  }

  /// Tìm kiếm theo từ khoá
  void search(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// Áp dụng cả filter loại và search query
  void _applyFilter() {
    _filteredCourts = _courts.where((c) {
      final matchType = _selectedType == 'all' || c.type == _selectedType;
      final matchSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.address.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchType && matchSearch;
    }).toList();
  }

  void clearSelectedCourt() {
    _selectedCourt = null;
    notifyListeners();
  }
}
