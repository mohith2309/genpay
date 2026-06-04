import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pause_mode_service.dart';

final pauseModeServiceProvider = Provider<PauseModeService>((ref) => PauseModeService());

class PauseModeState {
  final bool isPaused;
  final DateTime? pauseUntil;
  final int overrideCount;

  PauseModeState({
    required this.isPaused,
    this.pauseUntil,
    required this.overrideCount,
  });

  PauseModeState copyWith({bool? isPaused, DateTime? pauseUntil, int? overrideCount}) {
    return PauseModeState(
      isPaused: isPaused ?? this.isPaused,
      pauseUntil: pauseUntil ?? this.pauseUntil,
      overrideCount: overrideCount ?? this.overrideCount,
    );
  }

  Duration? get remainingTime {
    if (pauseUntil == null) return null;
    final remaining = pauseUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  String get remainingText {
    final d = remainingTime;
    if (d == null) return '';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m left';
    if (d.inMinutes > 0) return '${d.inMinutes}m left';
    return '${d.inSeconds}s left';
  }
}

class PauseModeNotifier extends StateNotifier<PauseModeState> {
  final PauseModeService _service;

  PauseModeNotifier(this._service)
      : super(PauseModeState(isPaused: false, overrideCount: 0)) {
    _init();
  }

  Future<void> _init() async {
    final isPaused = await _service.isPaused();
    final pauseUntil = await _service.getPauseUntil();
    final overrideCount = await _service.getTodayOverrideCount();
    state = PauseModeState(
      isPaused: isPaused,
      pauseUntil: pauseUntil,
      overrideCount: overrideCount,
    );
  }

  Future<void> activatePause(int hours) async {
    await _service.activatePause(hours);
    await _init();
  }

  Future<void> deactivatePause() async {
    await _service.deactivatePause();
    state = PauseModeState(isPaused: false, overrideCount: state.overrideCount);
  }

  Future<OverrideResult> requestOverride(String reason) async {
    final result = await _service.requestOverride(reason);
    if (result.allowed) {
      await _service.deactivatePause();
      state = state.copyWith(isPaused: false);
    }
    return result;
  }

  Future<void> refresh() => _init();
}

final pauseModeProvider = StateNotifierProvider<PauseModeNotifier, PauseModeState>(
  (ref) => PauseModeNotifier(ref.watch(pauseModeServiceProvider)),
);
