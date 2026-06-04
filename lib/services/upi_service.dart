/// Parsed contents of a UPI QR / deep-link (`upi://pay?...`).
class UpiPaymentRequest {
  final String payeeVpa;
  final String? payeeName;
  final double? amount;
  final String? note;

  const UpiPaymentRequest({
    required this.payeeVpa,
    this.payeeName,
    this.amount,
    this.note,
  });

  bool get isValid => payeeVpa.contains('@');
}

class UpiService {
  /// Parses a scanned QR payload into a [UpiPaymentRequest].
  ///
  /// Accepts both full `upi://pay?pa=...` links and a bare VPA string.
  static UpiPaymentRequest? parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    // Bare VPA, e.g. "merchant@okicici"
    if (!value.contains('://') && value.contains('@') && !value.contains(' ')) {
      return UpiPaymentRequest(payeeVpa: value.toLowerCase());
    }

    Uri? uri;
    try {
      uri = Uri.parse(value);
    } catch (_) {
      return null;
    }

    if (uri.scheme.toLowerCase() != 'upi') return null;

    final params = uri.queryParameters;
    final pa = params['pa'];
    if (pa == null || !pa.contains('@')) return null;

    return UpiPaymentRequest(
      payeeVpa: pa.toLowerCase(),
      payeeName: params['pn'],
      amount: double.tryParse(params['am'] ?? ''),
      note: params['tn'],
    );
  }

  /// Builds a `upi://pay` deep link from explicit fields.
  static String buildUri({
    required String payeeVpa,
    String? payeeName,
    double? amount,
    String? note,
  }) {
    final buffer = StringBuffer('upi://pay?pa=${Uri.encodeComponent(payeeVpa)}');
    buffer.write('&pn=${Uri.encodeComponent(payeeName ?? payeeVpa)}');
    if (amount != null && amount > 0) {
      buffer.write('&am=${Uri.encodeComponent(amount.toStringAsFixed(2))}');
    }
    buffer.write('&cu=INR');
    if (note != null && note.isNotEmpty) {
      buffer.write('&tn=${Uri.encodeComponent(note)}');
    }
    return buffer.toString();
  }

  static bool isValidVpa(String vpa) {
    return RegExp(r'^[a-zA-Z0-9._\-]{2,}@[a-zA-Z][a-zA-Z0-9]+$').hasMatch(vpa.trim());
  }
}
