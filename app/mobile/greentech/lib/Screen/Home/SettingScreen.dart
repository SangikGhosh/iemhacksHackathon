import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Utils/avatar_helper.dart';
import 'package:greentech/Widget/UiKit.dart';

const String _appVersion = '1.0.0';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    final confirmed = await showUiConfirmSheet(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to scan waste or track pickups.',
      confirmLabel: 'Sign out',
      destructive: true,
    );

    if (confirmed != true) return;

    await ref.read(sessionProvider.notifier).signOut();
    router.go('/auth');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final user = session.value;
    final loading = user == null && session.isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(user),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IdentityCard(user: user),
                  const SizedBox(height: 14),
                  _StatRow(user: user),
                  const SizedBox(height: 30),
                  const UiSectionLabel('Account'),
                  _Group(
                    rows: [
                      _Row(
                        icon: HugeIcons.strokeRoundedUser,
                        title: 'Manage profile',
                        subtitle: 'Name, email and role',
                        onTap: () => context.push('/profile'),
                      ),
                      const _Row(
                        icon: HugeIcons.strokeRoundedLockPassword,
                        title: 'Password & security',
                        soon: true,
                      ),
                      const _Row(
                        icon: HugeIcons.strokeRoundedNotification01,
                        title: 'Notifications',
                        soon: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const UiSectionLabel('Activity'),
                  _Group(
                    rows: [
                      _Row(
                        icon: HugeIcons.strokeRoundedDeliveryBox01,
                        title: 'My pickups',
                        subtitle: 'Requests and collections',
                        onTap: () => context.go('/pickup'),
                      ),
                      const _Row(
                        icon: HugeIcons.strokeRoundedScanImage,
                        title: 'Scan history',
                        soon: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const UiSectionLabel('Preferences'),
                  const _Group(
                    rows: [
                      _Row(
                        icon: HugeIcons.strokeRoundedMoon02,
                        title: 'Appearance',
                        value: 'Light',
                        soon: true,
                      ),
                      _Row(
                        icon: HugeIcons.strokeRoundedTranslate,
                        title: 'Language',
                        value: 'English',
                        soon: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const UiSectionLabel('Support'),
                  const _Group(
                    rows: [
                      _Row(
                        icon: HugeIcons.strokeRoundedHelpCircle,
                        title: 'Help & support',
                        soon: true,
                      ),
                      _Row(
                        icon: HugeIcons.strokeRoundedInformationCircle,
                        title: 'About Green Route',
                        soon: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  _SignOutButton(onTap: () => _signOut(context, ref)),
                  const SizedBox(height: 22),
                  const _VersionFootnote(),
                ],
              ),
            ),
    );
  }

  AppBar _buildAppBar(AppUser? user) {
    final role = (user?.role ?? Role.citizen).label;

    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 82,
      titleSpacing: 20,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: uiInk,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$role account',
            style: const TextStyle(
              color: uiInkSecondary,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Green Route user';
    final email = user?.email ?? '';

    return Pressable(
      onTap: () => context.push('/profile'),
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: uiInk,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
              ),
              child: CircleAvatar(
                radius: 29,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                backgroundImage: NetworkImage(
                  AvatarHelper.getAvatarForName(name),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.isEmpty ? 'No email on file' : email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.62),
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: HugeIcons.strokeRoundedStar,
            value: '${user?.points ?? 0}',
            label: 'Reward points',
            accent: uiGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: HugeIcons.strokeRoundedUserGroup,
            value: (user?.role ?? Role.citizen).label,
            label: 'Your role',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  final dynamic icon;
  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? uiInk;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: tone, size: 20),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: tone,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: uiInkSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiHairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const UiHairline(indent: 54),
            rows[index],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
    this.soon = false,
  });

  final dynamic icon;
  final String title;
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final muted = soon || onTap == null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: HugeIcon(
              icon: icon,
              color: muted ? uiInkTertiary : uiInk,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: muted ? uiInkSecondary : uiInk,
                    letterSpacing: -0.25,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: uiInkTertiary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            Text(
              value!,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: uiInkTertiary,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 10),
          ],
          if (soon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: uiFill,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Text(
                'Soon',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: uiInkTertiary,
                  letterSpacing: 0.2,
                ),
              ),
            )
          else
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: uiInkTertiary,
              size: 18,
            ),
        ],
      ),
    );

    if (soon || onTap == null) return content;

    return Pressable(onTap: onTap, scale: 0.99, child: content);
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: uiDangerSoft,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedLogout01,
              color: uiDanger,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Sign out',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: uiDanger,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionFootnote extends StatelessWidget {
  const _VersionFootnote();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Green Route',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: uiInkTertiary,
            letterSpacing: -0.1,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Version $_appVersion',
          style: TextStyle(fontSize: 12.5, color: uiInkTertiary),
        ),
      ],
    );
  }
}
