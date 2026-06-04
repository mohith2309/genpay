import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 0)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String merchant;

  @HiveField(3)
  String category;

  @HiveField(4)
  String? subcategory;

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  bool isSilent;

  @HiveField(7)
  String? mood;

  @HiveField(8)
  bool isRecurring;

  @HiveField(9)
  String? note;

  @HiveField(10)
  bool fromSms;

  @HiveField(11)
  bool isApproved;

  @HiveField(12)
  double vaultSaved;

  @HiveField(13)
  String paymentMethod;

  @HiveField(14)
  bool isEmotionalSpend;

  @HiveField(15)
  String? upiId;

  @HiveField(16)
  String? upiApp;

  Transaction({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.category,
    this.subcategory,
    required this.date,
    this.isSilent = false,
    this.mood,
    this.isRecurring = false,
    this.note,
    this.fromSms = false,
    this.isApproved = true,
    this.vaultSaved = 0.0,
    this.paymentMethod = 'UPI',
    this.isEmotionalSpend = false,
    this.upiId,
    this.upiApp,
  });

  Transaction copyWith({
    String? id,
    double? amount,
    String? merchant,
    String? category,
    String? subcategory,
    DateTime? date,
    bool? isSilent,
    String? mood,
    bool? isRecurring,
    String? note,
    bool? fromSms,
    bool? isApproved,
    double? vaultSaved,
    String? paymentMethod,
    bool? isEmotionalSpend,
    String? upiId,
    String? upiApp,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      date: date ?? this.date,
      isSilent: isSilent ?? this.isSilent,
      mood: mood ?? this.mood,
      isRecurring: isRecurring ?? this.isRecurring,
      note: note ?? this.note,
      fromSms: fromSms ?? this.fromSms,
      isApproved: isApproved ?? this.isApproved,
      vaultSaved: vaultSaved ?? this.vaultSaved,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isEmotionalSpend: isEmotionalSpend ?? this.isEmotionalSpend,
      upiId: upiId ?? this.upiId,
      upiApp: upiApp ?? this.upiApp,
    );
  }

  @override
  String toString() => 'Transaction($id, $merchant, $amount, $category)';
}
