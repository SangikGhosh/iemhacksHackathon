import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import 'package:greentech/Config/MapConfig.dart';
import 'package:greentech/Model/CollectionPoint.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/LocationService.dart';
import 'package:greentech/Utils/avatar_helper.dart';
import 'package:greentech/Widget/MapWidgets/MapCanvas.dart';
import 'package:greentech/Widget/UiKit.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final MapController _map = MapController();
  final PageController _cards = PageController(viewportFraction: 0.86);

  List<CollectionPoint> _points = const [];
  LatLng? _origin;
  String? _error;
  bool _loading = true;
  bool _locating = false;
  bool _mapReady = false;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cards.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final origin = await _resolveOrigin();
      final points = origin == null
          ? await ApiService.collectionPoints()
          : await ApiService.nearestCollectionPoints(
              lat: origin.latitude,
              lon: origin.longitude,
            );

      if (!mounted) return;

      setState(() {
        _origin = origin;
        _points = points;
        _selected = 0;
        _loading = false;
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

  Future<LatLng?> _resolveOrigin() async {
    setState(() => _locating = true);
    try {
      return await LocationService.current();
    } on LocationException {
      return null;
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _frameMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady || _points.isEmpty) return;
      if (_map.camera.nonRotatedSize.shortestSide < 1) return;

      final positions = [
        if (_origin != null) _origin!,
        ..._points.map((point) => point.position),
      ];

      if (positions.length == 1) {
        _map.move(positions.first, 15);
        return;
      }

      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: positions,
          padding: const EdgeInsets.fromLTRB(50, 60, 50, 180),
          maxZoom: 16,
        ),
      );
    });
  }

  void _selectPoint(int index, {bool moveCards = true}) {
    if (index < 0 || index >= _points.length) return;

    setState(() => _selected = index);
    HapticFeedback.selectionClick();

    if (_mapReady) _map.move(_points[index].position, 16);

    if (moveCards && _cards.hasClients) {
      _cards.animateToPage(
        index,
        duration: const Duration(milliseconds: 340),
        curve: uiEase,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _error != null
          ? _ErrorState(message: _error!, onRetry: _load)
          : Stack(
              children: [
                Positioned.fill(child: _buildMap()),
                if (_loading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Center(
                        child: CircularProgressIndicator(color: uiInk),
                      ),
                    ),
                  ),
                if (!_loading) ...[
                  Positioned(
                    top: 14,
                    right: 16,
                    child: _MapButton(
                      icon: HugeIcons.strokeRoundedGps01,
                      busy: _locating,
                      onTap: _load,
                    ),
                  ),
                  if (_origin == null)
                    const Positioned(top: 14, left: 16, child: _LocationHint()),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: _buildCards(),
                  ),
                ],
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    final user = ref.watch(sessionProvider).value;
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName
        : 'Green Route user';

    final subtitle = _loading
        ? 'Finding points near you…'
        : _points.isEmpty
        ? 'No drop-off points found'
        : _origin == null
        ? '${_points.length} drop-off points'
        : '${_points.length} drop-off points near you';

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
            'Nearby',
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

  Widget _buildMap() {
    return MapCanvas(
      controller: _map,
      initialCenter:
          _origin ?? const LatLng(MapConfig.fallbackLat, MapConfig.fallbackLon),
      onMapReady: () {
        _mapReady = true;
        _frameMap();
      },
      layers: [
        MarkerLayer(
          markers: [
            for (var i = 0; i < _points.length; i++)
              Marker(
                point: _points[i].position,
                width: 44,
                height: 44,
                child: PointPin(
                  type: _points[i].type,
                  selected: i == _selected,
                  onTap: () => _selectPoint(i),
                ),
              ),
            if (_origin != null)
              Marker(
                point: _origin!,
                width: 30,
                height: 30,
                child: const UserDotMarker(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCards() {
    if (_points.isEmpty) return const _EmptyPoints();

    return SizedBox(
      height: 132,
      child: PageView.builder(
        controller: _cards,
        itemCount: _points.length,
        onPageChanged: (index) => _selectPoint(index, moveCards: false),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _PointCard(
            point: _points[index],
            rank: index + 1,
            hasOrigin: _origin != null,
            onTap: () => _selectPoint(index),
          ),
        ),
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.point,
    required this.rank,
    required this.hasOrigin,
    required this.onTap,
  });

  final CollectionPoint point;
  final int rank;
  final bool hasOrigin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distance = point.bestDistanceKm;
    final minutes = point.drivingMinutes;

    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: uiHairline),
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: pointColor(point.type).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: HugeIcon(
                    icon: pointIcon(point.type),
                    color: pointColor(point.type),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        point.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: uiInk,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        point.subtitle,
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
                if (hasOrigin)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: uiFill,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '#$rank',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: uiInkSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                _Chip(label: point.type.label),
                if (distance != null) ...[
                  const SizedBox(width: 8),
                  _Chip(
                    label: '${distance.toStringAsFixed(2)} km',
                    icon: point.hasRoadDistance
                        ? HugeIcons.strokeRoundedRoute01
                        : HugeIcons.strokeRoundedRuler,
                  ),
                ],
                if (minutes != null) ...[
                  const SizedBox(width: 8),
                  _Chip(
                    label: minutes < 1 ? '<1 min' : '${minutes.round()} min',
                    icon: HugeIcons.strokeRoundedClock01,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final dynamic icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            HugeIcon(icon: icon, color: uiInkSecondary, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: uiInkSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.onTap,
    this.busy = false,
  });

  final dynamic icon;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: busy ? null : onTap,
      dimWhenDisabled: false,
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
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: uiInk),
              )
            : HugeIcon(icon: icon, color: uiInk, size: 20),
      ),
    );
  }
}

class _LocationHint extends StatelessWidget {
  const _LocationHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: uiInk.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedLocation01,
            color: uiInkSecondary,
            size: 14,
          ),
          SizedBox(width: 7),
          Text(
            'Showing all points',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: uiInkSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPoints extends StatelessWidget {
  const _EmptyPoints();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: uiHairline),
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.12),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedMapPinpoint01,
              color: uiInkTertiary,
              size: 22,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'No drop-off points within range yet.',
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: uiInkSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedMapsLocation01,
              color: uiInkTertiary,
              size: 34,
            ),
            const SizedBox(height: 18),
            const Text(
              'Could not load the map',
              style: TextStyle(
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
            const SizedBox(height: 24),
            UiSecondaryButton(label: 'Try again', onTap: onRetry),
          ],
        ),
      ),
    );
  }
}
