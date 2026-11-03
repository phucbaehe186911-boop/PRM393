/// Tất cả strings tiếng Việt dùng trong SportZone
class AppStrings {
  AppStrings._();

  static const String appName = 'SportZone';
  static const String appTagline = 'Đặt sân thể thao dễ dàng';

  // Auth
  static const String loginTitle = 'Đăng nhập';
  static const String registerTitle = 'Tạo tài khoản';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Mật khẩu';
  static const String nameLabel = 'Họ và tên';
  static const String phoneLabel = 'Số điện thoại';
  static const String confirmPasswordLabel = 'Xác nhận mật khẩu';
  static const String loginButton = 'Đăng nhập';
  static const String registerButton = 'Đăng ký';
  static const String logoutButton = 'Đăng xuất';
  static const String noAccount = 'Chưa có tài khoản? Đăng ký';
  static const String hasAccount = 'Đã có tài khoản? Đăng nhập';
  static const String loginError = 'Email hoặc mật khẩu không đúng';
  static const String emailExistsError = 'Email đã được sử dụng';
  static const String passwordTooShort = 'Mật khẩu phải có ít nhất 8 ký tự';
  static const String passwordMismatch = 'Mật khẩu xác nhận không khớp';
  static const String invalidEmail = 'Email không hợp lệ';
  static const String fieldRequired = 'Vui lòng nhập thông tin này';

  // Navigation
  static const String tabCourts = 'Sân';
  static const String tabMap = 'Bản đồ';
  static const String tabChat = 'Chat';
  static const String tabNotifications = 'Thông báo';
  static const String tabProfile = 'Hồ sơ';

  // Courts
  static const String allTypes = 'Tất cả';
  static const String badminton = 'Cầu lông';
  static const String pickleball = 'Pickleball';
  static const String football = 'Bóng đá';
  static const String tennis = 'Tennis';
  static const String searchHint = 'Tìm kiếm sân...';
  static const String priceFromLabel = 'Từ';
  static const String perHour = '/giờ';
  static const String offPeak = 'Giờ thường';
  static const String peak = 'Giờ vàng';
  static const String peakHours = '17:00 - 21:00';
  static const String noCourtsFound = 'Không tìm thấy sân nào phù hợp';

  // Booking
  static const String bookingTitle = 'Đặt sân';
  static const String selectDate = 'Chọn ngày';
  static const String selectSlot = 'Chọn giờ';
  static const String addons = 'Dịch vụ thêm';
  static const String addonRacket = 'Thuê vợt';
  static const String addonBall = 'Nhặt bóng';
  static const String addonWater = 'Nước suối';
  static const String totalPrice = 'Tổng tiền';
  static const String depositLabel = 'Tiền cọc 50%';
  static const String confirmBooking = 'XÁC NHẬN ĐẶT SÂN';
  static const String bookingSuccess = 'Đặt sân thành công!';
  static const String bookingCancelled = 'Huỷ sân thành công';
  static const String cancelBooking = 'Huỷ đặt sân';
  static const String cancelConfirm = 'Bạn có chắc chắn muốn huỷ không?';
  static const String myBookings = 'Lịch đặt của tôi';
  static const String upcoming = 'Sắp tới';
  static const String completed = 'Đã chơi';
  static const String cancelled = 'Đã huỷ';

  // Reviews
  static const String writeReview = 'Đánh giá';
  static const String reviewed = 'Đã đánh giá';
  static const String reviewPlaceholder = 'Nhận xét của bạn (tuỳ chọn)';
  static const String submitReview = 'Gửi đánh giá';

  // Map
  static const String mapTitle = 'Bản đồ sân';
  static const String locationPermissionDenied =
      'Ứng dụng cần quyền truy cập vị trí để hiển thị sân gần bạn.';

  // Chat
  static const String chatTitle = 'Chat';
  static const String noChats = 'Bạn chưa nhắn tin với sân nào';
  static const String messageHint = 'Nhập tin nhắn...';
  static const String contactOwner = 'Liên hệ';

  // Notifications
  static const String notificationTitle = 'Thông báo';
  static const String noNotifications = 'Chưa có thông báo nào';
  static const String markAllRead = 'Đánh dấu tất cả đã đọc';

  // Profile
  static const String profileTitle = 'Hồ sơ';
  static const String saveChanges = 'Lưu thay đổi';
  static const String changeAvatar = 'Đổi ảnh';
  static const String logoutConfirm = 'Bạn có chắc chắn muốn đăng xuất?';
}
