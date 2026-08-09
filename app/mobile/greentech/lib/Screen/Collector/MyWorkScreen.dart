import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Screen/Collector/CompleteSheet.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class MyWorkScreen extends ConsumerStatefulWidget {
  const MyWorkScreen({super.key});

  @override
  ConsumerState<MyWorkScreen> createState() => _MyWorkScreenState();
}

class _MyWorkScreenState extends ConsumerState<MyWorkScreen> {
  int _tab = 0;

  Future<void> _complete(Pickup pickup) async {
    final changed = await showCompleteSheet(context, pickup: pickup);
    if (changed != true || !mounted) return;

    await Future.wait([
      ref.read(pickupsProvider.notifier).refresh(),
      ref.read(routeProvider.notifier).refresh(),
      ref.read(availableJobsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pickupsProvider);
    final all = async.value ?? const <Pickup>[];

    final active = all.where((p) => p.status == PickupStatus.accepted).toList();
    final done = all.where((p) => p.status == PickupStatus.completed).toList();

    final earned = done.fold<double>(
      0,
      (sum, p) => sum + (p.money.finalAmount ?? 0),
    );
    final weight = done.fold<double>(
      0,
      (sum, p) => sum + (p.money.finalWeightKg ?? 0),
    );

    final visible = _tab == 0 ? active : done;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        title: 'My work',
        subtitle: '${active.length} to collect · ${done.length} done',
      ),
      body: async.isLoading && all.isEmpty
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && all.isEmpty
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(pickupsProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              color: uiInk,
              onRefresh: () => ref.read(pickupsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          icon: HugeIcons.strokeRoundedCoins01,
                          value: rupees(earned),
                          label: 'Paid out',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricTile(
                          icon: HugeIcons.strokeRoundedWeightScale01,
                          value: kilograms(weight),
                          label: 'Collected',
                          accent: uiGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricTile(
                          icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                          value: '${done.length}',
                          label: 'Jobs done',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CashNote(),
                  const SizedBox(height: 22),
                  _Tabs(
                    selected: _tab,
                    labels: ['To collect (${active.length})', 'History'],
                    onSelect: (index) => setState(() => _tab = index),
                  ),
                  const SizedBox(height: 18),
                  if (visible.isEmpty)
                    EmptyState(
                      icon: HugeIcons.strokeRoundedDeliveryBox01,
                      title: _tab == 0
                          ? 'Nothing to collect'
                          : 'No history yet',
                      message: _tab == 0
                          ? 'Accept a job from the Open jobs tab and it lands here.'
                          : 'Completed collections and what you paid will show up here.',
                    )
                  else
                    for (final pickup in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WorkCard(
                          pickup: pickup,
                          onComplete: pickup.status == PickupStatus.accepted
                              ? () => _complete(pickup)
                              : null,
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _CashNote extends StatelessWidget {
  const _CashNote();

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
        const Expanded(
          child: Text(
            'Pickup money is settled in cash with the citizen. It never passes through your wallet.',
            style: TextStyle(
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
  const _Tabs({
    required this.selected,
    required this.labels,
    required this.onSelect,
  });

  final int selected;
  final List<String> labels;
  final ValueChanged<int> onSelect;

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
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: Pressable(
                onTap: () => onSelect(index),
                scale: 0.97,
                child: AnimatedContainer(
                  duration: uiQuick,
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
                    labels[index],
                    style: TextStyle(
                      fontSize: 13.5,
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

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.pickup, this.onComplete});

  final Pickup pickup;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final money = pickup.money;
    final settled = money.isSettled;

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
              StatusChip(status: pickup.status),
              const Spacer(),
              Text(
                relativeTime(pickup.completedAt ?? pickup.acceptedAt),
                style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            pickup.materials.isEmpty
                ? '${pickup.totalObjects} items'
                : pickup.materials,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: uiInk,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pickup.location.address.isEmpty
                ? pickup.mode.label
                : pickup.location.address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, color: uiInkSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Mini(
                label: settled ? 'Paid' : 'Est. offer',
                value: rupees(
                  settled ? money.finalAmount! : money.estimatedOffer,
                ),
                accent: settled ? uiGreen : null,
              ),
              const SizedBox(width: 22),
              _Mini(
                label: settled ? 'Weighed' : 'Est. weight',
                value: money.finalWeightKg == null
                    ? '—'
                    : kilograms(money.finalWeightKg!),
              ),
              if (settled) ...[
                const SizedBox(width: 22),
                _Mini(label: 'Citizen points', value: '${pickup.rewardPoints}'),
              ],
            ],
          ),
          if (pickup.citizen != null) ...[
            const SizedBox(height: 14),
            const UiHairline(),
            const SizedBox(height: 12),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: uiInkTertiary,
                  size: 15,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    pickup.citizen!.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: uiInkSecondary,
                    ),
                  ),
                ),
                if (pickup.contactPhone.isNotEmpty)
                  Text(
                    pickup.contactPhone,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: uiInk,
                    ),
                  ),
              ],
            ),
          ],
          if (onComplete != null) ...[
            const SizedBox(height: 16),
            Pressable(
              onTap: onComplete,
              scale: 0.98,
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: uiInk,
                  borderRadius: BorderRadius.circular(23),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Weigh and complete',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: accent ?? uiInk,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: uiInkTertiary),
        ),
      ],
    );
  }
}
