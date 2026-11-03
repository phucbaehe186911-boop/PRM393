import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/app_colors.dart';
import '../../services/vnpay_service.dart';

/// Màn hình thanh toán VNPay dùng InAppWebView
/// Dùng flutter_inappwebview thay vì webview_flutter vì có API bypass SSL cert
/// (cần thiết cho VNPay sandbox trên Android emulator)
class VnPayPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final void Function(VNPayResult) onResult;

  const VnPayPaymentPage({
    super.key,
    required this.paymentUrl,
    required this.onResult,
  });

  @override
  State<VnPayPaymentPage> createState() => _VnPayPaymentPageState();
}

class _VnPayPaymentPageState extends State<VnPayPaymentPage> {
  bool _isLoading = true;
  bool _handled = false; // tránh gọi callback 2 lần

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
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            if (!_handled) {
              _handled = true;
              Navigator.of(context).pop();
              widget.onResult(const VNPayResult(
                responseCode: '24',
                txnRef: '',
                amount: 0,
                bankCode: '',
                transactionNo: '',
                isSuccess: false,
              ));
            }
          },
        ),
        title: Row(
          children: [
            Image.network(
              'https://sandbox.vnpayment.vn/paymentv2/Images/favicon.ico',
              width: 20,
              height: 20,
              errorBuilder: (context, error, stack) =>
                  const Icon(Icons.payment, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thanh toán VNPay',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.paymentUrl),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              // User agent giống Chrome mobile để VNPay không block
              userAgent: 'Mozilla/5.0 (Linux; Android 14; Pixel 4) '
                  'AppleWebKit/537.36 (KHTML, like Gecko) '
                  'Chrome/120.0.0.0 Mobile Safari/537.36',
              // Cho phép load mixed content
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
            ),
            // Bypass SSL certificate errors — cần thiết cho VNPay sandbox
            // trên emulator vì System WebView thiếu intermediate CA
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);
              // Bắt return URL qua onLoadStart vì Android WebView
              // không gọi shouldOverrideUrlLoading cho HTTP redirect (302)
              final urlStr = url?.toString() ?? '';
              if (!_handled && VNPayService.isReturnUrl(urlStr)) {
                _handled = true;
                final uri = Uri.parse(urlStr);
                final result = VNPayService.parseResult(uri);
                if (mounted) {
                  Navigator.of(context).pop();
                  widget.onResult(result);
                }
              }
            },
            onLoadStop: (controller, url) => setState(() => _isLoading = false),
            // shouldOverrideUrlLoading: bắt direct navigation (không qua redirect)
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url?.toString() ?? '';
              if (!_handled && VNPayService.isReturnUrl(url)) {
                _handled = true;
                final uri = Uri.parse(url);
                final result = VNPayService.parseResult(uri);
                if (mounted) {
                  Navigator.of(context).pop();
                  widget.onResult(result);
                }
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onReceivedError: (controller, request, error) {
              debugPrint(
                'VNPay WebView error [${error.type}]: ${error.description}',
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
