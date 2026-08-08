import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Model/CollectorRoute.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Utils/avatar_helper.dart';
import 'package:greentech/Widget/MapWidgets/MapCanvas.dart';
import 'package:greentech/Widget/UiKit.dart';

class PickupScreen extends ConsumerStatefulWidget {
  const PickupScreen({super.key, this.loadRoute});

  final Future<CollectorRoute?> Function()? loadRoute;

  @override
  ConsumerState<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends ConsumerState<PickupScreen> {
  final MapController _map = MapController();

  CollectorRoute? _route;
  String? _error;
  bool _loading = true;
  bool _mapReady = false;
  int _selected = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final route = await (widget.loadRoute ?? ApiService.myRoute)();
      if (!mounted) return;

      setState(() {
        _route = route;
        _loading = false;
        _selected = -1;
      });

      _frameMap();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _frameMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final route = _route;
      if (!_mapReady || route == null) return;
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

  void _selectStop(int index) {
    final route = _route;
    if (route == null || index < 0 || index >= route.stops.length) return;

    setState(() => _selected = index);
    HapticFeedback.selectionClick();
    if (_mapReady) _map.move(route.stops[index].position, 15.5);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).value;
    final isCollector = user?.role == Role.collector;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(user),
      body: !isCollector && user != null
          ? const _CitizenState()
          : _loading
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : _error != null
          ? _MessageState(
              icon: HugeIcons.strokeRoundedMapsLocation01,
              title: 'Could not load your route',
              message: _error!,
              actionLabel: 'Try again',
              onAction: _load,
            )
          : _route == null
          ? _MessageState(
              icon: HugeIcons.strokeRoundedTruck,
              title: 'No route yet',
              message:
                  'Accept some pickups and your optimised route will appear here.',
              actionLabel: 'Refresh',
              onAction: _load,
            )
          : _buildRoute(_route!),
    );
  }

  AppBar _buildAppBar(AppUser? user) {
    final route = _route;
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName
        : 'Green Route user';

    final subtitle = _loading
        ? 'Planning your route…'
        : route == null
        ? 'Nothing scheduled'
        : '${route.totalRequests} request'
              '${route.totalRequests == 1 ? '' : 's'} · '
              '${route.totalStops} stop${route.totalStops == 1 ? '' : 's'}';

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
            'My route',
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
            subtitle,
            style: const TextStyle(
              color: uiInkSecondary,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
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
                  AvatarHelper.getAvatarForName(name),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoute(CollectorRoute route) {
    return Column(
      children: [
        SizedBox(
          height: 300,
          child: Stack(
            children: [
              Positioned.fill(child: _buildMap(route)),
              Positioned(
                top: 12,
                right: 16,
                child: _RoundButton(
                  icon: HugeIcons.strokeRoundedRefresh,
                  onTap: _load,
                ),
              ),
              if (route.isStraightLineFallback)
                const Positioned(top: 12, left: 16, child: _FallbackBadge()),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _SummaryRow(route: route),
              const SizedBox(height: 20),
              _LoadBar(route: route),
              const SizedBox(height: 26),
              const UiSectionLabel('Stops'),
              _StopsList(
                route: route,
                selected: _selected,
                onSelect: _selectStop,
              ),
              if (route.hasDeferred) ...[
                const SizedBox(height: 20),
                _DeferredNote(count: route.deferredPickupIds.length),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMap(CollectorRoute route) {
    return MapCanvas(
      controller: _map,
      initialZoom: 12,
      initialCenter: route.depot.position,
      onMapReady: () {
        _mapReady = true;
        _frameMap();
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
                  onTap: () => _selectStop(i),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.route});

  final CollectorRoute route;

  @override
  Widget build(BuildContext context) {
    final distance = route.distanceKm;
    final duration = route.durationMinutes;

    return Row(
      children: [
        Expanded(
          child: _Stat(
            icon: HugeIcons.strokeRoundedRoute01,
            value: distance == null ? '—' : '${distance.toStringAsFixed(1)} km',
            label: 'Distance',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            icon: HugeIcons.strokeRoundedClock01,
            value: duration == null ? '—' : _formatDuration(duration),
            label: 'Drive time',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Stat(
            icon: HugeIcons.strokeRoundedWeightScale01,
            value: '${route.plannedLoadKg.toStringAsFixed(1)} kg',
            label: 'Load',
            accent: uiGreen,
          ),
        ),
      ],
    );
  }

  static String _formatDuration(double minutes) {
    if (minutes < 60) return '${minutes.round()} min';
    final hours = minutes ~/ 60;
    final rest = (minutes % 60).round();
    return rest == 0 ? '${hours}h' : '${hours}h ${rest}m';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HugeIcon(icon: icon, color: tone, size: 18),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: tone,
                letterSpacing: -0.6,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: uiInkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadBar extends StatelessWidget {
  const _LoadBar({required this.route});

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
            valueColor: const AlwaysStoppedAnimation<Color>(uiGreen),
          ),
        ),
      ],
    );
  }
}

class _StopsList extends StatelessWidget {
  const _StopsList({
    required this.route,
    required this.selected,
    required this.onSelect,
  });

  final CollectorRoute route;
  final int selected;
  final ValueChanged<int> onSelect;

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
          _DepotRow(name: route.depot.name, label: 'Start'),
          for (var i = 0; i < route.stops.length; i++) ...[
            const UiHairline(indent: 46),
            _StopRow(
              stop: route.stops[i],
              active: i == selected,
              onTap: () => onSelect(i),
            ),
          ],
          const UiHairline(indent: 46),
          _DepotRow(name: route.depot.name, label: 'Return'),
        ],
      ),
    );
  }
}

class _DepotRow extends StatelessWidget {
  const _DepotRow({required this.name, required this.label});

  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: uiGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedWarehouse,
              color: uiGreen,
              size: 15,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: uiInkSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: uiInkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.active,
    required this.onTap,
  });

  final RouteStop stop;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: uiQuick,
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: active ? uiInk : uiFill,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '${stop.sequence}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : uiInkSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
                  Text(
                    '${stop.type.label} · ${stop.pickupCount} request'
                    '${stop.pickupCount == 1 ? '' : 's'} · '
                    '${stop.weightKg.toStringAsFixed(2)} kg',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: uiInkTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeferredNote extends StatelessWidget {
  const _DeferredNote({required this.count});

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
                letterSpacing: -0.1,
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final dynamic icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: HugeIcon(icon: icon, color: uiInk, size: 20),
      ),
    );
  }
}

class _CitizenState extends StatelessWidget {
  const _CitizenState();

  @override
  Widget build(BuildContext context) {
    return const _MessageState(
      icon: HugeIcons.strokeRoundedTruckDelivery,
      title: 'Route planning is for collectors',
      message:
          'Your pickup requests will show up here once the pickup flow is wired up.',
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(icon: icon, color: uiInkTertiary, size: 34),
            const SizedBox(height: 18),
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
