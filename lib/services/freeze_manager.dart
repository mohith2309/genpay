import 'package:hive/hive.dart';
import '../core/constants.dart';

class FreezeManager {
  static const String _freezeUntilKey = 'freeze_until';
  static const String _overrideReasonKey = 'override_reason';
  static const String _overrideTimeKey = 'override_time';

  Box? _box;

  Future<void> _init() async {
    _box ??= await Hive.openBox(AppConstants.settingsBox);
  }

  Future<void> activateFreeze() async {
    await _init();
    final until = DateTime.now().add(const Duration(hours: 24));
    await _box!.put(_freezeUntilKey, until.toIso8601String());
  }

  Future<bool> isFreezeActive() async {
    await _init();
    final untilStr = _box!.get(_freezeUntilKey) as String?;
    if (untilStr == null) return false;
    final until = DateTime.tryParse(untilStr);
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  Future<DateTime?> getFreezeUntil() async {
    await _init();
    final untilStr = _box!.get(_freezeUntilKey) as String?;
    if (untilStr == null) return null;
    return DateTime.tryParse(untilStr);
  }

  Future<void> deactivateFreeze() async {
    await _init();
    await _box!.delete(_freezeUntilKey);
    await _box!.delete(_overrideReasonKey);
    await _box!.delete(_overrideTimeKey);
  }

  Future<void> saveOverride(String reason) async {
    await _init();
    await _box!.put(_overrideReasonKey, reason);
    await _box!.put(_overrideTimeKey, DateTime.now().toIso8601String());
    // Clear the freeze since we are overriding it
    await deactivateFreeze();
  }
}
