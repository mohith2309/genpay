import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../providers/request_provider.dart';
import '../../services/upi_service.dart';
import 'send_money_screen.dart';

class RequestMoneyScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const RequestMoneyScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends ConsumerState<RequestMoneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingIncomingProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request money'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.electricBlue,
          labelColor: AppColors.electricBlue,
          unselectedLabelColor: Theme.of(context).hintColor,
          tabs: [
            const Tab(text: 'Ask'),
            Tab(text: 'Requests${pending.isNotEmpty ? ' (${pending.length})' : ''}'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_AskTab(), _RequestsTab()],
      ),
    );
  }
}

// ── Ask (create outgoing request) ──────────────────────────────────────────────

class _AskTab extends ConsumerStatefulWidget {
  const _AskTab();
  @override
  ConsumerState<_AskTab> createState() => _AskTabState();
}

class _AskTabState extends ConsumerState<_AskTab> {
  final _vpaController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _vpaController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    final vpa = _vpaController.text.trim().toLowerCase();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (!UpiService.isValidVpa(vpa)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid UPI ID like name@okicici')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount to request')),
      );
      return;
    }
    final name = vpa.split('@').first;
    ref.read(requestsProvider.notifier).createOutgoing(
          name: name,
          vpa: vpa,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    HapticFeedback.mediumImpact();
    _vpaController.clear();
    _amountController.clear();
    _noteController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request for ${AppUtils.formatCurrency(amount)} sent to $name')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _vpaController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontFamily: 'JetBrains Mono'),
          decoration: const InputDecoration(
            labelText: 'Request from (UPI ID)',
            hintText: 'name@okicici',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixIcon: Icon(Icons.currency_rupee),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'What\'s it for? (optional)',
            prefixIcon: Icon(Icons.note_outlined),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _sendRequest,
            icon: const Icon(Icons.call_received),
            label: const Text('Send request'),
          ),
        ),
        const SizedBox(height: 24),
        _outgoingList(),
      ],
    );
  }

  Widget _outgoingList() {
    final outgoing = ref
        .watch(requestsProvider)
        .where((r) => !r.incoming)
        .toList();
    if (outgoing.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOU REQUESTED',
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2)),
        const SizedBox(height: 10),
        ...outgoing.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.call_received,
                      color: AppColors.electricBlue, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.vpa,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontFamily: 'JetBrains Mono')),
                        Text(r.status == RequestStatus.pending
                            ? 'Awaiting payment'
                            : 'Paid',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(AppUtils.formatCurrency(r.amount),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontFamily: 'JetBrains Mono')),
                ],
              ),
            )),
      ],
    );
  }
}

// ── Requests (incoming) ────────────────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = ref
        .watch(requestsProvider)
        .where((r) => r.incoming)
        .toList();

    if (incoming.isEmpty) {
      return Center(
        child: Text('No payment requests',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).hintColor)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: incoming.map((r) {
        final color = Color(_colorForName(r.name));
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Text(r.name[0].toUpperCase(),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            style: Theme.of(context).textTheme.titleSmall),
                        Text(r.note ?? r.vpa,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(AppUtils.formatCurrency(r.amount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: 'JetBrains Mono',
                          )),
                ],
              ),
              if (r.status == RequestStatus.pending) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(requestsProvider.notifier).decline(r.id);
                        },
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          ref.read(requestsProvider.notifier).markPaid(r.id);
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SendMoneyScreen(
                                payeeVpa: r.vpa,
                                payeeName: r.name,
                                presetAmount: r.amount,
                                presetNote: r.note,
                              ),
                            ),
                          );
                        },
                        child: const Text('Pay'),
                      ),
                    ),
                  ],
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    r.status == RequestStatus.paid ? '✓ Paid' : 'Declined',
                    style: TextStyle(
                      color: r.status == RequestStatus.paid
                          ? AppColors.neonGreen
                          : Theme.of(context).hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Deterministic avatar colour from a name.
int _colorForName(String name) {
  const colors = [
    0xFF00D9FF, 0xFF39FF14, 0xFFFF6B6B, 0xFFFFD93D, 0xFF6C5CE7, 0xFFFD79A8
  ];
  return colors[name.hashCode.abs() % colors.length];
}
