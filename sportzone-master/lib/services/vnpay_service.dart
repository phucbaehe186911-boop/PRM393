import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

/// VNPay Sandbox payment service
/// Docs: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html
class VNPayService {
  VNPayService._();

  static const String _tmnCode = 'TCL67R9U';
  static const String _hashSecret = 'XHYAHMLOEETEUEYQOLSJOCDSIPADOSJP';
  static const String _baseUrl =
      'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String returnUrl =
      'https://prm393-sportzone.vercel.app/payment-return';

  /// Tạo URL thanh toán VNPay với chữ ký HMAC-SHA512
  static String buildPaymentUrl({
    required int bookingId,
    required double amount,
    required String orderInfo,
  }) {
    final now = DateTime.now();
    final createDate = DateFormat('yyyyMMddHHmmss').format(now);
    final txnRef = '${bookingId}_${now.millisecondsSinceEpoch}';

    // Tất cả params (sorted theo key để sign)
    final params = <String, String>{
      'vnp_Amount': (amount * 100).toInt().toString(),
      'vnp_Command': 'pay',
      'vnp_CreateDate': createDate,
      'vnp_CurrCode': 'VND',
      'vnp_IpAddr': '10.0.2.2',
      'vnp_Locale': 'vn',
      'vnp_OrderInfo': orderInfo,
      'vnp_OrderType': '250000',
      'vnp_ReturnUrl': returnUrl,
      'vnp_TmnCode': _tmnCode,
      'vnp_TxnRef': txnRef,
      'vnp_Version': '2.1.0',
    };

    // Sort by key (bắt buộc theo spec VNPay)
    final sortedKeys = params.keys.toList()..sort();

    // Build query string để sign (dùng encodeQueryComponent để giữ uppercase hex)
    final signData = sortedKeys
        .map((k) => '$k=${Uri.encodeQueryComponent(params[k]!)}')
        .join('&');

    // HMAC-SHA512
    final hmac = Hmac(sha512, utf8.encode(_hashSecret));
    final secureHash = hmac.convert(utf8.encode(signData)).toString();

    return '$_baseUrl?$signData&vnp_SecureHash=$secureHash';
  }

  /// Kiểm tra URL có phải return URL từ VNPay không
  static bool isReturnUrl(String url) =>
      url.startsWith(returnUrl);

  /// Parse kết quả từ return URL
  static VNPayResult parseResult(Uri uri) {
    final code = uri.queryParameters['vnp_ResponseCode'] ?? '';
    final txnRef = uri.queryParameters['vnp_TxnRef'] ?? '';
    final amount = int.tryParse(
            uri.queryParameters['vnp_Amount'] ?? '0') ??
        0;
    final bankCode = uri.queryParameters['vnp_BankCode'] ?? '';
    final transactionNo = uri.queryParameters['vnp_TransactionNo'] ?? '';

    return VNPayResult(
      responseCode: code,
      txnRef: txnRef,
      amount: amount / 100,
      bankCode: bankCode,
      transactionNo: transactionNo,
      isSuccess: code == '00',
    );
  }
}

/// Kết quả trả về từ VNPay sau khi thanh toán
class VNPayResult {
  final String responseCode;
  final String txnRef;
  final double amount;
  final String bankCode;
  final String transactionNo;
  final bool isSuccess;

  const VNPayResult({
    required this.responseCode,
    required this.txnRef,
    required this.amount,
    required this.bankCode,
    required this.transactionNo,
    required this.isSuccess,
  });

  String get message {
    switch (responseCode) {
      case '00':
        return 'Thanh toán thành công';
      case '07':
        return 'Giao dịch bị nghi ngờ gian lận';
      case '09':
        return 'Thẻ/Tài khoản chưa đăng ký dịch vụ Internet Banking';
      case '10':
        return 'Xác thực thông tin thẻ/tài khoản quá 3 lần';
      case '11':
        return 'Đã hết hạn chờ thanh toán';
      case '12':
        return 'Thẻ/Tài khoản bị khóa';
      case '24':
        return 'Giao dịch bị hủy';
      case '51':
        return 'Tài khoản không đủ số dư';
      case '65':
        return 'Vượt quá hạn mức giao dịch trong ngày';
      case '75':
        return 'Ngân hàng thanh toán đang bảo trì';
      default:
        return 'Giao dịch thất bại (code: $responseCode)';
    }
  }
}
