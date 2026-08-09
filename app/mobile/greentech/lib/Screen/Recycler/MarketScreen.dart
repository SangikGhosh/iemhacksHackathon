import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Listing.dart';
import 'package:greentech/Model/Wallet.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Screen/Recycler/BuySheet.dart';
import 'package:greentech/Service/ToastService.dart';
import 'package:greentech/Utils/avatar_helper.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  bool _applying = false;

  Future<void> _apply(MarketQuery query) async {
    setState(() => _applying = true);
    await ref.read(marketProvider.notifier).apply(query);
    if (!mounted) return;
    setState(() => _applying = false);
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(marketProvider.notifier).refresh(),
      ref.read(walletProvider.notifier).refresh(),
    ]);
  }

  Future<void> _open(Listing listing) async {
    final result = await showBuySheet(context, listing: listing);
    if (result == null || !mounted) return;

    switch (result.outcome) {
      case BuyOutcome.bought:
        ToastService.show(
          'Bought ${listing.material} for ${rupees(listing.price)}.',
          ToastType.success,
          context,
        );
        ref.read(marketProvider.notifier).remove(listing.id);
        await Future.wait([
          ref.read(walletProvider.notifier).refresh(),
          ref.read(purchasesProvider.notifier).refresh(),
        ]);
      case BuyOutcome.gone:
        ToastService.show(
          result.message ?? 'Someone bought this first.',
          ToastType.info,
          context,
        );
        ref.read(marketProvider.notifier).remove(listing.id);
        await ref.read(marketProvider.notifier).refresh();
      case BuyOutcome.failed:
        await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(marketProvider);
    final all = async.value ?? const <Listing>[];
    final wallet = ref.watch(walletProvider).value ?? Wallet.empty;
    final user = ref.watch(sessionProvider).value;

    final controller = ref.read(marketProvider.notifier);
    final query = controller.query;
    final materials = controller.materials;
    final items = all
        .where((listing) => listing.status == ListingStatus.open)
        .toList();

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        title: 'Market',
        subtitle: items.isEmpty
            ? 'No open stock right now'
            : '${items.length} lot${items.length == 1 ? '' : 's'} available',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Pressable(
                onTap: () => context.push('/profile'),
                scale: 0.92,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: uiHairline, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(1.5),
                  child: CircleAvatar(
                    backgroundColor: uiFill,
                    backgroundImage: NetworkImage(
                      AvatarHelper.getAvatarForName(user?.fullName ?? 'Green'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: async.isLoading && all.isEmpty
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && all.isEmpty
          ? ErrorRetry(message: '${async.error}', onRetry: _refresh)
          : RefreshIndicator(
              color: uiInk,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  _BalanceStrip(
                    wallet: wallet,
                    onTap: () => context.push('/wallet'),
                  ),
                  const SizedBox(height: 18),
                  _SortBar(
                    sort: query.sort,
                    busy: _applying,
                    onSort: (value) => _apply(query.copyWith(sort: value)),
                  ),
                  if (materials.length > 1) ...[
                    const SizedBox(height: 12),
                    _MaterialChips(
                      materials: materials,
                      selected: query.material,
                      onSelect: (value) =>
                          _apply(query.copyWith(material: value)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (items.isEmpty)
                    EmptyState(
                      icon: HugeIcons.strokeRoundedShoppingBag01,
                      title: query.material == null
                          ? 'Nothing on the market'
                          : 'No ${query.material} right now',
                      message: query.material == null
                          ? 'When citizens and collectors list segregated waste, it shows up here.'
                          : 'Nothing open in this material. Clear the filter to see everything.',
                    )
                  else
                    for (final listing in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MarketCard(
                          listing: listing,
                          affordable: wallet.balance >= listing.price,
                          onTap: listing.mine ? () {} : () => _open(listing),
                          onBuy: listing.mine ? null : () => _open(listing),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _BalanceStrip extends StatelessWidget {
  const _BalanceStrip({required this.wallet, required this.onTap});

  final Wallet wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 17, 18, 17),
        decoration: BoxDecoration(
          color: uiInk,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUYING POWER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.65),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  rupees(wallet.balance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -1,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Spent ${rupees(wallet.totalSpent)}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.sort,
    required this.busy,
    required this.onSort,
  });

  final ListingSort sort;
  final bool busy;
  final ValueChanged<ListingSort> onSort;

  static const List<ListingSort> _options = [
    ListingSort.newest,
    ListingSort.priceAsc,
    ListingSort.priceDesc,
    ListingSort.weightDesc,
  ];

  static const Map<ListingSort, String> _labels = {
    ListingSort.newest: 'Newest',
    ListingSort.priceAsc: 'Cheapest',
    ListingSort.priceDesc: 'Dearest',
    ListingSort.weightDesc: 'Heaviest',
  };

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
          for (final option in _options)
            Expanded(
              child: Pressable(
                onTap: busy ? null : () => onSort(option),
                scale: 0.97,
                dimWhenDisabled: false,
                child: AnimatedContainer(
                  duration: uiQuick,
                  height: 38,
                  decoration: BoxDecoration(
                    color: option == sort ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: option == sort
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
                    _labels[option]!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: option == sort ? uiInk : uiInkSecondary,
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

class _MaterialChips extends StatelessWidget {
  const _MaterialChips({
    required this.materials,
    required this.selected,
    required this.onSelect,
  });

  final List<String> materials;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final material in materials)
            _Chip(
              label: material,
              selected: selected == material,
              onTap: () => onSelect(material),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: uiQuick,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: selected ? uiInk : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: selected ? uiInk : uiHairlineStrong),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : uiInkSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class MarketCard extends StatelessWidget {
  const MarketCard({
    super.key,
    required this.listing,
    required this.affordable,
    required this.onTap,
    this.onBuy,
  });

  final Listing listing;
  final bool affordable;
  final VoidCallback onTap;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final own = listing.mine;

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: uiHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              listing.material,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: uiInk,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          if (own) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: uiFill,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Yours',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: uiInkSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${kilograms(listing.weightKg)}'
                        '${listing.location.isEmpty ? '' : ' · ${listing.location}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: uiInkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      rupees(listing.pricePerKg),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: uiInk,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'per kg',
                      style: TextStyle(fontSize: 11.5, color: uiInkTertiary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const UiHairline(),
            const SizedBox(height: 13),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: uiInkTertiary,
                  size: 14,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    listing.seller?.fullName ?? 'Seller',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: uiInkSecondary),
                  ),
                ),
                Text(
                  'Lot ${rupees(listing.price)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: uiInk,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            if (onBuy != null) ...[
              const SizedBox(height: 14),
              Pressable(
                onTap: affordable ? onBuy : null,
                dimWhenDisabled: false,
                scale: 0.98,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: affordable ? uiInk : uiFillStrong,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    affordable ? 'Buy this lot' : 'Balance too low',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: affordable ? Colors.white : uiInkTertiary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
