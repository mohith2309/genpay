import 'package:hive/hive.dart';

part 'bank_account.g.dart';

@HiveType(typeId: 4)
class BankAccount extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String bankName;

  @HiveField(2)
  String accountLast4;

  @HiveField(3)
  String ifsc;

  @HiveField(4)
  double balance;

  /// 4 or 6 digit UPI PIN. In a real PSP this never leaves the NPCI common
  /// library; here it's stored locally for the simulated flow.
  @HiveField(5)
  String upiPin;

  @HiveField(6)
  bool isPrimary;

  @HiveField(7)
  String vpa;

  @HiveField(8)
  int colorValue;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountLast4,
    required this.ifsc,
    this.balance = 0.0,
    this.upiPin = '',
    this.isPrimary = false,
    required this.vpa,
    this.colorValue = 0xFF00D9FF,
  });

  bool get hasPin => upiPin.isNotEmpty;

  String get maskedAccount => '••••••$accountLast4';

  BankAccount copyWith({
    String? bankName,
    String? accountLast4,
    String? ifsc,
    double? balance,
    String? upiPin,
    bool? isPrimary,
    String? vpa,
    int? colorValue,
  }) {
    return BankAccount(
      id: id,
      bankName: bankName ?? this.bankName,
      accountLast4: accountLast4 ?? this.accountLast4,
      ifsc: ifsc ?? this.ifsc,
      balance: balance ?? this.balance,
      upiPin: upiPin ?? this.upiPin,
      isPrimary: isPrimary ?? this.isPrimary,
      vpa: vpa ?? this.vpa,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}
