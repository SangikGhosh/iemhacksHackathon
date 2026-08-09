import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/UserService.dart';
import 'package:greentech/Utils/avatar_helper.dart';

const _headerColor = Color(0xFFEAEAFA);
const _labelColor = Color(0xFF8E8E9C);
const _dangerColor = Color(0xFFE53935);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Future<AppUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = UserService.getUserDetails();
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }

  Future<void> _signOut() async {
    final router = GoRouter.of(context);

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign out?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'You will need to sign in again to use your account.',
          style: TextStyle(fontSize: 15, height: 1.45, color: _labelColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: _labelColor)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Sign out',
              style: TextStyle(color: _dangerColor),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    await signOutAndReset(ref);
    router.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final sessionUser = ref.watch(sessionProvider).value;

    return Scaffold(
      backgroundColor: _headerColor,
      body: FutureBuilder<AppUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          final user = sessionUser ?? snapshot.data;
          final loading =
              user == null &&
              snapshot.connectionState == ConnectionState.waiting;

          final userName = (user?.fullName.trim().isNotEmpty ?? false)
              ? user!.fullName
              : 'Green Route user';
          final userEmail = user?.email ?? '';

          return Column(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    _buildHeaderBar(),
                    const SizedBox(height: 16),
                    _buildAvatar(userName),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : SafeArea(
                          top: false,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSectionHeader('Personal Info'),
                                const SizedBox(height: 8),
                                _buildDetailTile(
                                  icon: HugeIcons.strokeRoundedUser,
                                  label: 'Your name',
                                  value: userName,
                                ),
                                _buildDetailTile(
                                  icon: HugeIcons.strokeRoundedMail01,
                                  label: 'Email address',
                                  value: userEmail.isEmpty
                                      ? 'Not added'
                                      : userEmail,
                                ),
                                _buildDetailTile(
                                  icon: HugeIcons.strokeRoundedUserGroup,
                                  label: 'Role',
                                  value: (user?.role ?? Role.citizen).label,
                                ),
                                if ((user?.role ?? Role.citizen).earnsRewards)
                                  _buildDetailTile(
                                    icon: HugeIcons.strokeRoundedStar,
                                    label: 'Reward points',
                                    value: '${user?.points ?? 0}',
                                  ),
                                const SizedBox(height: 20),
                                _buildSignOutButton(),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          child: InkWell(
            onTap: _exit,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 34,
              height: 34,
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String userName) {
    return SizedBox(
      width: 116,
      height: 116,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: const Color(0xFFDCDCF2),
              backgroundImage: NetworkImage(
                AvatarHelper.getAvatarForName(userName),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 8,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: _labelColor,
      ),
    );
  }

  Widget _buildDetailTile({
    required dynamic icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HugeIcon(icon: icon, color: Colors.black87, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: _labelColor),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _signOut,
        borderRadius: BorderRadius.circular(10),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLogout01,
                color: _dangerColor,
                size: 21,
              ),
              SizedBox(width: 14),
              Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _dangerColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
