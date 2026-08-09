import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

Color statusColor(PickupStatus status) => switch (status) {
  PickupStatus.requested => const Color(0xFFB4741C),
  PickupStatus.accepted => const Color(0xFF1A73D4),
  PickupStatus.completed => uiGreen,
  PickupStatus.cancelled => uiDanger,
  PickupStatus.unknown => uiInkSecondary,
};

dynamic statusIcon(PickupStatus status) => switch (status) {
  PickupStatus.requested => HugeIcons.strokeRoundedClock01,
  PickupStatus.accepted => HugeIcons.strokeRoundedTruck,
  PickupStatus.completed => HugeIcons.strokeRoundedCheckmarkBadge01,
  PickupStatus.cancelled => HugeIcons.strokeRoundedCancel01,
  PickupStatus.unknown => HugeIcons.strokeRoundedDeliveryBox01,
};

String formatDay(DateTime? value) {
  if (value == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]}';
}

String formatDayTime(DateTime? value) {
  if (value == null) return '—';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour < 12 ? 'am' : 'pm';
  return '${formatDay(value)} · $hour:$minute$suffix';
}

String relativeTime(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatDay(value);
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.compact = false});

  final PickupStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 9 : 11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: statusIcon(status),
            color: color,
            size: compact ? 12 : 14,
          ),
          SizedBox(width: compact ? 5 : 7),
          Text(
            status.label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
    this.onTap,
  });

  final dynamic icon;
  final String value;
  final String label;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = accent ?? uiInk;

    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: tone, size: 18),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: tone,
                letterSpacing: -0.7,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: uiInkSecondary,
            ),
          ),
        ],
      ),
    );

    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: uiInk,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            Pressable(
              onTap: onAction,
              scale: 0.95,
              child: Row(
                children: [
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: uiInkSecondary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    color: uiInkTertiary,
                    size: 15,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ListCard extends StatelessWidget {
  const ListCard({super.key, required this.children, this.indent = 0});

  final List<Widget> children;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiHairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) UiHairline(indent: indent),
            children[index],
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final dynamic icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: uiFill,
                borderRadius: BorderRadius.circular(22),
              ),
              alignment: Alignment.center,
              child: HugeIcon(icon: icon, color: uiInkTertiary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: uiInk,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: uiInkSecondary,
                letterSpacing: -0.1,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              UiSecondaryButton(label: actionLabel!, onTap: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: HugeIcons.strokeRoundedAlert02,
      title: 'Something went wrong',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

class CitizenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CitizenAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: appBackground,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 82,
      titleSpacing: onBack == null ? 20 : 4,
      leading: onBack == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: UiCircleButton(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  onTap: onBack!,
                  size: 40,
                ),
              ),
            ),
      leadingWidth: onBack == null ? null : 72,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: uiInk,
              fontSize: onBack == null ? 32 : 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: uiInkSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}
