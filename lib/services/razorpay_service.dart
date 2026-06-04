import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/constants.dart';

/// Result of a checkout attempt, normalized across success / failure / wallet.
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;
  final int? errorCode;
  final String? walletName;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
    this.errorCode,
    this.walletName,
  });
}

/// Wrapper over [Razorpay] that uses the GenPay backend for the secure parts.
///
/// Flow (the correct, secret-safe one):
///   1. [createOrder] → backend creates a Razorpay order with the Key Secret
///      (never shipped in the app) and returns `order_id` + publishable `key_id`.
///   2. [open] launches checkout bound to that `order_id`.
///   3. On success, [verifyPayment] sends the signature back to the backend,
///      which validates `HMAC_SHA256(order_id|payment_id, secret)`.
class RazorpayService {
  Razorpay? _razorpay;

  void Function(PaymentResult result)? onSuccess;
  void Function(PaymentResult result)? onError;
  void Function(PaymentResult result)? onExternalWallet;

  String? _orderKeyId; // key_id returned by the backend with the order

  String get _backendUrl {
    try {
      final v = dotenv.maybeGet('BACKEND_URL');
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return AppConstants.backendUrlFallback;
  }

  void init() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);
  }

  /// Asks the backend to create an order. Returns null if the backend is
  /// unreachable or rejects (e.g. invalid Razorpay keys).
  Future<({String orderId, int amountPaise, String keyId})?> createOrder(
    double amountRupees, {
    String? receipt,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_backendUrl/razorpay/order'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'amount': amountRupees, 'receipt': receipt}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['order_id'] == null) return null;
      _orderKeyId = data['key_id'] as String?;
      return (
        orderId: data['order_id'] as String,
        amountPaise: (data['amount'] as num).toInt(),
        keyId: data['key_id'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Verifies the checkout signature with the backend. Only a `true` here
  /// should unlock premium — never trust the client-side success alone.
  Future<bool> verifyPayment(PaymentResult r) async {
    if (r.orderId == null || r.paymentId == null || r.signature == null) {
      return false;
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_backendUrl/razorpay/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'order_id': r.orderId,
              'payment_id': r.paymentId,
              'signature': r.signature,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return false;
      return (jsonDecode(res.body) as Map<String, dynamic>)['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse r) {
    onSuccess?.call(PaymentResult(
      success: true,
      paymentId: r.paymentId,
      orderId: r.orderId,
      signature: r.signature,
    ));
  }

  void _onPaymentError(PaymentFailureResponse r) {
    onError?.call(PaymentResult(
      success: false,
      errorCode: r.code,
      errorMessage: r.message ?? 'Payment failed',
    ));
  }

  void _onWallet(ExternalWalletResponse r) {
    onExternalWallet?.call(PaymentResult(
      success: false,
      walletName: r.walletName,
    ));
  }

  /// Opens the Razorpay checkout sheet bound to a backend-created [orderId].
  void open({
    required String orderId,
    required double amount,
    required String description,
    String? payeeName,
    String? vpa,
    String? contact,
    String? email,
  }) {
    final options = <String, dynamic>{
      'key': _orderKeyId ?? AppConstants.razorpayTestKey,
      'order_id': orderId,
      'amount': (amount * 100).round(),
      'currency': 'INR',
      'name': payeeName?.isNotEmpty == true ? payeeName : AppConstants.merchantName,
      'description': description,
      'theme': {'color': '#6366F1'},
      'prefill': {
        if (contact != null && contact.isNotEmpty) 'contact': contact,
        if (email != null && email.isNotEmpty) 'email': email,
        if (vpa != null && vpa.isNotEmpty) 'vpa': vpa,
        'method': 'upi',
      },
      'external': {
        'wallets': ['paytm'],
      },
    };
    _razorpay?.open(options);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
