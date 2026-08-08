import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Service/ToastService.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final user = ref.watch(sessionProvider).value;

    if (user == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: Center(child: CircularProgressIndicator(color: colors.onSurface)),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primary,
          backgroundColor: colors.surfaceContainerLowest,
          onRefresh: ref.read(sessionProvider.notifier).refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _Greeting(user: user),
              const SizedBox(height: 22),
              _PointsCard(user: user),
              const SizedBox(height: 22),
              const _SectionTitle('Quick actions'),
              const SizedBox(height: 12),
              _Actions(role: user.role),
              const SizedBox(height: 26),
              const _SectionTitle('Your account'),
              const SizedBox(height: 12),
              _AccountCard(user: user),
              const SizedBox(height: 22),
              const _SignOutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _partOfDay(),
                style: TextStyle(fontSize: 12.5, color: colors.outline),
              ),
              const SizedBox(height: 3),
              Text(
                user.firstName,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.6,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.onSurface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            user.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _partOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: colors.onSurface,
        borderRadius: BorderRadius.circular(22),
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
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.eco_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Reward points',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${user.points}',
                style: const TextStyle(
                  fontSize: 42,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'pts',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Earned for correct segregation and disposal. Pull down to refresh.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.role});

  final Role role;

  List<(IconData, String)> get _tiles => switch (role) {
    Role.collector => const [
      (Icons.map_outlined, 'Today’s route'),
      (Icons.qr_code_scanner_rounded, 'Scan pickup'),
      (Icons.inventory_2_outlined, 'Load manifest'),
      (Icons.history_rounded, 'History'),
    ],
    Role.recycler => const [
      (Icons.inbox_rounded, 'Incoming batches'),
      (Icons.scale_outlined, 'Log processed'),
      (Icons.insights_rounded, 'Yield report'),
      (Icons.history_rounded, 'History'),
    ],
    _ => const [
      (Icons.delete_outline_rounded, 'Log waste'),
      (Icons.calendar_today_outlined, 'Pickup schedule'),
      (Icons.card_giftcard_rounded, 'Redeem points'),
      (Icons.report_gmailerrorred_rounded, 'Report dumping'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 11,
      crossAxisSpacing: 11,
      childAspectRatio: 1.55,
      children: [
        for (final (icon, label) in _tiles)
          _ActionTile(icon: icon, label: label),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ToastService.show(
          '$label is coming soon.',
          ToastType.info,
          context,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 21, color: colors.primary),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final divider = Divider(height: 1, color: colors.outlineVariant);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          _Row(label: 'Name', value: user.fullName),
          divider,
          _Row(label: 'Email', value: user.email),
          divider,
          _Row(label: 'Role', value: user.role.label),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, color: colors.outline)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _confirm(context, ref),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.logout_rounded, size: 18),
      label: const Text(
        'Sign out',
        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final colors = Theme.of(context).colorScheme;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?', style: TextStyle(fontSize: 18)),
        content: Text(
          'You will need your email and password to get back in.',
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: colors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Sign out', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    await ref.read(sessionProvider.notifier).signOut();
    router.go('/auth');
  }
}
