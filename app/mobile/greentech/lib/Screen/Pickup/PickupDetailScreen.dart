import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/ToastService.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/MapWidgets/MapCanvas.dart';
import 'package:greentech/Widget/UiKit.dart';

class PickupDetailScreen extends ConsumerStatefulWidget {
  const PickupDetailScreen({super.key, required this.pickupId});

  final String pickupId;

  @override
  ConsumerState<PickupDetailScreen> createState() => _PickupDetailScreenState();
}

class _PickupDetailScreenState extends ConsumerState<PickupDetailScreen> {
  final MapController _map = MapController();

  Pickup? _pickup;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _seedFromCache();
    _load();
  }

  void _seedFromCache() {
    final cached = ref.read(pickupsProvider).value;
    if (cached == null) return;
    for (final pickup in cached) {
      if (pickup.id == widget.pickupId) {
        _pickup = pickup;
        _loading = false;
        break;
      }
    }
  }

  Future<void> _load() async {
    try {
      final pickup = await ApiService.pickup(widget.pickupId);
      if (!mounted) return;
      setState(() {
        _pickup = pickup;
        _loading = false;
        _error = null;
      });
      ref.read(pickupsProvider.notifier).adopt(pickup);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_pickup == null) _error = error.message;
      });
    }
  }

  Future<void> _cancel() async {
    final pickup = _pickup;
    if (pickup == null) return;

    final confirmed = await showUiConfirmSheet(
      context,
      title: 'Cancel this pickup?',
      message:
          'Once a collector accepts, it can no longer be cancelled. You can request it again later.',
      confirmLabel: 'Cancel pickup',
      cancelLabel: 'Keep it',
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    try {
      final cancelled = await ref
          .read(pickupsProvider.notifier)
          .cancel(pickup.id);
      if (!mounted) return;
      setState(() => _pickup = cancelled);
      ToastService.show('Pickup cancelled.', ToastType.info, context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ToastService.show(error.message, ToastType.error, context);
      await _load();
    }
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/pickup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickup;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CitizenAppBar(
        title: 'Pickup',
        subtitle: pickup == null ? null : '#${pickup.shortId}',
        onBack: _exit,
      ),
      body: _loading && pickup == null
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : pickup == null
          ? ErrorRetry(message: _error ?? 'Pickup not found', onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              color: uiInk,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  _StatusBanner(pickup: pickup),
                  const SizedBox(height: 22),
                  _Timeline(pickup: pickup),
                  const SizedBox(height: 26),
                  const UiSectionLabel('Waste'),
                  ListCard(
                    indent: 0,
                    children: [
                      _DetailRow(
                        label: 'Materials',
                        value: pickup.materials.isEmpty
                            ? '${pickup.totalObjects} items'
                            : pickup.materials,
                      ),
                      _DetailRow(
                        label: 'Items',
                        value: '${pickup.totalObjects}',
                      ),
                      _DetailRow(label: 'Mode', value: pickup.mode.label),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const UiSectionLabel('Money'),
                  _MoneyCard(pickup: pickup),
                  const SizedBox(height: 22),
                  const UiSectionLabel('Where'),
                  if (pickup.location.hasCoordinates) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 170,
                        child: MapCanvas(
                          controller: _map,
                          initialZoom: 15,
                          initialCenter: LatLng(
                            pickup.location.latitude!,
                            pickup.location.longitude!,
                          ),
                          interactive: false,
                          layers: [
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    pickup.location.latitude!,
                                    pickup.location.longitude!,
                                  ),
                                  width: 44,
                                  height: 44,
                                  child: const _DestinationPin(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ListCard(
                    indent: 0,
                    children: [
                      _DetailRow(
                        label: 'Address',
                        value: pickup.location.address.isEmpty
                            ? 'Not provided'
                            : pickup.location.address,
                      ),
                      if ((pickup.location.landmark ?? '').isNotEmpty)
                        _DetailRow(
                          label: 'Landmark',
                          value: pickup.location.landmark!,
                        ),
                      if (pickup.contactPhone.isNotEmpty)
                        _DetailRow(label: 'Phone', value: pickup.contactPhone),
                      if ((pickup.notes ?? '').isNotEmpty)
                        _DetailRow(label: 'Notes', value: pickup.notes!),
                    ],
                  ),
                  if (pickup.hasCollector) ...[
                    const SizedBox(height: 22),
                    const UiSectionLabel('Collector'),
                    _CollectorCard(pickup: pickup),
                  ],
                  if ((pickup.cancelReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: uiDangerSoft,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        'Cancelled: ${pickup.cancelReason}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: uiDanger,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  if (pickup.cancellable)
                    Pressable(
                      onTap: _cancel,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: uiDangerSoft,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel pickup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: uiDanger,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    )
                  else if (pickup.status == PickupStatus.accepted)
                    const AuthLockNote(
                      'A collector has accepted this pickup, so it can no longer be cancelled.',
                    ),
                ],
              ),
            ),
    );
  }
}

class AuthLockNote extends StatelessWidget {
  const AuthLockNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedLocked,
            color: uiInkTertiary,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: uiInkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.pickup});

  final Pickup pickup;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(pickup.status);

    final message = switch (pickup.status) {
      PickupStatus.requested =>
        'We are finding a collector near you. You can still cancel.',
      PickupStatus.accepted =>
        '${pickup.collector?.fullName ?? 'A collector'} is on the way.',
      PickupStatus.completed =>
        'Collected and paid. ${pickup.rewardPoints} points were added to your balance.',
      PickupStatus.cancelled => 'This pickup was called off.',
      PickupStatus.unknown => '',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: HugeIcon(
              icon: statusIcon(pickup.status),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup.status.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: uiInk,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: uiInkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.pickup});

  final Pickup pickup;

  @override
  Widget build(BuildContext context) {
    final steps = <({String label, DateTime? at, bool done})>[
      (
        label: 'Requested',
        at: pickup.createdAt,
        done: pickup.createdAt != null,
      ),
      (
        label: 'Collector accepted',
        at: pickup.acceptedAt,
        done: pickup.acceptedAt != null,
      ),
      if (pickup.status == PickupStatus.cancelled)
        (
          label: 'Cancelled',
          at: pickup.cancelledAt,
          done: pickup.cancelledAt != null,
        )
      else
        (
          label: 'Collected and paid',
          at: pickup.completedAt,
          done: pickup.completedAt != null,
        ),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiHairline),
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++)
            _TimelineRow(
              label: steps[index].label,
              at: steps[index].at,
              done: steps[index].done,
              last: index == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.at,
    required this.done,
    required this.last,
  });

  final String label;
  final DateTime? at;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: done ? uiGreen : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? uiGreen : uiHairlineStrong,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: done ? uiGreen.withValues(alpha: 0.35) : uiHairline,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 16 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: done ? uiInk : uiInkTertiary,
                      letterSpacing: -0.2,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    at == null ? 'Pending' : formatDayTime(at),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: uiInkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.pickup});

  final Pickup pickup;

  @override
  Widget build(BuildContext context) {
    final money = pickup.money;
    final settled = money.isSettled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settled ? 'PAID OUT' : 'ESTIMATED OFFER',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: uiInkTertiary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            rupees(money.payable),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w700,
              color: settled ? uiGreen : uiInk,
              letterSpacing: -1.6,
              height: 1.0,
            ),
          ),
          if (!settled) ...[
            const SizedBox(height: 10),
            const Text(
              'This is an estimate from the photo. The collector weighs the waste and confirms the final amount.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: uiInkSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Estimated ${rupees(money.estimatedOffer)} · weighed '
              '${money.finalWeightKg == null ? '—' : kilograms(money.finalWeightKg!)}',
              style: const TextStyle(fontSize: 13, color: uiInkSecondary),
            ),
          ],
          const SizedBox(height: 16),
          const UiHairline(),
          const SizedBox(height: 14),
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedStar,
                color: uiGreen,
                size: 17,
              ),
              const SizedBox(width: 9),
              Text(
                '${pickup.rewardPoints} points',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: uiInk,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                pickup.rewardAwarded ? 'Credited' : 'On completion',
                style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectorCard extends StatelessWidget {
  const _CollectorCard({required this.pickup});

  final Pickup pickup;

  @override
  Widget build(BuildContext context) {
    final collector = pickup.collector!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: uiHairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: uiFill,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedTruck,
                  color: uiInk,
                  size: 21,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collector.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: uiInk,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      collector.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: uiInkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((pickup.collectorNotes ?? '').isNotEmpty) ...[
            const SizedBox(height: 16),
            const UiHairline(),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedNote,
                  color: uiInkTertiary,
                  size: 16,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    pickup.collectorNotes!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: uiInkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: uiInkTertiary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: uiInk,
                height: 1.4,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: uiInk,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.8),
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedLocation01,
          color: Colors.white,
          size: 17,
        ),
      ),
    );
  }
}
