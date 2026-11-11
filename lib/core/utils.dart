import 'dart:ui';
import 'package:intl/intl.dart';

class AppUtils {
  static final NumberFormat _indianCurrency = NumberFormat('#,##,##0.00', 'en_IN');
  static final NumberFormat _indianCurrencyNoDecimal = NumberFormat('#,##,##0', 'en_IN');
  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormatter = DateFormat('hh:mm a');
  static final DateFormat _shortDate = DateFormat('dd MMM');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  static String formatCurrency(double amount, {bool showDecimals = true}) {
    if (showDecimals) {
      return '₹${_indianCurrency.format(amount)}';
    }
    return '₹${_indianCurrencyNoDecimal.format(amount)}';
  }

  static String formatAmount(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount, showDecimals: false);
  }

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatTime(DateTime date) {
    return _timeFormatter.format(date);
  }

  static String formatShortDate(DateTime date) {
    return _shortDate.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShortDate(date);
  }

  static double calculateRoundup(double amount) {
    final remainder = amount % 10;
    if (remainder == 0) return 0;
    return 10 - remainder;
  }

  // Optimization: Return Color object directly to prevent string parsing on every render
  static Color getCategoryColor(String category) {
    const colors = {
      'Food': Color(0xFFFF6B6B),
      'Transport': Color(0xFF00D9FF),
      'Shopping': Color(0xFFFF9FF3),
      'Bills': Color(0xFFFFD93D),
      'Entertainment': Color(0xFF6C5CE7),
      'Health': Color(0xFF39FF14),
      'Education': Color(0xFF74B9FF),
      'Travel': Color(0xFFFD79A8),
      'Groceries': Color(0xFF55EFC4),
      'Fuel': Color(0xFFFDCB6E),
      'Subscriptions': Color(0xFFA29BFE),
      'Other': Color(0xFFB2BEC3),
    };
    return colors[category] ?? const Color(0xFF888888);
  }

  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String percentageText(double spent, double budget) {
    if (budget <= 0) return '0%';
    final pct = (spent / budget * 100).clamp(0, 999);
    return '${pct.toStringAsFixed(0)}%';
  }

  static String parseMerchantFromVpa(String vpa) {
    // Extract readable name from UPI VPA like merchant@okicici
    final parts = vpa.split('@');
    if (parts.isEmpty) return vpa;
    return parts[0]
        .replaceAll(RegExp(r'[._\-]'), ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ')
        .trim();
  }

  static double cleanAmountString(String raw) {
    // Remove commas and whitespace, parse to double
    final cleaned = raw.replaceAll(RegExp(r'[,\s]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
