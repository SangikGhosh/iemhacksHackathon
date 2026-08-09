import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Model/Leaderboard.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Utils/avatar_helper.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationsProvider.notifier).syncFromServer();
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(sessionProvider.notifier).refresh(),
      ref.read(leaderboardProvider.notifier).refresh(),
      ref.read(detectionHistoryProvider.notifier).refresh(),
      ref.read(pickupsProvider.notifier).refresh(),
      ref.read(walletProvider.notifier).refresh(),
    ]);
    await ref.read(notificationsProvider.notifier).syncFromServer();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value;
    final history = ref.watch(detectionHistoryProvider).value;
    final pickups = ref.watch(pickupsProvider).value ?? const <Pickup>[];
    final leaderboard = ref.watch(leaderboardProvider).value;
    final unread = ref
        .watch(notificationsProvider)
        .where((item) => !item.read)
        .length;

    final active = pickups.where((pickup) => pickup.status.isOpen).toList();

    return Scaffold(
      backgroundColor: appBackground,
      appBar: _buildAppBar(user, unread),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: uiInk,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
          children: [
            _PointsHero(
              points: user?.points ?? 0,
              rank: leaderboard?.me?.rank,
              ahead: leaderboard?.me?.ahead,
              onTap: () => context.push('/rewards'),
            ),
            const SizedBox(height: 14),
            _ImpactRow(totals: history?.totals ?? DetectionTotals.empty),
            const SizedBox(height: 14),
            _AssistantCard(onTap: () => context.push('/chat')),
            if (active.isNotEmpty) ...[
              const SizedBox(height: 28),
              SectionHeader(
                'Active pickup${active.length == 1 ? '' : 's'}',
                actionLabel: 'All',
                onAction: () => context.go('/pickup'),
              ),
              _ActivePickupCard(
                pickup: active.first,
                onTap: () => context.push('/pickups/${active.first.id}'),
              ),
            ],
            const SizedBox(height: 28),
            const SectionHeader('What would you like to do?'),
            _ActionGrid(),
            const SizedBox(height: 28),
            SectionHeader(
              'Leaderboard',
              actionLabel: 'Full board',
              onAction: () => context.push('/leaderboard'),
            ),
            _LeaderboardPreview(
              leaderboard: leaderboard,
              meId: user?.id,
              onTap: () => context.push('/leaderboard'),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppUser? user, int unread) {
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.firstName
        : 'there';

    return CitizenAppBar(
      title: 'Hi, $name',
      subtitle: 'Turn waste into points',
      actions: [
        _BellButton(
          unread: unread,
          onTap: () => context.push('/notifications'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20, left: 6),
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
    );
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                color: uiInk,
                size: 23,
              ),
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 17),
                    decoration: BoxDecoration(
                      color: uiDanger,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1.6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointsHero extends StatelessWidget {
  const _PointsHero({
    required this.points,
    required this.rank,
    required this.ahead,
    required this.onTap,
  });

  final int points;
  final int? rank;
  final int? ahead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
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
                  'GREEN POINTS',
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
              builder: (context, value, child) => Text(
                '$value',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ahead == null
                  ? 'Scan waste to start earning'
                  : ahead == 0
                  ? 'You are leading the community'
                  : '$ahead ${ahead == 1 ? 'person is' : 'people are'} ahead of you',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.66),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.totals});

  final DetectionTotals totals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricTile(
            icon: HugeIcons.strokeRoundedScanImage,
            value: '${totals.scans}',
            label: 'Scans',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricTile(
            icon: HugeIcons.strokeRoundedLeaf01,
            value: kilograms(totals.carbonSavedKg),
            label: 'CO₂ saved',
            accent: uiGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricTile(
            icon: HugeIcons.strokeRoundedRecycle01,
            value: '${totals.objects}',
            label: 'Items',
          ),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = <_HomeAction>[
      _HomeAction(
        icon: HugeIcons.strokeRoundedScanImage,
        title: 'Scan waste',
        subtitle: 'Identify and price it',
        onTap: () => context.go('/image'),
        primary: true,
      ),
      _HomeAction(
        icon: HugeIcons.strokeRoundedDeliveryBox01,
        title: 'Pickups',
        subtitle: 'Request and track',
        onTap: () => context.go('/pickup'),
      ),
      _HomeAction(
        icon: HugeIcons.strokeRoundedWallet01,
        title: 'Wallet',
        subtitle: 'Payments and balance',
        onTap: () => context.push('/wallet'),
      ),
      _HomeAction(
        icon: HugeIcons.strokeRoundedStar,
        title: 'Rewards',
        subtitle: 'Points history',
        onTap: () => context.push('/rewards'),
      ),
      _HomeAction(
        icon: HugeIcons.strokeRoundedShoppingBag01,
        title: 'Sell waste',
        subtitle: 'List for recyclers',
        onTap: () => context.push('/listings'),
      ),
      _HomeAction(
        icon: HugeIcons.strokeRoundedRanking,
        title: 'Leaderboard',
        subtitle: 'Community ranking',
        onTap: () => context.push('/leaderboard'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.32,
      ),
      itemBuilder: (context, index) => _ActionCard(action: actions[index]),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _HomeAction action;

  @override
  Widget build(BuildContext context) {
    final dark = action.primary;

    return Pressable(
      onTap: action.onTap,
      scale: 0.97,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
        decoration: BoxDecoration(
          color: dark ? uiInk : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: dark ? null : Border.all(color: uiHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dark ? Colors.white.withValues(alpha: 0.14) : uiFill,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: HugeIcon(
                icon: action.icon,
                color: dark ? Colors.white : uiInk,
                size: 19,
              ),
            ),
            const Spacer(),
            Text(
              action.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : uiInk,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              action.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: dark
                    ? Colors.white.withValues(alpha: 0.6)
                    : uiInkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePickupCard extends StatelessWidget {
  const _ActivePickupCard({required this.pickup, required this.onTap});

  final Pickup pickup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
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
              children: [
                StatusChip(status: pickup.status),
                const Spacer(),
                Text(
                  pickup.mode.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: uiInkTertiary,
                  ),
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
                  ? 'Requested ${relativeTime(pickup.createdAt)}'
                  : pickup.location.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, color: uiInkSecondary),
            ),
            const SizedBox(height: 16),
            _PickupTracker(pickup: pickup),
          ],
        ),
      ),
    );
  }
}

class _PickupTracker extends StatelessWidget {
  const _PickupTracker({required this.pickup});

  final Pickup pickup;

  @override
  Widget build(BuildContext context) {
    final steps = ['Requested', 'Accepted', 'Collected'];
    final reached = switch (pickup.status) {
      PickupStatus.requested => 1,
      PickupStatus.accepted => 2,
      PickupStatus.completed => 3,
      _ => 0,
    };

    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: index < reached ? uiGreen : uiFillStrong,
              ),
            ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: index < reached ? uiGreen : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: index < reached ? uiGreen : uiHairlineStrong,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: index < reached ? uiInk : uiInkTertiary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LeaderboardPreview extends StatelessWidget {
  const _LeaderboardPreview({
    required this.leaderboard,
    required this.meId,
    required this.onTap,
  });

  final Leaderboard? leaderboard;
  final String? meId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final board = leaderboard;

    if (board == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: uiFill,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: uiInk, strokeWidth: 2.5),
      );
    }

    if (board.entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: uiFill,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Text(
          'No one has scored yet. Scan some waste to take the top spot.',
          style: TextStyle(fontSize: 14.5, height: 1.4, color: uiInkSecondary),
        ),
      );
    }

    final top = board.entries.take(3).toList();

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: ListCard(
        indent: 48,
        children: [
          for (final entry in top)
            LeaderRow(entry: entry, highlight: entry.userId == meId),
        ],
      ),
    );
  }
}

class LeaderRow extends StatelessWidget {
  const LeaderRow({super.key, required this.entry, required this.highlight});

  final LeaderboardEntry entry;
  final bool highlight;

  static const List<Color> _medals = [
    Color(0xFFD4A017),
    Color(0xFF9AA0A6),
    Color(0xFFB07B4F),
  ];

  @override
  Widget build(BuildContext context) {
    final medal = entry.rank <= 3 ? _medals[entry.rank - 1] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: medal?.withValues(alpha: 0.14) ?? uiFill,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: medal ?? uiInkSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: uiInk,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                    if (highlight) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: uiGreen.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: uiGreen,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.completedPickups} pickup'
                  '${entry.completedPickups == 1 ? '' : 's'} · '
                  '${kilograms(entry.totalWeightKg)}',
                  style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${entry.points}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: uiInk,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: uiHairline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: uiInk,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedSparkles,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ask Green Route',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: uiInk,
                      letterSpacing: -0.35,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Points, pickups and prices — answered',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: uiInkTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: uiInkTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
