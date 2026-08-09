import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/AppNotification.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/UiKit.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllRead();
    });
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Color _tone(NotificationKind kind) => switch (kind) {
    NotificationKind.pickupAccepted => const Color(0xFF1A73D4),
    NotificationKind.pickupCompleted => uiGreen,
    NotificationKind.pickupCancelled => uiDanger,
    NotificationKind.pickupReleased => uiAmber,
    NotificationKind.pickupRequested => uiInkSecondary,
    NotificationKind.jobAvailable => uiGreen,
  };

  dynamic _icon(NotificationKind kind) => switch (kind) {
    NotificationKind.pickupAccepted => HugeIcons.strokeRoundedTruck,
    NotificationKind.pickupCompleted => HugeIcons.strokeRoundedCheckmarkBadge01,
    NotificationKind.pickupCancelled => HugeIcons.strokeRoundedCancel01,
    NotificationKind.pickupReleased => HugeIcons.strokeRoundedRefresh,
    NotificationKind.pickupRequested => HugeIcons.strokeRoundedDeliveryBox01,
    NotificationKind.jobAvailable => HugeIcons.strokeRoundedPackage,
  };

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CitizenAppBar(
        title: 'Notifications',
        subtitle: items.isEmpty
            ? 'Pickup updates land here'
            : '${items.length} update${items.length == 1 ? '' : 's'}',
        onBack: _exit,
        actions: [
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Center(
                child: Pressable(
                  onTap: () => ref.read(notificationsProvider.notifier).clear(),
                  scale: 0.94,
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: uiInkSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: uiInk,
        onRefresh: () =>
            ref.read(notificationsProvider.notifier).syncFromServer(),
        child: items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: const [
                  SizedBox(height: 60),
                  EmptyState(
                    icon: HugeIcons.strokeRoundedInbox,
                    title: 'Nothing yet',
                    message:
                        'When a collector accepts, completes or cancels one of your pickups, you will see it here.',
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Pressable(
                        onTap: () => context.push('/pickups/${item.pickupId}'),
                        scale: 0.99,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: item.read ? Colors.white : uiFill,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: uiHairline),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _tone(
                                    item.kind,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: HugeIcon(
                                  icon: _icon(item.kind),
                                  color: _tone(item.kind),
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w700,
                                              color: uiInk,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ),
                                        if (!item.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: uiDanger,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.body,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.45,
                                        color: uiInkSecondary,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      relativeTime(item.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: uiInkTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
