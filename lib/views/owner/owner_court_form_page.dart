import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/court.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/court_viewmodel.dart';

/// Form Thêm hoặc Sửa sân thể thao dành cho Chủ sân (Owner)
class OwnerCourtFormPage extends StatefulWidget {
  final int? courtId; // null = Thêm mới, có giá trị = Sửa

  const OwnerCourtFormPage({super.key, this.courtId});

  @override
  State<OwnerCourtFormPage> createState() => _OwnerCourtFormPageState();
}

class _OwnerCourtFormPageState extends State<OwnerCourtFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _peakPriceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  String _selectedType = 'pickleball';
  double _lat = 21.0285;
  double _lng = 105.8542;
  bool _isLoading = false;
  Court? _existingCourt;

  // Gợi ý ảnh mẫu đẹp cho từng môn thể thao
  static const Map<String, List<String>> _sampleImages = {
    'pickleball': [
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800',
      'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=800',
    ],
    'badminton': [
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
      'https://images.unsplash.com/photo-1544473244-3ae36ea44df4?w=800',
    ],
    'football': [
      'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=800',
      'https://images.unsplash.com/photo-1489944440615-453fc2b6a9a9?w=800',
    ],
    'tennis': [
      'https://images.unsplash.com/photo-1622279457486-62dcc4a431d6?w=800',
      'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.courtId != null) {
      _loadCourtForEdit(widget.courtId!);
    } else {
      // Gợi ý ảnh mặc định
      _imageCtrl.text = _sampleImages['pickleball']!.first;
      _priceCtrl.text = '80000';
      _peakPriceCtrl.text = '160000';
    }
  }

  void _loadCourtForEdit(int id) {
    final courtVm = context.read<CourtViewModel>();
    final court = courtVm.ownerCourts.where((c) => c.id == id).firstOrNull ??
        courtVm.courts.where((c) => c.id == id).firstOrNull;

    if (court != null) {
      _existingCourt = court;
      _nameCtrl.text = court.name;
      _selectedType = court.type;
      _addressCtrl.text = court.address;
      _priceCtrl.text = court.pricePerHour.toInt().toString();
      _peakPriceCtrl.text = court.peakPricePerHour.toInt().toString();
      _descCtrl.text = court.description ?? '';
      _imageCtrl.text = court.images.isNotEmpty ? court.images.first : '';
      _lat = court.lat;
      _lng = court.lng;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _peakPriceCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _useSampleImage() {
    final samples = _sampleImages[_selectedType] ?? [];
    if (samples.isNotEmpty) {
      setState(() {
        _imageCtrl.text = samples.first;
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthViewModel>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final courtVm = context.read<CourtViewModel>();
      final price = double.tryParse(_priceCtrl.text.trim()) ?? 80000.0;
      final peakPrice = double.tryParse(_peakPriceCtrl.text.trim()) ?? 160000.0;
      final images = _imageCtrl.text.trim().isNotEmpty
          ? [_imageCtrl.text.trim()]
          : (_sampleImages[_selectedType] ?? []);

      if (widget.courtId == null) {
        // Thêm mới
        final newCourt = Court(
          id: 0,
          name: _nameCtrl.text.trim(),
          type: _selectedType,
          address: _addressCtrl.text.trim(),
          lat: _lat,
          lng: _lng,
          pricePerHour: price,
          peakPricePerHour: peakPrice,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          images: images,
          rating: 5.0,
          reviewCount: 0,
          ownerId: user.id,
        );
        await courtVm.addCourt(newCourt, user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm sân mới thành công! Đã tự động tạo lịch đặt 7 ngày.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        // Sửa sân
        final updated = _existingCourt!.copyWith(
          name: _nameCtrl.text.trim(),
          type: _selectedType,
          address: _addressCtrl.text.trim(),
          pricePerHour: price,
          peakPricePerHour: peakPrice,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          images: images,
          ownerId: _existingCourt!.ownerId ?? user.id,
        );
        await courtVm.updateCourt(updated, user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin sân thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.courtId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isEdit ? 'Chỉnh sửa thông tin sân' : 'Thêm sân thể thao mới',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Tên sân ───────────────────────────────────────
              _fieldLabel('Tên cụm sân / trung tâm *'),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDec('Ví dụ: Cụm sân Pickleball Cầu Giấy Arena'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tên sân' : null,
              ),
              const SizedBox(height: 14),

              // ── Loại sân ──────────────────────────────────────
              _fieldLabel('Môn thể thao *'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'pickleball', child: Text('🏓 Pickleball')),
                      DropdownMenuItem(
                          value: 'badminton', child: Text('🏸 Cầu lông')),
                      DropdownMenuItem(
                          value: 'football', child: Text('⚽ Bóng đá')),
                      DropdownMenuItem(
                          value: 'tennis', child: Text('🎾 Tennis')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                          _useSampleImage();
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Địa chỉ ───────────────────────────────────────
              _fieldLabel('Địa chỉ chi tiết *'),
              TextFormField(
                controller: _addressCtrl,
                decoration: _inputDec('Số nhà, tên đường, quận/huyện, thành phố'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
              ),
              const SizedBox(height: 14),

              // ── Giá giờ ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Giá thường (VNĐ/h) *'),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec('80000'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nhập giá thường'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Giờ cao điểm (17-21h) *'),
                        TextFormField(
                          controller: _peakPriceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: _inputDec('160000'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nhập giá cao điểm'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Ảnh sân ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldLabel('Link ảnh đại diện sân (URL)'),
                  TextButton.icon(
                    onPressed: _useSampleImage,
                    icon: const Icon(Icons.auto_awesome, size: 14),
                    label: const Text('Dùng ảnh mẫu đẹp',
                        style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _imageCtrl,
                decoration: _inputDec('https://images.unsplash.com/...'),
              ),
              const SizedBox(height: 14),

              // ── Mô tả ─────────────────────────────────────────
              _fieldLabel('Mô tả tiện ích, trang thiết bị'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDec(
                    'Ví dụ: Thảm tiêu chuẩn thi đấu, máy lạnh, bãi đỗ xe ô tô miễn phí, quầy nước...'),
              ),
              const SizedBox(height: 24),

              // ── Nút Lưu ───────────────────────────────────────
              ElevatedButton(
                onPressed: _isLoading ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        isEdit ? 'Lưu thay đổi' : 'Tạo sân và mở đặt ngay',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: AppColors.textDisabled, fontSize: 13),
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
      );
}

