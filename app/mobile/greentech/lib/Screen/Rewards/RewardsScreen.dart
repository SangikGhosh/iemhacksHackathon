import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class RewardEvent {
  const RewardEvent({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.at,
    required this.icon,
    required this.credited,
  });

  final String title;
  final String subtitle;
  final int points;
  final DateTime? at;
  final dynamic icon;
  final bool credited;
}

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  List<RewardEvent> _events(DetectionHistory? history, List<Pickup> pickups) {
    final events = <RewardEvent>[];

    for (final scan in history?.items ?? const <DetectionHistoryItem>[]) {
      if (scan.totalRewardPoints <= 0) continue;
      events.add(
        RewardEvent(
          title: 'Scanned ${scan.materialSummary}',
          subtitle: '${scan.totalObjects} items identified',
          points: scan.totalRewardPoints,
          at: scan.createdAt,
          icon: HugeIcons.strokeRoundedScanImage,
          credited: scan.pointsAwarded,
        ),
      );
    }

    for (final pickup in pickups) {
      if (pickup.rewardPoints <= 0) continue;
      events.add(
        RewardEvent(
          title: '${pickup.mode.label} pickup',
          subtitle: pickup.status == PickupStatus.completed
              ? 'Collected ${pickup.money.finalWeightKg == null ? '' : kilograms(pickup.money.finalWeightKg!)}'
                    .trim()
              : 'Awarded when the pickup completes',
          points: pickup.rewardPoints,
          at: pickup.completedAt ?? pickup.createdAt,
          icon: HugeIcons.strokeRoundedDeliveryBox01,
          credited: pickup.rewardAwarded,
        ),
      );
    }

    events.sort((a, b) {
      final left = a.at;
      final right = b.at;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });

    return events;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).value;
    final history = ref.watch(detectionHistoryProvider).value;
    final pickups = ref.watch(pickupsProvider).value ?? const <Pickup>[];
    final leaderboard = ref.watch(leaderboardProvider).value;

    final events = _events(history, pickups);
    final pending = events
        .where((event) => !event.credited)
        .fold<int>(0, (sum, event) => sum + event.points);

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        title: 'Rewards',
        subtitle: 'Every scan and pickup earns Green Points',
        onBack: () => _exit(context),
      ),
      body: RefreshIndicator(
        color: uiInk,
        onRefresh: () async {
          await Future.wait([
            ref.read(sessionProvider.notifier).refresh(),
            ref.read(detectionHistoryProvider.notifier).refresh(),
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
              points: user?.points ?? 0,
              rank: leaderboard?.me?.rank,
              pending: pending,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: HugeIcons.strokeRoundedScanImage,
                    value: '${history?.totals.scans ?? 0}',
                    label: 'Scans',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: HugeIcons.strokeRoundedDeliveryBox01,
                    value:
                        '${pickups.where((p) => p.status == PickupStatus.completed).length}',
                    label: 'Pickups done',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: HugeIcons.strokeRoundedLeaf01,
                    value: kilograms(history?.totals.carbonSavedKg ?? 0),
                    label: 'CO₂ saved',
                    accent: uiGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _EarningGuide(),
            const SizedBox(height: 26),
            const UiSectionLabel('Points history'),
            if (events.isEmpty)
              const EmptyState(
                icon: HugeIcons.strokeRoundedStar,
                title: 'No points yet',
                message:
                    'Scan some waste to earn your first Green Points. Drop-offs pay the most.',
              )
            else
              ListCard(
                indent: 52,
                children: [
                  for (final event in events) _RewardRow(event: event),
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
    required this.points,
    required this.rank,
    required this.pending,
  });

  final int points;
  final int? rank;
  final int pending;

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
                icon: HugeIcons.strokeRoundedStar,
                color: Colors.white,
                size: 17,
              ),
              const SizedBox(width: 8),
              Text(
                'YOUR BALANCE',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              if (rank != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rank #$rank',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: points),
            duration: const Duration(milliseconds: 900),
            curve: uiEase,
            builder: (context, value, child) => Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -2,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'points',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          if (pending > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$pending points pending on open pickups',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EarningGuide extends StatelessWidget {
  const _EarningGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: uiGreenSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiGreenLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                color: uiGreen,
                size: 18,
              ),
              const SizedBox(width: 9),
              const Text(
                'How points add up',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: uiInk,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _GuideRow(
            label: 'Scan waste',
            value: 'Instantly, per material',
          ),
          const SizedBox(height: 9),
          const _GuideRow(label: 'Drop off yourself', value: '8 points per kg'),
          const SizedBox(height: 9),
          const _GuideRow(label: 'Doorstep pickup', value: '5 points per kg'),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: uiInkSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: uiInk,
          ),
        ),
      ],
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.event});

  final RewardEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: uiFill,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: HugeIcon(icon: event.icon, color: uiInk, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
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
                  '${event.subtitle} · ${relativeTime(event.at)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${event.points}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: event.credited ? uiGreen : uiInkTertiary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                event.credited ? 'Credited' : 'Pending',
                style: const TextStyle(fontSize: 11.5, color: uiInkTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
