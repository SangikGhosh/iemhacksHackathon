import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/CollectorRoute.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Screen/Collector/CompleteSheet.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/MapWidgets/MapCanvas.dart';
import 'package:greentech/Widget/UiKit.dart';

class RouteScreen extends ConsumerStatefulWidget {
  const RouteScreen({super.key});

  @override
  ConsumerState<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends ConsumerState<RouteScreen> {
  final MapController _map = MapController();
  bool _mapReady = false;
  int _selected = -1;

  void _frameMap(CollectorRoute route) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      if (_map.camera.nonRotatedSize.shortestSide < 1) return;

      final points = route.line.isNotEmpty ? route.line : route.allPoints;
      if (points.isEmpty) return;
      if (points.length == 1) {
        _map.move(points.first, 14);
        return;
      }

      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(44),
          maxZoom: 15,
        ),
      );
    });
  }

  Pickup? _pickupFor(RouteStop stop) {
    final assigned = ref.read(pickupsProvider).value ?? const <Pickup>[];
    for (final id in stop.pickupIds) {
      for (final pickup in assigned) {
        if (pickup.id == id && pickup.status == PickupStatus.accepted) {
          return pickup;
        }
      }
    }
    return null;
  }

  Future<void> _openStop(RouteStop stop) async {
    final pickup = _pickupFor(stop);
    if (pickup == null) return;

    final changed = await showCompleteSheet(context, pickup: pickup);
    if (changed != true || !mounted) return;

    await Future.wait([
      ref.read(pickupsProvider.notifier).refresh(),
      ref.read(routeProvider.notifier).refresh(),
      ref.read(availableJobsProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(routeProvider);
    final route = async.value;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CitizenAppBar(
        title: 'Today’s route',
        subtitle: route == null
            ? 'Nothing planned yet'
            : '${route.totalRequests} request'
                  '${route.totalRequests == 1 ? '' : 's'} · '
                  '${route.totalStops} stop${route.totalStops == 1 ? '' : 's'}',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Pressable(
                onTap: () => ref.read(routeProvider.notifier).refresh(),
                scale: 0.92,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: uiFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedRefresh,
                    color: uiInk,
                    size: 19,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: async.isLoading && route == null
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : async.hasError && route == null
          ? ErrorRetry(
              message: '${async.error}',
              onRetry: () => ref.read(routeProvider.notifier).refresh(),
            )
          : route == null
          ? EmptyState(
              icon: HugeIcons.strokeRoundedRoute01,
              title: 'No route yet',
              message:
                  'Accept some jobs and we will plan the fastest loop from the depot and back.',
              actionLabel: 'Refresh',
              onAction: () => ref.read(routeProvider.notifier).refresh(),
            )
          : Column(
              children: [
                SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildMap(route)),
                      if (route.isStraightLineFallback)
                        const Positioned(
                          top: 12,
                          left: 16,
                          child: _FallbackBadge(),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: uiInk,
                    onRefresh: () => ref.read(routeProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                      children: [
                        _Summary(route: route),
                        const SizedBox(height: 18),
                        _LoadGauge(route: route),
                        const SizedBox(height: 24),
                        const UiSectionLabel('Stops in driving order'),
                        _Stops(
                          route: route,
                          selected: _selected,
                          onSelect: (index) {
                            setState(() => _selected = index);
                            HapticFeedback.selectionClick();
                            _map.move(route.stops[index].position, 15.5);
                          },
                          onComplete: _openStop,
                          hasPickup: (stop) => _pickupFor(stop) != null,
                        ),
                        if (route.hasDeferred) ...[
                          const SizedBox(height: 20),
                          _Deferred(count: route.deferredPickupIds.length),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMap(CollectorRoute route) {
    return MapCanvas(
      controller: _map,
      initialZoom: 12,
      initialCenter: route.depot.position,
      onMapReady: () {
        _mapReady = true;
        _frameMap(route);
      },
      layers: [
        PolylineLayer(
          polylines: [
            Polyline(
              points: route.line,
              strokeWidth: 5,
              color: uiInk.withValues(alpha: 0.85),
              borderStrokeWidth: 2,
              borderColor: Colors.white,
              pattern: route.isStraightLineFallback
                  ? StrokePattern.dashed(segments: const [10, 8])
                  : const StrokePattern.solid(),
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: route.depot.position,
              width: 44,
              height: 44,
              child: const DepotPin(),
            ),
            for (var i = 0; i < route.stops.length; i++)
              Marker(
                point: route.stops[i].position,
                width: 46,
                height: 46,
                child: SequencePin(
                  label: '${route.stops[i].sequence}',
                  selected: i == _selected,
                  onTap: () => setState(() => _selected = i),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.route});

  final CollectorRoute route;

  static String _duration(double minutes) {
    if (minutes < 60) return '${minutes.round()} min';
    final hours = minutes ~/ 60;
    final rest = (minutes % 60).round();
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricTile(
            icon: HugeIcons.strokeRoundedRoute01,
            value: route.distanceKm == null
                ? '—'
                : '${route.distanceKm!.toStringAsFixed(1)} km',
            label: 'Distance',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricTile(
            icon: HugeIcons.strokeRoundedClock01,
            value: route.durationMinutes == null
                ? '—'
                : _duration(route.durationMinutes!),
            label: 'Drive time',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricTile(
            icon: HugeIcons.strokeRoundedWeightScale01,
            value: kilograms(route.plannedLoadKg),
            label: 'Load',
            accent: uiGreen,
          ),
        ),
      ],
    );
  }
}

class _LoadGauge extends StatelessWidget {
  const _LoadGauge({required this.route});

  final CollectorRoute route;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Vehicle load',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: uiInkSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${route.plannedLoadKg.toStringAsFixed(1)} of '
              '${route.vehicleCapacityKg.toStringAsFixed(0)} kg',
              style: const TextStyle(fontSize: 13, color: uiInkTertiary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: route.loadPercent,
            minHeight: 7,
            backgroundColor: uiFillStrong,
            valueColor: AlwaysStoppedAnimation<Color>(
              route.loadPercent > 0.9 ? uiAmber : uiGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _Stops extends StatelessWidget {
  const _Stops({
    required this.route,
    required this.selected,
    required this.onSelect,
    required this.onComplete,
    required this.hasPickup,
  });

  final CollectorRoute route;
  final int selected;
  final ValueChanged<int> onSelect;
  final ValueChanged<RouteStop> onComplete;
  final bool Function(RouteStop) hasPickup;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DepotRow(name: route.depot.name, label: 'Start'),
        const SizedBox(height: 10),
        for (var i = 0; i < route.stops.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _StopCard(
              stop: route.stops[i],
              active: i == selected,
              canComplete: hasPickup(route.stops[i]),
              onTap: () => onSelect(i),
              onComplete: () => onComplete(route.stops[i]),
            ),
          ),
        _DepotRow(name: route.depot.name, label: 'Return'),
      ],
    );
  }
}

class _DepotRow extends StatelessWidget {
  const _DepotRow({required this.name, required this.label});

  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedWarehouse,
            color: uiGreen,
            size: 17,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: uiInkSecondary,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: uiInkTertiary),
          ),
        ],
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.active,
    required this.canComplete,
    required this.onTap,
    required this.onComplete,
  });

  final RouteStop stop;
  final bool active;
  final bool canComplete;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: AnimatedContainer(
        duration: uiQuick,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? uiInk : uiHairline,
            width: active ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: uiInk,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${stop.sequence}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.address.isEmpty ? stop.type.label : stop.address,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: uiInk,
                          letterSpacing: -0.25,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            stop.type.label,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: uiInkTertiary,
                            ),
                          ),
                          const Text(
                            '  ·  ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: uiInkTertiary,
                            ),
                          ),
                          Text(
                            kilograms(stop.weightKg),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: uiInkTertiary,
                            ),
                          ),
                          if (stop.pickupCount > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: uiAmberSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${stop.pickupCount} parcels',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: uiAmber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canComplete) ...[
              const SizedBox(height: 14),
              Pressable(
                onTap: onComplete,
                scale: 0.98,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: uiInk,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Weigh and complete',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

class _Deferred extends StatelessWidget {
  const _Deferred({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: uiAmberSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: uiAmberLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedAlert02,
            color: uiAmber,
            size: 19,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              '$count pickup${count == 1 ? '' : 's'} did not fit this trip. '
              'They stay assigned to you for the next run.',
              style: const TextStyle(
                fontSize: 14,
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

class _FallbackBadge extends StatelessWidget {
  const _FallbackBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: uiInk.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        'Straight-line preview',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: uiAmber,
        ),
      ),
    );
  }
}
