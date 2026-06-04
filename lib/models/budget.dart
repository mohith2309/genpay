import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 1)
class Budget extends HiveObject {
  @HiveField(0)
  String categoryId;

  @HiveField(1)
  double amount;

  @HiveField(2)
  double spent;

  @HiveField(3)
  DateTime month;

  @HiveField(4)
  bool isAutopilot;

  Budget({
    required this.categoryId,
    required this.amount,
    this.spent = 0.0,
    required this.month,
    this.isAutopilot = false,
  });

  double get remaining => (amount - spent).clamp(0, double.infinity);
  double get percentage => amount > 0 ? (spent / amount).clamp(0, 1) : 0;
  bool get isOverBudget => spent > amount;

  Budget copyWith({
    String? categoryId,
    double? amount,
    double? spent,
    DateTime? month,
    bool? isAutopilot,
  }) {
    return Budget(
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      month: month ?? this.month,
      isAutopilot: isAutopilot ?? this.isAutopilot,
    );
  }
}
