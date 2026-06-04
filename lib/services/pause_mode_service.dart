import 'package:hive/hive.dart';
import '../core/constants.dart';

class PauseModeService {
  static const String _pauseUntilKey = 'pause_until';
  static const String _overrideCountKey = 'override_count';
  static const String _lastOverrideDateKey = 'last_override_date';

  Box? _box;

  Future<void> _init() async {
    _box ??= await Hive.openBox(AppConstants.pauseModeBox);
  }

  Future<void> activatePause(int hours) async {
    await _init();
    final until = DateTime.now().add(Duration(hours: hours));
    await _box!.put(_pauseUntilKey, until.toIso8601String());
  }

  Future<bool> isPaused() async {
    await _init();
    final untilStr = _box!.get(_pauseUntilKey) as String?;
    if (untilStr == null) return false;
    final until = DateTime.tryParse(untilStr);
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  Future<DateTime?> getPauseUntil() async {
    await _init();
    final untilStr = _box!.get(_pauseUntilKey) as String?;
    if (untilStr == null) return null;
    return DateTime.tryParse(untilStr);
  }

  Future<Duration?> getRemainingTime() async {
    final until = await getPauseUntil();
    if (until == null) return null;
    final remaining = until.difference(DateTime.now());
    if (remaining.isNegative) return null;
    return remaining;
  }

  Future<void> deactivatePause() async {
    await _init();
    await _box!.delete(_pauseUntilKey);
  }

  Future<OverrideResult> requestOverride(String reason) async {
    await _init();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastOverrideDate = _box!.get(_lastOverrideDateKey, defaultValue: '') as String;

    int overrideCount = 0;
    if (lastOverrideDate == today) {
      overrideCount = _box!.get(_overrideCountKey, defaultValue: 0) as int;
    }

    await _box!.put(_lastOverrideDateKey, today);
    await _box!.put(_overrideCountKey, overrideCount + 1);

    if (overrideCount >= 3) {
      return OverrideResult(
        allowed: false,
        message: 'You\'ve overridden pause mode $overrideCount times today. That\'s a pattern, not an emergency.',
        delaySeconds: 0,
      );
    }

    return OverrideResult(
      allowed: true,
      message: overrideCount >= 1
          ? 'Again? You\'ve already overridden once today. Is this ACTUALLY urgent?'
          : AppConstants.pauseOverrideWarning,
      delaySeconds: 30,
    );
  }

  Future<int> getTodayOverrideCount() async {
    await _init();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = _box!.get(_lastOverrideDateKey, defaultValue: '') as String;
    if (lastDate != today) return 0;
    return _box!.get(_overrideCountKey, defaultValue: 0) as int;
  }
}

class OverrideResult {
  final bool allowed;
  final String message;
  final int delaySeconds;

  OverrideResult({
    required this.allowed,
    required this.message,
    required this.delaySeconds,
  });
}
