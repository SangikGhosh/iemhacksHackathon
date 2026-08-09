import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import 'package:greentech/Config/MapConfig.dart';
import 'package:greentech/Model/CollectionPoint.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/LocationService.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/MapWidgets/MapCanvas.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class NearbyYardsScreen extends ConsumerStatefulWidget {
  const NearbyYardsScreen({super.key});

  @override
  ConsumerState<NearbyYardsScreen> createState() => _NearbyYardsScreenState();
}

class _NearbyYardsScreenState extends ConsumerState<NearbyYardsScreen> {
  final MapController _map = MapController();

  List<CollectionPoint> _points = const [];
  LatLng? _origin;
  String? _error;
  bool _loading = true;
  bool _mapReady = false;
  bool _scrapOnly = true;
  int _selected = 0;

  static const Set<CollectionPointType> _scrapTypes = {
    CollectionPointType.mrf,
    CollectionPointType.scrapYard,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<CollectionPoint> get _visible => _scrapOnly
      ? _points.where((p) => _scrapTypes.contains(p.type)).toList()
      : _points;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      LatLng? origin;
      try {
        origin = await LocationService.current();
      } on LocationException {
        origin = null;
      }

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

  void _frameMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      if (_map.camera.nonRotatedSize.shortestSide < 1) return;

      final coords = [
        if (_origin != null) _origin!,
        ..._visible.map((p) => p.position),
      ];
      if (coords.isEmpty) return;
      if (coords.length == 1) {
        _map.move(coords.first, 15);
        return;
      }

      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: coords,
          padding: const EdgeInsets.all(48),
          maxZoom: 15.5,
        ),
      );
    });
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _visible;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: CitizenAppBar(
        title: 'Nearby yards',
        subtitle: _loading
            ? 'Finding aggregation points…'
            : '${items.length} point${items.length == 1 ? '' : 's'}'
                  '${_origin == null ? '' : ' near you'}',
        onBack: _exit,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: uiInk))
          : _error != null
          ? ErrorRetry(message: _error!, onRetry: _load)
          : Column(
              children: [
                SizedBox(
                  height: 230,
                  child: MapCanvas(
                    controller: _map,
                    initialZoom: 12,
                    initialCenter:
                        _origin ??
                        const LatLng(
                          MapConfig.fallbackLat,
                          MapConfig.fallbackLon,
                        ),
                    onMapReady: () {
                      _mapReady = true;
                      _frameMap();
                    },
                    layers: [
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < items.length; i++)
                            Marker(
                              point: items[i].position,
                              width: 44,
                              height: 44,
                              child: PointPin(
                                type: items[i].type,
                                selected: i == _selected,
                                onTap: () {
                                  setState(() => _selected = i);
                                  HapticFeedback.selectionClick();
                                  _map.move(items[i].position, 16);
                                },
                              ),
                            ),
                          if (_origin != null)
                            Marker(
                              point: _origin!,
                              width: 28,
                              height: 28,
                              child: const UserDotMarker(),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      _Toggle(
                        scrapOnly: _scrapOnly,
                        onChanged: (value) {
                          setState(() {
                            _scrapOnly = value;
                            _selected = 0;
                          });
                          _frameMap();
                        },
                      ),
                      const SizedBox(height: 18),
                      if (items.isEmpty)
                        const EmptyState(
                          icon: HugeIcons.strokeRoundedMapsLocation01,
                          title: 'No points in range',
                          message:
                              'Try turning off the scrap filter to see every collection point.',
                        )
                      else
                        for (var i = 0; i < items.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _YardRow(
                              point: items[i],
                              selected: i == _selected,
                              onTap: () {
                                setState(() => _selected = i);
                                HapticFeedback.selectionClick();
                                _map.move(items[i].position, 16);
                              },
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

class _Toggle extends StatelessWidget {
  const _Toggle({required this.scrapOnly, required this.onChanged});

  final bool scrapOnly;
  final ValueChanged<bool> onChanged;

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
          for (final entry in const [
            (true, 'MRF & scrap yards'),
            (false, 'All points'),
          ])
            Expanded(
              child: Pressable(
                onTap: () => onChanged(entry.$1),
                scale: 0.97,
                child: AnimatedContainer(
                  duration: uiQuick,
                  height: 38,
                  decoration: BoxDecoration(
                    color: entry.$1 == scrapOnly
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: entry.$1 == scrapOnly
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
                    entry.$2,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: entry.$1 == scrapOnly ? uiInk : uiInkSecondary,
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

class _YardRow extends StatelessWidget {
  const _YardRow({
    required this.point,
    required this.selected,
    required this.onTap,
  });

  final CollectionPoint point;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distance = point.bestDistanceKm;
    final minutes = point.drivingMinutes;
    final color = pointColor(point.type);

    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: AnimatedContainer(
        duration: uiQuick,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? uiInk : uiHairline,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: HugeIcon(
                icon: pointIcon(point.type),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: uiInk,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      point.type.label,
                      if (distance != null) '${distance.toStringAsFixed(2)} km',
                      if (minutes != null)
                        minutes < 1 ? '<1 min' : '${minutes.round()} min',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
