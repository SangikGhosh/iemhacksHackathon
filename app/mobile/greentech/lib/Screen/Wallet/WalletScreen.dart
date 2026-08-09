import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Model/Wallet.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';

class PaymentEntry {
  const PaymentEntry({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.credit,
    required this.at,
    required this.icon,
    required this.settled,
  });

  final String title;
  final String subtitle;
  final double amount;
  final bool credit;
  final DateTime? at;
  final dynamic icon;
  final bool settled;
}

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  int _tab = 0;

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  List<PaymentEntry> _pickupPayments(List<Pickup> pickups) {
    return pickups
        .where(
          (pickup) =>
              pickup.status == PickupStatus.completed &&
              pickup.money.finalAmount != null,
        )
        .map(
          (pickup) => PaymentEntry(
            title: '${pickup.mode.label} pickup paid',
            subtitle: pickup.materials.isEmpty
                ? '${pickup.totalObjects} items'
                : pickup.materials,
            amount: pickup.money.finalAmount!,
            credit: true,
            at: pickup.completedAt,
            icon: HugeIcons.strokeRoundedDeliveryBox01,
            settled: true,
          ),
        )
        .toList();
  }

  List<PaymentEntry> _walletPayments(Wallet wallet) {
    return wallet.transactions
        .map(
          (tx) => PaymentEntry(
            title: tx.title,
            subtitle: tx.type.isCredit
                ? 'Marketplace sale'
                : 'Marketplace purchase',
            amount: tx.amount,
            credit: tx.type.isCredit,
            at: tx.createdAt,
            icon: HugeIcons.strokeRoundedShoppingBag01,
            settled: true,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(walletProvider);
    final wallet = async.value ?? Wallet.empty;
    final role = ref.watch(sessionProvider).value?.role ?? Role.citizen;
    final showPickups = role.canRequestPickup;
    final pickups = showPickups
        ? ref.watch(pickupsProvider).value ?? const <Pickup>[]
        : const <Pickup>[];

    final fromPickups = _pickupPayments(pickups);
    final fromWallet = _walletPayments(wallet);

    final pickupTotal = fromPickups.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );

    final entries = switch (_tab) {
      1 => fromWallet,
      2 => fromPickups,
      _ =>
        [...fromWallet, ...fromPickups]..sort((a, b) {
          final left = a.at;
          final right = b.at;
          if (left == null && right == null) return 0;
          if (left == null) return 1;
          if (right == null) return -1;
          return right.compareTo(left);
        }),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CitizenAppBar(
        title: 'Wallet',
        subtitle: 'Marketplace balance and pickup payouts',
        onBack: widget.embedded ? null : _exit,
      ),
      body: async.isLoading && !async.hasValue
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && !async.hasValue
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(walletProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              color: uiInk,
              onRefresh: () async {
                await Future.wait([
                  ref.read(walletProvider.notifier).refresh(),
                  ref.read(pickupsProvider.notifier).refresh(),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  _BalanceCard(
                    wallet: wallet,
                    pickupTotal: pickupTotal,
                    showPickups: showPickups,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          icon: HugeIcons.strokeRoundedArrowUp01,
                          value: rupees(wallet.totalEarned),
                          label: 'Sales in',
                          accent: uiGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricTile(
                          icon: HugeIcons.strokeRoundedArrowDown01,
                          value: rupees(wallet.totalSpent),
                          label: 'Purchases out',
                        ),
                      ),
                      if (showPickups) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedDeliveryBox01,
                            value: rupees(pickupTotal),
                            label: 'Pickup payouts',
                          ),
                        ),
                      ],
                      if (role.earnsRewards) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedStar,
                            value: '${wallet.greenPoints}',
                            label: 'Green points',
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SplitNote(showPickups: showPickups),
                  const SizedBox(height: 24),
                  if (showPickups) ...[
                    _Tabs(
                      selected: _tab,
                      onSelect: (index) => setState(() => _tab = index),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (entries.isEmpty)
                    EmptyState(
                      icon: HugeIcons.strokeRoundedWallet01,
                      title: 'No payments yet',
                      message: showPickups
                          ? 'Sell waste to a recycler or complete a pickup, and the money shows up here.'
                          : 'Buy or sell material in the marketplace, and the money shows up here.',
                    )
                  else
                    ListCard(
                      indent: 52,
                      children: [
                        for (final entry in entries) _PaymentRow(entry: entry),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.wallet,
    required this.pickupTotal,
    required this.showPickups,
  });

  final Wallet wallet;
  final double pickupTotal;
  final bool showPickups;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: uiInk,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedWallet01,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                'WALLET BALANCE',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            rupees(wallet.balance),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1.9,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            showPickups
                ? 'Plus ${rupees(pickupTotal)} paid directly for pickups'
                : 'Marketplace trades settle straight into this balance',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitNote extends StatelessWidget {
  const _SplitNote({required this.showPickups});

  final bool showPickups;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            color: uiInkTertiary,
            size: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            showPickups
                ? 'The wallet ledger records marketplace trades. Pickup payouts are settled by the collector and shown separately.'
                : 'The wallet ledger records every marketplace purchase and sale you settle.',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: uiInkTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const List<String> _labels = ['All', 'Marketplace', 'Pickups'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _labels.length; index++)
            Expanded(
              child: Pressable(
                onTap: () => onSelect(index),
                scale: 0.97,
                child: AnimatedContainer(
                  duration: uiQuick,
                  curve: uiEase,
                  height: 38,
                  decoration: BoxDecoration(
                    color: index == selected
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: index == selected
                        ? [
                            BoxShadow(
                              color: uiInk.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _labels[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: index == selected ? uiInk : uiInkSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.entry});

  final PaymentEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.credit ? uiGreen : uiDanger;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: HugeIcon(icon: entry.icon, color: color, size: 17),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: uiInk,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.subtitle} · ${relativeTime(entry.at)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.credit ? '+' : '−'}${rupees(entry.amount)}',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}
