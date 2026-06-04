import 'dart:convert';
import 'package:http/http.dart' as http;

class RazorpayAutomationService {
  final String keyId;
  final String keySecret;

  RazorpayAutomationService({
    required this.keyId,
    required this.keySecret,
  });

  bool get _hasValidKeys =>
      keyId.isNotEmpty &&
      keySecret.isNotEmpty &&
      keyId != 'your_key_id' &&
      keySecret != 'your_key_secret' &&
      !keyId.startsWith('rzp_test');

  String get _authHeader {
    final bytes = utf8.encode('$keyId:$keySecret');
    return 'Basic ${base64Encode(bytes)}';
  }

  /// Fetches recurring subscriptions/mandates from Razorpay API.
  /// Falls back to simulated data for demo purposes when keys are test/placeholder.
  Future<List<Map<String, dynamic>>> fetchSubscriptions() async {
    if (!_hasValidKeys) {
      // Mock data representing subscriptions fetched from Razorpay
      return [
        {
          'id': 'sub_Nfx123456789',
          'entity': 'subscription',
          'plan_id': 'plan_Nfx001',
          'status': 'active',
          'current_start': DateTime.now().subtract(const Duration(days: 15)).millisecondsSinceEpoch ~/ 1000,
          'current_end': DateTime.now().add(const Duration(days: 15)).millisecondsSinceEpoch ~/ 1000,
          'charge_at': DateTime.now().add(const Duration(days: 15)).millisecondsSinceEpoch ~/ 1000,
          'notes': {'merchant': 'Netflix', 'type': 'Premium Plan'},
          'amount': 64900, // in paise
        },
        {
          'id': 'sub_Nfx987654321',
          'entity': 'subscription',
          'plan_id': 'plan_Nfx002',
          'status': 'active',
          'current_start': DateTime.now().subtract(const Duration(days: 10)).millisecondsSinceEpoch ~/ 1000,
          'current_end': DateTime.now().add(const Duration(days: 20)).millisecondsSinceEpoch ~/ 1000,
          'charge_at': DateTime.now().add(const Duration(days: 20)).millisecondsSinceEpoch ~/ 1000,
          'notes': {'merchant': 'Netflix', 'type': 'Standard Plan'},
          'amount': 49900,
        },
        {
          'id': 'sub_Spt012345678',
          'entity': 'subscription',
          'plan_id': 'plan_Spt001',
          'status': 'active',
          'current_start': DateTime.now().subtract(const Duration(days: 5)).millisecondsSinceEpoch ~/ 1000,
          'current_end': DateTime.now().add(const Duration(days: 25)).millisecondsSinceEpoch ~/ 1000,
          'charge_at': DateTime.now().add(const Duration(days: 25)).millisecondsSinceEpoch ~/ 1000,
          'notes': {'merchant': 'Spotify', 'type': 'Premium Duo'},
          'amount': 17900,
        },
        {
          'id': 'sub_Ytb345678901',
          'entity': 'subscription',
          'plan_id': 'plan_Ytb001',
          'status': 'active',
          'current_start': DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch ~/ 1000,
          'current_end': DateTime.now().add(const Duration(days: 28)).millisecondsSinceEpoch ~/ 1000,
          'charge_at': DateTime.now().add(const Duration(days: 28)).millisecondsSinceEpoch ~/ 1000,
          'notes': {'merchant': 'YouTube Premium', 'type': 'Family Plan'},
          'amount': 18900,
        },
      ];
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.razorpay.com/v1/subscriptions'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List?;
        if (items != null) {
          return items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Cancels a subscription via POST /v1/subscriptions/{id}/cancel
  Future<bool> cancelSubscription(String subscriptionId) async {
    if (!_hasValidKeys) {
      // Mock successful cancel
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.razorpay.com/v1/subscriptions/$subscriptionId/cancel'),
        headers: {
          'Authorization': _authHeader,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cancel_at_cycle_end': 0, // Cancel immediately
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }
}
