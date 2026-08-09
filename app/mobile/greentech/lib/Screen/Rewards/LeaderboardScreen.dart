import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Leaderboard.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Screen/Home/HomeScreen.dart' show LeaderRow;
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  void _exit(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardProvider);
    final board = async.value;
    final meId = ref.watch(sessionProvider).value?.id;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        title: 'Leaderboard',
        subtitle: board == null
            ? 'All time'
            : '${board.totals.citizens} citizens · ${board.totals.points} points',
        onBack: () => _exit(context),
      ),
      body: async.isLoading && board == null
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && board == null
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(leaderboardProvider.notifier).refresh(),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        ref.read(leaderboardProvider.notifier).refresh(),
                    color: uiInk,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        _CommunityCard(totals: board!.totals),
                        const SizedBox(height: 24),
                        if (board.entries.length >= 3) ...[
                          _Podium(entries: board.entries.take(3).toList()),
                          const SizedBox(height: 24),
                        ],
                        const UiSectionLabel('Everyone'),
                        if (board.entries.isEmpty)
                          const EmptyState(
                            icon: HugeIcons.strokeRoundedRanking,
                            title: 'No scores yet',
                            message:
                                'Be the first to scan waste and claim the top spot.',
                          )
                        else
                          ListCard(
                            indent: 48,
                            children: [
                              for (final entry in board.entries)
                                LeaderRow(
                                  entry: entry,
                                  highlight: entry.userId == meId,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                if (board.me != null && !board.meIsVisible)
                  _MeFooter(me: board.me!),
              ],
            ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.totals});

  final LeaderboardTotals totals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMMUNITY IMPACT',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: uiInkTertiary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Total(
                  value: '${totals.points}',
                  label: 'Points earned',
                ),
              ),
              Expanded(
                child: _Total(
                  value: kilograms(totals.weightKg),
                  label: 'Waste collected',
                  accent: uiGreen,
                ),
              ),
              Expanded(
                child: _Total(
                  value: '${totals.completedPickups}',
                  label: 'Pickups done',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({required this.value, required this.label, this.accent});

  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accent ?? uiInk,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: uiInkSecondary),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ordered = [entries[1], entries[0], entries[2]];
    final heights = [96.0, 124.0, 80.0];

    return SizedBox(
      height: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < ordered.length; index++)
            Expanded(
              child: _PodiumColumn(
                entry: ordered[index],
                height: heights[index],
                crown: index == 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.height,
    required this.crown,
  });

  final LeaderboardEntry entry;
  final double height;
  final bool crown;

  static const List<Color> _medals = [
    Color(0xFFD4A017),
    Color(0xFF9AA0A6),
    Color(0xFFB07B4F),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _medals[(entry.rank - 1).clamp(0, 2)];
    final initials = entry.fullName.trim().isEmpty
        ? '?'
        : entry.fullName
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((p) => p[0])
              .join()
              .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (crown)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedChampion,
                color: Color(0xFFD4A017),
                size: 22,
              ),
            ),
          Container(
            width: crown ? 54 : 46,
            height: crown ? 54 : 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: crown ? 18 : 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.fullName.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: uiInk,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                Text(
                  '${entry.points}',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'pts',
                  style: TextStyle(fontSize: 11, color: uiInkTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MeFooter extends StatelessWidget {
  const _MeFooter({required this.me});

  final LeaderboardMe me;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: uiInk,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: uiInk.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '${me.rank}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your position',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  me.ahead == 0
                      ? 'You are in the lead'
                      : '${me.ahead} ${me.ahead == 1 ? 'person' : 'people'} ahead of you',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${me.points}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
