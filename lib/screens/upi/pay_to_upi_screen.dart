import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/payee_provider.dart';
import '../../services/upi_service.dart';
import 'send_money_screen.dart';

/// Enter a UPI ID manually, verify it, then continue to the amount screen.
/// Also lists saved payees for one-tap re-pay.
class PayToUpiScreen extends ConsumerStatefulWidget {
  final String title;
  const PayToUpiScreen({super.key, this.title = 'Pay to UPI ID'});

  @override
  ConsumerState<PayToUpiScreen> createState() => _PayToUpiScreenState();
}

class _PayToUpiScreenState extends ConsumerState<PayToUpiScreen> {
  final _vpaController = TextEditingController();
  final _nameController = TextEditingController();
  bool _verified = false;

  @override
  void dispose() {
    _vpaController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _verify() {
    final vpa = _vpaController.text.trim();
    if (UpiService.isValidVpa(vpa)) {
      final existing = ref.read(payeesProvider.notifier).byVpa(vpa);
      setState(() {
        _verified = true;
        if (_nameController.text.isEmpty) {
          _nameController.text = existing?.name ??
              vpa.split('@').first.replaceAll(RegExp(r'[._\-]'), ' ');
        }
      });
    } else {
      setState(() => _verified = false);
    }
  }

  void _continue() {
    final vpa = _vpaController.text.trim().toLowerCase();
    final name = _nameController.text.trim().isEmpty
        ? vpa.split('@').first
        : _nameController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendMoneyScreen(payeeVpa: vpa, payeeName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payees = ref.watch(recentPayeesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _vpaController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            style: const TextStyle(fontFamily: 'JetBrains Mono'),
            decoration: InputDecoration(
              labelText: 'Enter UPI ID / VPA',
              hintText: 'name@okicici',
              prefixIcon: const Icon(Icons.alternate_email),
              suffixIcon: _verified
                  ? const Icon(Icons.verified, color: AppColors.neonGreen)
                  : null,
            ),
            onChanged: (_) => _verify(),
          ),
          const SizedBox(height: 14),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _verified
                ? Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Payee name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _continue,
                          child: const Text('Continue'),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          if (payees.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('SAVED PAYEES',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 2)),
            const SizedBox(height: 8),
            ...payees.map((p) {
              final color = Color(p.avatarColor);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Text(p.initials,
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w700)),
                ),
                title: Text(p.name,
                    style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(p.upiId,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontFamily: 'JetBrains Mono')),
                trailing: p.payCount > 0
                    ? Text('${p.payCount}×',
                        style: TextStyle(
                            color: Theme.of(context).hintColor, fontSize: 12))
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SendMoneyScreen(payeeVpa: p.upiId, payeeName: p.name),
                  ),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 28),
            Center(
              child: Text(
                'No saved payees yet.\nPay someone and they\'ll show up here.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).hintColor),
              ),
            ),
          ],

          const SizedBox(height: 16),
          const _SecurityHint(),
        ],
      ),
    );
  }
}

class _SecurityHint extends StatelessWidget {
  const _SecurityHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neonGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 16, color: AppColors.neonGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Every payment is authorised with your 6-digit UPI PIN.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).hintColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
