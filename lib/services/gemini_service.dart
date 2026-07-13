import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/transaction.dart';
import '../core/constants.dart';

class GeminiCategorizationResult {
  final String category;
  final String subcategory;
  final bool isEmotional;
  final String suggestion;

  GeminiCategorizationResult({
    required this.category,
    required this.subcategory,
    required this.isEmotional,
    required this.suggestion,
  });
}

class GeminiInsightResult {
  final List<String> patterns;
  final List<String> predictions;
  final List<String> tips;
  final String moodCorrelation;
  final String biggestWaste;

  GeminiInsightResult({
    required this.patterns,
    required this.predictions,
    required this.tips,
    required this.moodCorrelation,
    required this.biggestWaste,
  });
}

class GeminiService {
  static const int _dailyLimit = AppConstants.geminiDailyLimit;
  static const String _countKey = 'gemini_count';
  static const String _dateKey = 'gemini_date';

  Box? _cacheBox;

  Future<void> _initCache() async {
    _cacheBox ??= await Hive.openBox(AppConstants.geminiCacheBox);
  }

  // AI now runs through the GenPay backend, which proxies to NVIDIA NIM and
  // keeps the API key server-side. Override the URL with BACKEND_URL in .env.
  String get _backendUrl {
    try {
      final v = dotenv.maybeGet('BACKEND_URL');
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return AppConstants.backendUrlFallback;
  }

  bool get _hasApiKey => _backendUrl.isNotEmpty;

  // Privacy mode (offline AI) disables every cloud call.
  Future<bool> _isPrivacyMode() async {
    try {
      final box = await Hive.openBox(AppConstants.settingsBox);
      return box.get('privacy_mode', defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkRateLimit() async {
    await _initCache();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _cacheBox!.get(_dateKey, defaultValue: '');
    if (storedDate != today) {
      await _cacheBox!.put(_dateKey, today);
      await _cacheBox!.put(_countKey, 0);
      return true;
    }
    final count = _cacheBox!.get(_countKey, defaultValue: 0) as int;
    return count < _dailyLimit;
  }

  Future<void> _incrementCount() async {
    await _initCache();
    final count = _cacheBox!.get(_countKey, defaultValue: 0) as int;
    await _cacheBox!.put(_countKey, count + 1);
  }

  /// Calls the GenPay backend, which proxies to NVIDIA NIM. Returns null on
  /// privacy mode, rate-limit, network error, or non-200 — callers then fall
  /// back to on-device keyword logic.
  Future<String?> _callGemini(String prompt) async {
    if (await _isPrivacyMode()) return null;
    if (!await _checkRateLimit()) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'prompt': prompt,
              'temperature': 0.3,
              'maxTokens': 600,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        await _incrementCount();
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['text'] as String?;
        return (text != null && text.trim().isNotEmpty) ? text : null;
      }
    } catch (_) {}
    return null;
  }

  Future<GeminiCategorizationResult> categorizeTransaction(
    String merchant,
    double amount,
    DateTime time,
  ) async {
    await _initCache();

    // Check local cache first
    final cacheKey = 'cat_${merchant.toLowerCase()}';
    final cached = _cacheBox!.get(cacheKey);
    if (cached != null) {
      try {
        final map = Map<String, dynamic>.from(cached as Map);
        return GeminiCategorizationResult(
          category: map['category'] ?? 'Other',
          subcategory: map['subcategory'] ?? '',
          isEmotional: map['isEmotional'] ?? false,
          suggestion: map['suggestion'] ?? '',
        );
      } catch (_) {}
    }

    // Fallback to keyword matching if no API key
    if (!_hasApiKey) {
      return _localCategorize(merchant, amount);
    }

    final hour = time.hour;
    final isLateNight = hour >= 22 || hour < 5;
    final isWeekend = time.weekday >= 6;

    final prompt = '''You are a financial categorization AI for Indian users.
Categorize this UPI transaction for an Indian user:
- Merchant: $merchant
- Amount: ₹$amount
- Time: ${isLateNight ? 'late night' : 'normal hours'}, ${isWeekend ? 'weekend' : 'weekday'}

Categories: ${AppConstants.defaultCategories.join(', ')}

Respond in JSON only (no markdown):
{
  "category": "category name",
  "subcategory": "specific subcategory",
  "isEmotional": true/false (late night or weekend impulse buying?),
  "suggestion": "one short actionable tip in Indian context"
}''';

    final response = await _callGemini(prompt);
    if (response != null) {
      try {
        final map = jsonDecode(_extractJson(response)) as Map<String, dynamic>;
        final result = GeminiCategorizationResult(
          category: map['category'] ?? 'Other',
          subcategory: map['subcategory'] ?? '',
          isEmotional: map['isEmotional'] ?? false,
          suggestion: map['suggestion'] ?? '',
        );
        // Cache for future use
        await _cacheBox!.put(cacheKey, {
          'category': result.category,
          'subcategory': result.subcategory,
          'isEmotional': result.isEmotional,
          'suggestion': result.suggestion,
        });
        return result;
      } catch (_) {}
    }

    return _localCategorize(merchant, amount);
  }

  /// Pulls the first balanced JSON object out of an LLM reply, tolerating
  /// markdown fences or surrounding prose (Llama sometimes adds both).
  String _extractJson(String raw) {
    var s = raw.replaceAll(RegExp(r'```json|```'), '').trim();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      s = s.substring(start, end + 1);
    }
    return s;
  }

  GeminiCategorizationResult _localCategorize(String merchant, double amount) {
    final lower = merchant.toLowerCase();
    String category = 'Other';
    for (final entry in AppConstants.merchantCategoryMap.entries) {
      if (lower.contains(entry.key)) {
        category = entry.value;
        break;
      }
    }
    return GeminiCategorizationResult(
      category: category,
      subcategory: '',
      isEmotional: false,
      suggestion: '',
    );
  }

  Future<GeminiInsightResult> generateInsights(List<Transaction> transactions) async {
    if (transactions.isEmpty) {
      return GeminiInsightResult(
        patterns: ['Add transactions to get insights'],
        predictions: [],
        tips: [AppConstants.noInsights],
        moodCorrelation: '',
        biggestWaste: '',
      );
    }

    if (!_hasApiKey) {
      return _generateLocalInsights(transactions);
    }

    // Summarize transactions for prompt (keep it short to save tokens)
    final summary = _summarizeForPrompt(transactions);

    final prompt = '''You are GenPay, a snarky but helpful AI financial advisor for Indian users.
Analyze this spending summary for the current month:
$summary

Respond in JSON only (no markdown):
{
  "patterns": ["pattern1", "pattern2", "pattern3"],
  "predictions": ["prediction about future spending"],
  "tips": ["specific actionable tip 1", "specific actionable tip 2"],
  "moodCorrelation": "one line about mood and spending",
  "biggestWaste": "the category/merchant wasting most money"
}

Be specific with ₹ amounts. Use Indian context. Be slightly roasting but helpful. Keep each string under 100 chars.''';

    final response = await _callGemini(prompt);
    if (response != null) {
      try {
        final map = jsonDecode(_extractJson(response)) as Map<String, dynamic>;
        return GeminiInsightResult(
          patterns: List<String>.from(map['patterns'] ?? []),
          predictions: List<String>.from(map['predictions'] ?? []),
          tips: List<String>.from(map['tips'] ?? []),
          moodCorrelation: map['moodCorrelation'] ?? '',
          biggestWaste: map['biggestWaste'] ?? '',
        );
      } catch (_) {}
    }

    return _generateLocalInsights(transactions);
  }

  String _summarizeForPrompt(List<Transaction> txns) {
    final now = DateTime.now();
    final thisMonth = txns.where((t) => t.date.month == now.month && t.date.year == now.year);

    final byCategory = <String, double>{};
    for (final t in thisMonth) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }

    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final topCategories = (byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}')
        .join(', ');

    return 'Total: ₹${total.toStringAsFixed(0)}, Day: ${now.day}/${_daysInMonth(now)}, Top: $topCategories';
  }

  int _daysInMonth(DateTime d) => DateTime(d.year, d.month + 1, 0).day;

  GeminiInsightResult _generateLocalInsights(List<Transaction> txns) {
    final now = DateTime.now();
    final thisMonth = txns.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
    if (thisMonth.isEmpty) {
      return GeminiInsightResult(
        patterns: [AppConstants.noInsights],
        predictions: [],
        tips: [],
        moodCorrelation: '',
        biggestWaste: '',
      );
    }

    final byCategory = <String, double>{};
    for (final t in thisMonth) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }

    // Optimization: O(N) max extraction using reduce
    final topCat = byCategory.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final total = byCategory.values.fold(0.0, (a, b) => a + b);

    return GeminiInsightResult(
      patterns: [
        '${topCat.key} is eating ${((topCat.value / total) * 100).toStringAsFixed(0)}% of your budget',
        'You\'ve made ${thisMonth.length} transactions this month',
      ],
      predictions: ['You\'re on track to spend ₹${(total / now.day * _daysInMonth(now)).toStringAsFixed(0)} this month'],
      tips: ['Cut ${topCat.key} spending by 20% to save ₹${(topCat.value * 0.2).toStringAsFixed(0)}'],
      moodCorrelation: '',
      biggestWaste: '${topCat.key}: ₹${topCat.value.toStringAsFixed(0)}',
    );
  }

  Future<String> getSmartSuggestion(double budget, double spent, String category) async {
    if (!_hasApiKey) {
      final pct = budget > 0 ? (spent / budget * 100).toInt() : 0;
      if (pct >= 100) return AppConstants.overBudget100Messages.first;
      if (pct >= 90) return AppConstants.overBudget90Messages.first.replaceAll('{remaining}', '₹${(budget - spent).toStringAsFixed(0)}');
      if (pct >= 80) return AppConstants.overBudget80Messages.first.replaceAll('{remaining}', '₹${(budget - spent).toStringAsFixed(0)}');
      return 'You\'ve spent ₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)} in $category.';
    }

    final pct = budget > 0 ? (spent / budget * 100).toInt() : 0;
    final prompt = '''For an Indian user who has spent ₹${spent.toStringAsFixed(0)} of ₹${budget.toStringAsFixed(0)} ($pct%) in $category this month.
Give ONE short roasting-but-helpful suggestion (max 80 chars, Indian context, use ₹).''';

    final response = await _callGemini(prompt);
    return response?.trim() ??
        'You\'ve spent ${pct}% of your $category budget. Keep an eye on it!';
  }
}
