import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive/hive.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/bank_provider.dart';
import '../../providers/payee_provider.dart';

enum _Step { phone, verifying, selectBank, fetching, setPin, confirmPin, done }

class UpiSetupScreen extends ConsumerStatefulWidget {
  const UpiSetupScreen({super.key});

  @override
  ConsumerState<UpiSetupScreen> createState() => _UpiSetupScreenState();
}

class _UpiSetupScreenState extends ConsumerState<UpiSetupScreen> {
  _Step _step = _Step.phone;
  final _phoneController = TextEditingController();
  String _phone = '';
  List<String>? _selectedBank; // [name, handle, ifsc]
  String _pin = '';
  String _firstPin = '';
  String? _accountId;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ── Step transitions ──────────────────────────────────────────────────────

  Future<void> _submitPhone() async {
    final p = _phoneController.text.trim();
    if (p.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit mobile number')),
      );
      return;
    }
    _phone = p;
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.verifying);
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    setState(() => _step = _Step.selectBank);
  }

  Future<void> _selectBank(List<String> bank) async {
    _selectedBank = bank;
    setState(() => _step = _Step.fetching);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    // Link the account (no PIN yet)
    final account = await ref.read(bankAccountsProvider.notifier).linkAccount(
          bankName: bank[0],
          handle: bank[1],
          ifscPrefix: bank[2],
          phone: _phone,
        );
    _accountId = account.id;
    // Save the user's UPI profile name + VPA for the receive screen
    await ref
        .read(myUpiProfileProvider.notifier)
        .update(vpa: account.vpa, name: 'You');
    if (!mounted) return;
    setState(() => _step = _Step.setPin);
  }

  Future<void> _onPinKey(String k) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (k == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 6) {
        _pin += k;
      }
    });
    if (_pin.length == 6) {
      if (_step == _Step.setPin) {
        _firstPin = _pin;
        await Future.delayed(const Duration(milliseconds: 150));
        setState(() {
          _pin = '';
          _step = _Step.confirmPin;
        });
      } else if (_step == _Step.confirmPin) {
        if (_pin == _firstPin) {
          await ref
              .read(bankAccountsProvider.notifier)
              .setUpiPin(_accountId!, _pin);
          // Mark UPI setup complete in settings.
          final box = await Hive.openBox(AppConstants.settingsBox);
          await box.put('upi_setup_done', true);
          if (!mounted) return;
          setState(() => _step = _Step.done);
        } else {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PINs don\'t match. Start again.')),
          );
          setState(() {
            _pin = '';
            _firstPin = '';
            _step = _Step.setPin;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Razor-thin progress at the very top (Gemini's note): forward momentum.
    final progress = (_step.index + 1) / _Step.values.length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, value, _) => Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    backgroundColor: Theme.of(context).dividerColor,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _buildStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.phone:
        return _phoneStep();
      case _Step.verifying:
        return _loadingStep(
          key: const ValueKey('verifying'),
          emoji: '📲',
          title: 'Verifying your number',
          subtitle:
              'Sending an SMS from your device to securely link $_phone with your bank. Standard SMS charges may apply.',
        );
      case _Step.selectBank:
        return _selectBankStep();
      case _Step.fetching:
        return _loadingStep(
          key: const ValueKey('fetching'),
          emoji: '🏦',
          title: 'Fetching your account',
          subtitle:
              'Securely retrieving your ${_selectedBank?[0] ?? 'bank'} account linked to $_phone…',
        );
      case _Step.setPin:
        return _pinStep(
          key: const ValueKey('setpin'),
          title: 'Set your UPI PIN',
          subtitle: 'Create a 6-digit UPI PIN. You\'ll use it to approve payments.',
        );
      case _Step.confirmPin:
        return _pinStep(
          key: const ValueKey('confirmpin'),
          title: 'Confirm UPI PIN',
          subtitle: 'Re-enter your 6-digit UPI PIN to confirm.',
        );
      case _Step.done:
        return _doneStep();
    }
  }

  // ── Step UIs ──────────────────────────────────────────────────────────────

  Widget _phoneStep() {
    return Padding(
      key: const ValueKey('phone'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text('💸', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 20),
          Text('Set up GenPay UPI',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Pay anyone, scan any QR, split bills and track every rupee — all in one place.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 32),
          Text('YOUR MOBILE NUMBER',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 2)),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            autofocus: true,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontFamily: 'JetBrains Mono'),
            decoration: const InputDecoration(
              prefixText: '+91  ',
              counterText: '',
              hintText: '90000 00000',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.lock, size: 14, color: Theme.of(context).hintColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Use the number linked to your bank account.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitPhone,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingStep({
    required Key key,
    required String emoji,
    required String title,
    required String subtitle,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56))
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 1200.ms, color: AppColors.electricBlue),
            const SizedBox(height: 28),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.electricBlue),
            ),
            const SizedBox(height: 28),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectBankStep() {
    return Column(
      key: const ValueKey('selectbank'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose your bank',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('Select the bank where $_phone is registered.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: AppConstants.upiBanks.length,
            itemBuilder: (context, i) {
              final bank = AppConstants.upiBanks[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.account_balance,
                        color: AppColors.electricBlue, size: 20),
                  ),
                  title: Text(bank[0],
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: Text('@${bank[1]}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontFamily: 'JetBrains Mono')),
                  trailing: Icon(Icons.chevron_right,
                      color: Theme.of(context).hintColor),
                  onTap: () => _selectBank(bank),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pinStep({required Key key, required String title, required String subtitle}) {
    return Column(
      key: key,
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.lock_outline, color: AppColors.electricBlue, size: 40),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final filled = i < _pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? AppColors.electricBlue : Colors.transparent,
                border: Border.all(
                  color:
                      filled ? AppColors.electricBlue : Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
            );
          }),
        ),
        const Spacer(),
        _SetupPinPad(onKey: _onPinKey),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _doneStep() {
    return Center(
      key: const ValueKey('done'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonGreen, width: 2),
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.neonGreen, size: 56),
            ).animate().scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.3, 0.3)),
            const SizedBox(height: 28),
            Text('You\'re all set!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '${_selectedBank?[0] ?? 'Your bank'} is linked and your UPI PIN is ready. Start paying.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Start paying'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupPinPad extends StatelessWidget {
  final void Function(String) onKey;
  const _SetupPinPad({required this.onKey});

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: _keys.map((row) {
          return Row(
            children: row.map((k) {
              if (k.isEmpty) return const Expanded(child: SizedBox(height: 60));
              return Expanded(
                child: InkWell(
                  onTap: () => onKey(k),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: k == '⌫'
                        ? Icon(Icons.backspace_outlined,
                            color: Theme.of(context).colorScheme.onSurface)
                        : Text(k,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w500)),
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
