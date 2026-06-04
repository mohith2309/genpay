import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _smsGranted = false;
  final Map<String, double> _budgets = Map.from(AppConstants.defaultBudgets);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _requestSmsPermission() async {
    final status = await Permission.sms.request();
    setState(() {
      _smsGranted = status.isGranted;
    });
  }

  Future<void> _finish() async {
    // Persist the budgets the user picked during onboarding.
    final notifier = ref.read(budgetProvider.notifier);
    for (final entry in _budgets.entries) {
      await notifier.setBudget(entry.key, entry.value);
    }
    await ref.read(authProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    height: 3,
                    width: i == _currentPage ? 32 : 12,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.accent
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _Page1(),
                  _Page2(
                    smsGranted: _smsGranted,
                    onRequestPermission: _requestSmsPermission,
                  ),
                  _Page3(
                    budgets: _budgets,
                    onBudgetChange: (cat, val) => setState(() => _budgets[cat] = val),
                  ),
                ],
              ),
            ),
            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(_currentPage == 2 ? "Let's go 🚀" : 'Continue'),
                    ),
                  ),
                  if (_currentPage < 2) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Skip for now',
                        style: TextStyle(color: Theme.of(context).hintColor),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💸',
            style: const TextStyle(fontSize: 80),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -12, duration: 1.5.seconds, curve: Curves.easeInOut),
          const SizedBox(height: 40),
          Text(
            'Your money,\nbut make it\nsmart',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  height: 1.1,
                  fontSize: 40,
                ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideX(begin: -0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            'GenPay auto-reads your UPI SMS, categorizes every transaction with AI, and roasts you when you overspend.\n\nYou\'re welcome.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                  height: 1.6,
                ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms),
        ],
      ),
    );
  }
}

class _Page2 extends StatelessWidget {
  final bool smsGranted;
  final VoidCallback onRequestPermission;

  const _Page2({required this.smsGranted, required this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📱', style: const TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -8, duration: 2.seconds),
          const SizedBox(height: 40),
          Text(
            'Auto-reads\nUPI SMS',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 40,
                  height: 1.1,
                ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          Text(
            'We read your UPI messages to auto-log transactions.\n\n🔒 Everything stays on your phone.\n🚫 We never upload your SMS to any server.\n✓ You approve every transaction before it\'s saved.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                  height: 1.6,
                ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 32),
          // Permission card
          GestureDetector(
            onTap: smsGranted ? null : onRequestPermission,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: smsGranted
                    ? AppColors.credit.withValues(alpha: 0.1)
                    : AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: smsGranted ? AppColors.credit : AppColors.accent,
                ),
              ),
              child: Row(
                children: [
                  Text(smsGranted ? '✅' : '📨', style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          smsGranted ? 'SMS Access Granted' : 'Grant SMS Access',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: smsGranted ? AppColors.credit : AppColors.accent,
                              ),
                        ),
                        Text(
                          smsGranted
                              ? 'GenPay can now auto-detect your UPI payments'
                              : 'Tap to allow reading UPI SMS messages',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Page3 extends StatelessWidget {
  final Map<String, double> budgets;
  final void Function(String category, double value) onBudgetChange;

  const _Page3({required this.budgets, required this.onBudgetChange});

  static const _showCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🎯', style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 24),
          Text(
            'Set your\nmonthly budgets',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 36,
                  height: 1.1,
                ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'We\'ve filled in sensible defaults.\nChange anything that doesn\'t fit.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 24),
          ..._showCategories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BudgetSlider(
                category: cat,
                value: budgets[cat] ?? 2000,
                onChanged: (v) => onBudgetChange(cat, v),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'You can always change these later in Settings.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BudgetSlider extends StatelessWidget {
  final String category;
  final double value;
  final ValueChanged<double> onChanged;

  const _BudgetSlider({
    required this.category,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              AppConstants.categoryIcons[category] ?? '💸',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              '₹${value.toInt()}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.accent,
                  ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(500, 20000),
          min: 500,
          max: 20000,
          divisions: 39,
          activeColor: AppColors.accent,
          inactiveColor: Theme.of(context).dividerColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
