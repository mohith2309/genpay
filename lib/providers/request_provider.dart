import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

enum RequestStatus { pending, paid, declined }

/// A UPI collect request — either incoming (someone asks you to pay) or
/// outgoing (you ask someone to pay you).
class MoneyRequest {
  final String id;
  final String name;
  final String vpa;
  final double amount;
  final String? note;
  final bool incoming;
  final DateTime createdAt;
  final RequestStatus status;

  const MoneyRequest({
    required this.id,
    required this.name,
    required this.vpa,
    required this.amount,
    required this.incoming,
    required this.createdAt,
    this.note,
    this.status = RequestStatus.pending,
  });

  MoneyRequest copyWith({RequestStatus? status}) => MoneyRequest(
        id: id,
        name: name,
        vpa: vpa,
        amount: amount,
        note: note,
        incoming: incoming,
        createdAt: createdAt,
        status: status ?? this.status,
      );
}

final requestsProvider =
    StateNotifierProvider<RequestNotifier, List<MoneyRequest>>(
        (ref) => RequestNotifier());

/// Incoming requests still awaiting action.
final pendingIncomingProvider = Provider<List<MoneyRequest>>((ref) {
  return ref
      .watch(requestsProvider)
      .where((r) => r.incoming && r.status == RequestStatus.pending)
      .toList();
});

class RequestNotifier extends StateNotifier<List<MoneyRequest>> {
  RequestNotifier() : super(_seed());

  static final _uuid = const Uuid();

  // A couple of demo incoming collect requests so the inbox isn't empty.
  static List<MoneyRequest> _seed() {
    final now = DateTime.now();
    return [
      MoneyRequest(
        id: 'seed1',
        name: 'Aarav (flatmate)',
        vpa: 'aarav@okhdfcbank',
        amount: 1200,
        note: 'Electricity split',
        incoming: true,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      MoneyRequest(
        id: 'seed2',
        name: 'Zomato',
        vpa: 'zomato@hdfcbank',
        amount: 449,
        note: 'Dinner order',
        incoming: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  void createOutgoing({
    required String name,
    required String vpa,
    required double amount,
    String? note,
  }) {
    state = [
      MoneyRequest(
        id: _uuid.v4(),
        name: name,
        vpa: vpa,
        amount: amount,
        note: note,
        incoming: false,
        createdAt: DateTime.now(),
      ),
      ...state,
    ];
  }

  void markPaid(String id) => _setStatus(id, RequestStatus.paid);
  void decline(String id) => _setStatus(id, RequestStatus.declined);

  void _setStatus(String id, RequestStatus status) {
    state = [
      for (final r in state) r.id == id ? r.copyWith(status: status) : r,
    ];
  }
}
