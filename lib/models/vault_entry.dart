class VaultEntry {
  final String id;
  final double amount;
  final String transactionId;
  final String merchant;
  final DateTime date;

  VaultEntry({
    required this.id,
    required this.amount,
    required this.transactionId,
    required this.merchant,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'transactionId': transactionId,
        'merchant': merchant,
        'date': date.toIso8601String(),
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
        id: json['id'],
        amount: (json['amount'] as num).toDouble(),
        transactionId: json['transactionId'],
        merchant: json['merchant'],
        date: DateTime.parse(json['date']),
      );
}

class VaultWithdrawal {
  final String id;
  final double amount;
  final String reason;
  final DateTime date;

  VaultWithdrawal({
    required this.id,
    required this.amount,
    required this.reason,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'reason': reason,
        'date': date.toIso8601String(),
      };

  factory VaultWithdrawal.fromJson(Map<String, dynamic> json) => VaultWithdrawal(
        id: json['id'],
        amount: (json['amount'] as num).toDouble(),
        reason: json['reason'],
        date: DateTime.parse(json['date']),
      );
}
