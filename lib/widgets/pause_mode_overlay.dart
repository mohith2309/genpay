import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../providers/pause_mode_provider.dart';

class PauseModeOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const PauseModeOverlay({super.key, required this.child});

  @override
  ConsumerState<PauseModeOverlay> createState() => _PauseModeOverlayState();
}

class _PauseModeOverlayState extends ConsumerState<PauseModeOverlay> {
  Timer? _timer;
  bool _showOverride = false;
  bool _waitingForDelay = false;
  int _delaySeconds = 0;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _delayTimer?.cancel();
    super.dispose();
  }

  void _requestOverride() {
    setState(() {
      _showOverride = true;
    });
  }

  void _startOverrideDelay() async {
    final result = await ref.read(pauseModeProvider.notifier).requestOverride('User initiated');
    if (!result.allowed) {
      _showBlockedDialog(result.message);
      return;
    }

    if (result.delaySeconds > 0) {
      setState(() {
        _waitingForDelay = true;
        _delaySeconds = result.delaySeconds;
      });

      _delayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _delaySeconds--;
        });
        if (_delaySeconds <= 0) {
          timer.cancel();
          ref.read(pauseModeProvider.notifier).deactivatePause();
          setState(() {
            _waitingForDelay = false;
            _showOverride = false;
          });
        }
      });
    }
  }

  void _showBlockedDialog(String message) {
    setState(() {
      _showOverride = false;
    });
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Blocked', style: TextStyle(color: AppColors.softRed)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pauseState = ref.watch(pauseModeProvider);

    if (!pauseState.isPaused) return widget.child;

    final remaining = pauseState.remainingTime;
    if (remaining == null) {
      // Pause expired
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pauseModeProvider.notifier).deactivatePause();
      });
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        // Dim overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.92),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🧊', style: TextStyle(fontSize: 80))
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 2.seconds, color: AppColors.accent),
                    const SizedBox(height: 32),
                    Text(
                      'Cooling Period Active',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.accent,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      pauseState.remainingText,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your wallet is on airplane mode.\nStep away from the checkout.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    if (_showOverride && !_waitingForDelay) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.softRed.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              AppConstants.pauseOverrideWarning,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.softRed,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _showOverride = false),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.credit),
                                      foregroundColor: AppColors.credit,
                                    ),
                                    child: const Text('Nevermind'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _startOverrideDelay,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.softRed,
                                    ),
                                    child: const Text('Yes, override'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else if (_waitingForDelay) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_delaySeconds',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppColors.softRed,
                                  ),
                            ),
                            Text(
                              'seconds to think about it...',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      TextButton(
                        onPressed: _requestOverride,
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        child: const Text('Is this ACTUALLY urgent?'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
        ),
      ],
    );
  }
}
