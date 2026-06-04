import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class SmsParserService {
  final SmsQuery _query = SmsQuery();
  final _uuid = const Uuid();

  // Request SMS permission
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  // Main entry: read and parse all UPI SMS
  Future<List<Transaction>> fetchAndParseUpiSms({int limit = 200}) async {
    final granted = await hasPermission();
    if (!granted) return [];

    try {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: limit,
      );

      final upiMessages = messages.where(_isUpiSms).toList();
      final transactions = <Transaction>[];

      for (final sms in upiMessages) {
        final txn = _parseSms(sms);
        if (txn != null) {
          transactions.add(txn);
        }
      }

      // Sort by date descending
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    } catch (e) {
      return [];
    }
  }

  bool _isUpiSms(SmsMessage sms) {
    final body = (sms.body ?? '').toLowerCase();

    // Check for bank/payment keywords
    final hasUpiKeyword = AppConstants.upiSmsKeywords.any((kw) => body.contains(kw));
    if (!hasUpiKeyword) return false;

    // Must mention debit (expense) or credit
    final hasDebit = body.contains('debit') || body.contains('debited') || body.contains('paid');
    final hasCredit = body.contains('credit') || body.contains('credited') || body.contains('received');

    return hasDebit || hasCredit;
  }

  Transaction? _parseSms(SmsMessage sms) {
    final body = sms.body ?? '';
    if (body.isEmpty) return null;

    // Extract amount
    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    // Extract merchant
    final merchant = _extractMerchant(body);

    // Extract date
    final date = _extractDate(sms, body);

    // Extract payment method
    final paymentMethod = _extractPaymentMethod(body, sms.sender ?? '');

    // Determine category from merchant name
    final category = _categorizeByKeyword(merchant);

    // Extract UPI-specific data
    final upiId = _extractVpa(body);
    final upiApp = _detectUpiApp(body, sms.sender ?? '');

    // Calculate vault roundup
    final vaultSaved = AppUtils.calculateRoundup(amount);

    return Transaction(
      id: _uuid.v4(),
      amount: amount,
      merchant: merchant,
      category: category,
      date: date,
      isSilent: false,
      isRecurring: false,
      fromSms: true,
      isApproved: false,
      vaultSaved: vaultSaved,
      paymentMethod: paymentMethod,
      isEmotionalSpend: false,
      upiId: upiId,
      upiApp: upiApp,
    );
  }

  double? _extractAmount(String body) {
    for (final pattern in AppConstants.upiAmountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final raw = match.group(1);
        if (raw != null) {
          final amount = AppUtils.cleanAmountString(raw);
          if (amount > 0) return amount;
        }
      }
    }
    return null;
  }

  String _extractMerchant(String body) {
    // Pattern: "to <merchant> on/via/ref"
    final toPattern = RegExp(
      r"(?:to|To|TO)\s+([A-Za-z0-9\s&\-.']+?)(?:\s+on|\s+via|\s+Ref|\s+ref|\s+VPA|\.|$)",
    );
    var match = toPattern.firstMatch(body);
    if (match != null) {
      final name = match.group(1)?.trim();
      if (name != null && name.length > 2 && name.length < 50) {
        return _cleanMerchantName(name);
      }
    }

    // Pattern: "at <merchant>"
    final atPattern = RegExp(r'(?:at|At|AT)\s+([A-Za-z0-9\s&\-\.]+?)(?:\s+on|\s+via|\.|$)');
    match = atPattern.firstMatch(body);
    if (match != null) {
      final name = match.group(1)?.trim();
      if (name != null && name.length > 2 && name.length < 50) {
        return _cleanMerchantName(name);
      }
    }

    // Pattern: VPA like merchant@okicici
    final vpaPattern = RegExp(r'([a-zA-Z0-9._\-]+@[a-zA-Z]+)');
    match = vpaPattern.firstMatch(body);
    if (match != null) {
      return AppUtils.parseMerchantFromVpa(match.group(1) ?? 'Unknown');
    }

    // Fallback: use known merchants from body
    for (final entry in AppConstants.merchantCategoryMap.entries) {
      if (body.toLowerCase().contains(entry.key)) {
        return _cleanMerchantName(entry.key);
      }
    }

    return 'UPI Payment';
  }

  String _cleanMerchantName(String raw) {
    return raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .split(' ')
        .map((w) {
          if (w.isEmpty) return '';
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ')
        .trim();
  }

  DateTime _extractDate(SmsMessage sms, String body) {
    // Try to parse from SMS date field
    if (sms.date != null) {
      return sms.date!;
    }

    // Try to find date in body
    final datePatterns = [
      RegExp(r'(\d{2}[-/]\d{2}[-/]\d{2,4})'),
      RegExp(r"(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s*[-']?\s*\d{2,4})", caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        try {
          final dateStr = match.group(1) ?? '';
          // Basic parsing - fallback to today
          return DateTime.tryParse(dateStr) ?? DateTime.now();
        } catch (_) {}
      }
    }

    return DateTime.now();
  }

  String _extractPaymentMethod(String body, String sender) {
    final lower = body.toLowerCase();
    final senderLower = sender.toLowerCase();

    if (lower.contains('upi') || lower.contains('gpay') ||
        lower.contains('phonepe') || lower.contains('paytm') ||
        lower.contains('bhim')) {
      return 'UPI';
    }
    if (lower.contains('card') || lower.contains('credit') && lower.contains('card') ||
        lower.contains('debit') && lower.contains('card')) {
      return 'Card';
    }
    if (lower.contains('neft') || lower.contains('rtgs') || lower.contains('imps')) {
      return 'NetBanking';
    }
    if (lower.contains('wallet') || lower.contains('paytm')) {
      return 'Wallet';
    }

    // Check sender
    for (final bank in AppConstants.bankSmsKeywords.entries) {
      if (bank.value.any((k) => senderLower.contains(k))) {
        return 'UPI';
      }
    }

    return 'UPI';
  }

  String? _extractVpa(String body) {
    // VPA pattern: something@handle (e.g., merchant@ybl, user@okicici)
    final vpaPattern = RegExp(r'([a-zA-Z0-9._\-]+@[a-zA-Z][a-zA-Z0-9]+)');
    final match = vpaPattern.firstMatch(body);
    if (match != null) {
      final vpa = match.group(1) ?? '';
      // Filter out email addresses by excluding common email domains
      if (!vpa.contains('.com') && !vpa.contains('.in') && vpa.length < 40) {
        return vpa.toLowerCase();
      }
    }
    return null;
  }

  String? _detectUpiApp(String body, String sender) {
    final lower = body.toLowerCase();
    final senderLower = sender.toLowerCase();
    final combined = '$lower $senderLower';

    for (final entry in AppConstants.upiAppKeywords.entries) {
      for (final kw in entry.value) {
        if (combined.contains(kw.toLowerCase())) {
          return entry.key;
        }
      }
    }
    // Default: if it's a UPI transaction, mark as Other UPI
    if (lower.contains('upi')) return 'Other UPI';
    return null;
  }

  String _categorizeByKeyword(String merchant) {
    final lower = merchant.toLowerCase();
    for (final entry in AppConstants.merchantCategoryMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Other';
  }
}
