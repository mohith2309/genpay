import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../services/hive_service.dart';
import '../../services/razorpay_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/pause_mode_provider.dart';

/// Privacy mode (offline AI). Persisted in the settings box and read by
/// [GeminiService] to short-circuit every cloud call when enabled.
class PrivacyModeNotifier extends StateNotifier<bool> {
  PrivacyModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final box = await Hive.openBox(AppConstants.settingsBox);
    state = box.get('privacy_mode', defaultValue: false) as bool;
  }

  Future<void> toggle(bool value) async {
    final box = await Hive.openBox(AppConstants.settingsBox);
    await box.put('privacy_mode', value);
    state = value;
  }
}

final privacyModeProvider =
    StateNotifierProvider<PrivacyModeNotifier, bool>((ref) => PrivacyModeNotifier());

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final privacyMode = ref.watch(privacyModeProvider);
    final pause = ref.watch(pauseModeProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),

            const _PremiumCard(),
            const SizedBox(height: 24),

            const _SectionHeader('Privacy & security'),
            _SwitchTile(
              icon: Icons.shield_outlined,
              title: 'Privacy mode (offline AI)',
              subtitle: 'No cloud calls. On-device categorization only.',
              value: privacyMode,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                ref.read(privacyModeProvider.notifier).toggle(v);
              },
            ),
            _SwitchTile(
              icon: Icons.fingerprint,
              title: 'Biometric lock',
              subtitle: auth.isBiometricAvailable
                  ? 'Require Face ID / fingerprint to open GenPay'
                  : 'Not available on this device',
              value: auth.isBiometricEnabled,
              onChanged: auth.isBiometricAvailable
                  ? (v) {
                      HapticFeedback.selectionClick();
                      ref.read(authProvider.notifier).toggleBiometric(v);
                    }
                  : null,
            ),

            const SizedBox(height: 16),
            const _SectionHeader('Money guardrails'),
            _ActionTile(
              icon: Icons.auto_awesome,
              title: 'Budget autopilot',
              subtitle: 'Set budgets from your last 3 months',
              onTap: () => _runAutopilot(context, ref),
            ),
            _ActionTile(
              icon: Icons.ac_unit,
              title: pause.isPaused ? 'Cooling off (${pause.remainingText})' : 'Start a cooling-off period',
              subtitle: 'Block new spending for a while',
              onTap: () => _freezeSheet(context, ref),
            ),

            const SizedBox(height: 16),
            const _SectionHeader('Data'),
            _ActionTile(
              icon: Icons.delete_outline,
              title: 'Delete all data',
              subtitle: 'Wipe everything stored on this device',
              danger: true,
              onTap: () => _confirmDelete(context, ref),
            ),

            const SizedBox(height: 24),
            const _SectionHeader('About'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GenPay v1.0.0',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(
                    'SMS is parsed on your phone — only the merchant name is ever sent to Google Gemini for categorization, and only when privacy mode is off. Your data is never sold.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runAutopilot(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final txns = ref.read(transactionsProvider).asData?.value ?? [];
    await ref.read(budgetProvider.notifier).applyAutopilotBudgets(txns);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budgets rebalanced from your history 🤖')),
      );
    }
  }

  void _freezeSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🧊', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('Freeze spending for…',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [2, 6, 24].map((h) {
                  return OutlinedButton(
                    onPressed: () {
                      ref.read(pauseModeProvider.notifier).activatePause(h);
                      Navigator.pop(ctx);
                    },
                    child: Text('${h}h'),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete everything?'),
        content: const Text(
            'This wipes all transactions, budgets and your vault from this device. Can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: Theme.of(context).hintColor)),
          ),
          TextButton(
            onPressed: () async {
              await HiveService.clearAll();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data deleted')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.debit)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(letterSpacing: 2)),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.debit : AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: danger ? AppColors.debit : null)),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatefulWidget {
  const _PremiumCard();

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard> {
  final _razorpay = RazorpayService();
  bool _processing = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremium();
    _razorpay.init();
    _razorpay.onSuccess = _onSuccess;
    _razorpay.onError = _onError;
  }

  @override
  void dispose() {
    _razorpay.dispose();
    super.dispose();
  }

  Future<void> _loadPremium() async {
    final box = await Hive.openBox(AppConstants.settingsBox);
    if (mounted) {
      setState(() => _isPremium = box.get('premium', defaultValue: false) as bool);
    }
  }

  Future<void> _goPremium() async {
    setState(() => _processing = true);
    // 1. Backend creates the order with the Key Secret (server-side only).
    final order = await _razorpay.createOrder(
      AppConstants.premiumPriceMonthly,
      receipt: 'genpay_premium',
    );
    if (!mounted) return;
    if (order == null) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not start checkout. Is the backend running with valid Razorpay keys?'),
        ),
      );
      return;
    }
    // 2. Open checkout bound to the server-created order.
    _razorpay.open(
      orderId: order.orderId,
      amount: AppConstants.premiumPriceMonthly,
      description: 'GenPay Premium — 1 month',
      payeeName: AppConstants.merchantName,
    );
  }

  Future<void> _onSuccess(PaymentResult r) async {
    // 3. Verify the signature on the backend before unlocking premium.
    final verified = await _razorpay.verifyPayment(r);
    if (!mounted) return;
    if (!verified) {
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment could not be verified.')),
      );
      return;
    }
    final box = await Hive.openBox(AppConstants.settingsBox);
    await box.put('premium', true);
    if (!mounted) return;
    setState(() {
      _processing = false;
      _isPremium = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Welcome to GenPay Premium ⚡')),
    );
  }

  void _onError(PaymentResult r) {
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(r.errorMessage ?? 'Payment cancelled')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent),
        color: AppColors.accent.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚡', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(_isPremium ? 'GenPay Premium' : 'GenPay Premium',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppColors.accent)),
              const Spacer(),
              Text(_isPremium ? 'Active' : '₹49/mo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _isPremium ? AppColors.credit : null,
                      )),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Unlimited SMS parsing · AI insights & predictions · Future-self projections · Vault auto-invest · Data export',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).hintColor, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isPremium || _processing) ? null : _goPremium,
              child: _processing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary),
                    )
                  : Text(_isPremium ? 'You\'re Premium ⚡' : 'Go Premium'),
            ),
          ),
        ],
      ),
    );
  }
}
