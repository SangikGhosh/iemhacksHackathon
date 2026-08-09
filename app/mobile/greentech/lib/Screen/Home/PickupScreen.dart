import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import 'package:greentech/Config/MapConfig.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Screen/Pickup/PickupRequestSheet.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/ToastService.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/MapWidgets/MapCanvas.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class PickupScreen extends ConsumerStatefulWidget {
  const PickupScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends ConsumerState<PickupScreen> {
  final MapController _map = MapController();

  int _filter = 0;
  bool _mapReady = false;

  static const List<String> _filters = ['Active', 'History', 'All'];

  List<Pickup> _visible(List<Pickup> pickups) => switch (_filter) {
    0 => pickups.where((pickup) => pickup.status.isOpen).toList(),
    1 => pickups.where((pickup) => !pickup.status.isOpen).toList(),
    _ => pickups,
  };

  List<Pickup> _mappable(List<Pickup> pickups) => pickups
      .where((pickup) => pickup.status.isOpen && pickup.location.hasCoordinates)
      .toList();

  void _frameMap(List<Pickup> pickups) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      if (_map.camera.nonRotatedSize.shortestSide < 1) return;

      final coords = _mappable(pickups)
          .map(
            (pickup) =>
                LatLng(pickup.location.latitude!, pickup.location.longitude!),
          )
          .toList();

      if (coords.isEmpty) return;
      if (coords.length == 1) {
        _map.move(coords.first, 15);
        return;
      }

      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: coords,
          padding: const EdgeInsets.all(48),
          maxZoom: 15,
        ),
      );
    });
  }

  Future<void> _request() async {
    final pickup = await showPickupRequestSheet(context);
    if (pickup == null || !mounted) return;

    ToastService.show(
      'Pickup requested. We are finding a collector.',
      ToastType.success,
      context,
    );
    await ref.read(pickupsProvider.notifier).refresh();
  }

  Future<void> _cancel(Pickup pickup) async {
    final confirmed = await showUiConfirmSheet(
      context,
      title: 'Cancel this pickup?',
      message:
          'Once a collector accepts, it can no longer be cancelled. You can always request it again.',
      confirmLabel: 'Cancel pickup',
      cancelLabel: 'Keep it',
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(pickupsProvider.notifier).cancel(pickup.id);
      if (!mounted) return;
      ToastService.show('Pickup cancelled.', ToastType.info, context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ToastService.show(error.message, ToastType.error, context);
      await ref.read(pickupsProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(pickupsProvider);
    final pickups = async.value ?? const <Pickup>[];
    final visible = _visible(pickups);
    final mappable = _mappable(pickups);

    final active = pickups.where((p) => p.status.isOpen).length;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        onBack: widget.standalone
            ? () => context.canPop() ? context.pop() : context.go('/home')
            : null,
        title: 'Pickups',
        subtitle: active == 0
            ? 'Nothing scheduled right now'
            : '$active active · ${pickups.length} total',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Pressable(
                onTap: _request,
                scale: 0.92,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: uiInk,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: async.isLoading && pickups.isEmpty
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && pickups.isEmpty
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(pickupsProvider.notifier).refresh(),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(pickupsProvider.notifier).refresh(),
              color: uiInk,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  if (mappable.isNotEmpty) ...[
                    _buildMap(mappable),
                    const SizedBox(height: 20),
                  ],
                  _FilterBar(
                    labels: _filters,
                    selected: _filter,
                    onSelect: (index) => setState(() => _filter = index),
                  ),
                  const SizedBox(height: 18),
                  if (visible.isEmpty)
                    EmptyState(
                      icon: HugeIcons.strokeRoundedDeliveryBox01,
                      title: _filter == 1
                          ? 'No past pickups'
                          : 'No pickups yet',
                      message: _filter == 1
                          ? 'Completed and cancelled pickups will appear here.'
                          : 'Scan some waste, then request a doorstep collection or drop it off yourself.',
                      actionLabel: 'Request a pickup',
                      onAction: _request,
                    )
                  else
                    for (final pickup in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PickupCard(
                          pickup: pickup,
                          onTap: () => context.push('/pickups/${pickup.id}'),
                          onCancel: pickup.cancellable
                              ? () => _cancel(pickup)
                              : null,
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  Widget _buildMap(List<Pickup> mappable) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 210,
        child: MapCanvas(
          controller: _map,
          initialZoom: 13,
          initialCenter: LatLng(
            mappable.first.location.latitude ?? MapConfig.fallbackLat,
            mappable.first.location.longitude ?? MapConfig.fallbackLon,
          ),
          onMapReady: () {
            _mapReady = true;
            _frameMap(ref.read(pickupsProvider).value ?? const []);
          },
          layers: [
            MarkerLayer(
              markers: [
                for (final pickup in mappable)
                  Marker(
                    point: LatLng(
                      pickup.location.latitude!,
                      pickup.location.longitude!,
                    ),
                    width: 44,
                    height: 44,
                    child: _PickupPin(status: pickup.status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickupPin extends StatelessWidget {
  const _PickupPin({required this.status});

  final PickupStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.6),
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.24),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: HugeIcon(
          icon: statusIcon(status),
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
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
                  curve: uiEase,
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
                      fontSize: 14,
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

class PickupCard extends StatelessWidget {
  const PickupCard({
    super.key,
    required this.pickup,
    required this.onTap,
    this.onCancel,
  });

  final Pickup pickup;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final money = pickup.money;

    return Pressable(
      onTap: onTap,
      scale: 0.99,
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
                  relativeTime(pickup.createdAt),
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
            Row(
              children: [
                HugeIcon(
                  icon: pickup.mode == PickupMode.dropOff
                      ? HugeIcons.strokeRoundedLocation01
                      : HugeIcons.strokeRoundedTruck,
                  color: uiInkTertiary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pickup.location.address.isEmpty
                        ? pickup.mode.label
                        : pickup.location.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: uiInkSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(
                  label: money.isSettled ? 'Paid' : 'Estimated',
                  value: rupees(money.payable),
                  accent: money.isSettled ? uiGreen : null,
                ),
                const SizedBox(width: 22),
                _MiniStat(
                  label: pickup.rewardAwarded ? 'Points earned' : 'Points',
                  value: '${pickup.rewardPoints}',
                ),
                if (money.finalWeightKg != null) ...[
                  const SizedBox(width: 22),
                  _MiniStat(
                    label: money.isSettled ? 'Weighed' : 'Est. weight',
                    value: kilograms(money.finalWeightKg!),
                  ),
                ],
              ],
            ),
            if (pickup.hasCollector) ...[
              const SizedBox(height: 16),
              const UiHairline(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: uiFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedTruck,
                      color: uiInk,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pickup.collector!.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: uiInk,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const Text(
                    'Collector',
                    style: TextStyle(fontSize: 12.5, color: uiInkTertiary),
                  ),
                ],
              ),
            ],
            if (onCancel != null) ...[
              const SizedBox(height: 16),
              Pressable(
                onTap: onCancel,
                scale: 0.98,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: uiDangerSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancel pickup',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: uiDanger,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.accent});

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
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: accent ?? uiInk,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: uiInkTertiary)),
      ],
    );
  }
}
