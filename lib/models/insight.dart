class Insight {
  final String title;
  final String description;
  final InsightType type;
  final double? value;
  final String? actionText;
  final DateTime generatedAt;

  Insight({
    required this.title,
    required this.description,
    required this.type,
    this.value,
    this.actionText,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();
}

enum InsightType {
  pattern,
  warning,
  encouragement,
  prediction,
  saving,
  emotional,
}

class FutureProjection {
  final double currentSpend;
  final double projectedTotal;
  final double dailyRate;
  final int daysRemaining;
  final String biggestCategory;
  final double potentialSaving;
  final String suggestion;

  FutureProjection({
    required this.currentSpend,
    required this.projectedTotal,
    required this.dailyRate,
    required this.daysRemaining,
    required this.biggestCategory,
    required this.potentialSaving,
    required this.suggestion,
  });
}

class DuplicateAlert {
  final String merchant;
  final int count;
  final double totalAmount;
  final String period;
  final List<DateTime> dates;

  DuplicateAlert({
    required this.merchant,
    required this.count,
    required this.totalAmount,
    required this.period,
    required this.dates,
  });
}

class MoodCorrelation {
  final String mood;
  final double averageSpend;
  final int transactionCount;
  final String topCategory;

  MoodCorrelation({
    required this.mood,
    required this.averageSpend,
    required this.transactionCount,
    required this.topCategory,
  });
}
