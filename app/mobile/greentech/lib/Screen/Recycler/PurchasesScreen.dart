import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Listing.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(purchasesProvider);
    final items = async.value ?? const <Listing>[];

    final spent = items.fold<double>(0, (sum, l) => sum + l.price);
    final weight = items.fold<double>(0, (sum, l) => sum + l.weightKg);
    final avgRate = weight <= 0 ? 0.0 : spent / weight;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        title: 'Purchases',
        subtitle: items.isEmpty
            ? 'Stock you buy shows up here'
            : '${items.length} lot${items.length == 1 ? '' : 's'} bought',
      ),
      body: async.isLoading && items.isEmpty
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && items.isEmpty
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(purchasesProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              color: uiInk,
              onRefresh: () => ref.read(purchasesProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  if (items.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedCoins01,
                            value: rupees(spent),
                            label: 'Total spent',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedWeightScale01,
                            value: kilograms(weight),
                            label: 'Material',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricTile(
                            icon: HugeIcons.strokeRoundedTag01,
                            value: rupees(avgRate),
                            label: 'Avg /kg',
                            accent: uiGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (items.isEmpty)
                    const EmptyState(
                      icon: HugeIcons.strokeRoundedShoppingBag01,
                      title: 'No purchases yet',
                      message:
                          'Buy a lot from the market and it will be listed here with what you paid.',
                    )
                  else
                    for (final listing in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PurchaseCard(listing: listing),
                      ),
                ],
              ),
            ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: uiGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Bought',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: uiGreen,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                relativeTime(listing.soldAt ?? listing.createdAt),
                style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
                    const SizedBox(height: 3),
                    Text(
                      '${kilograms(listing.weightKg)} · from '
                      '${listing.seller?.fullName ?? 'seller'}',
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
                    rupees(listing.price),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: uiInk,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rupees(listing.pricePerKg)}/kg',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: uiInkTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
