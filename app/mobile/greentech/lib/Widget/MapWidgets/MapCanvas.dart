import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import 'package:greentech/Config/MapConfig.dart';
import 'package:greentech/Model/CollectionPoint.dart';
import 'package:greentech/Widget/UiKit.dart';

class MapCanvas extends StatelessWidget {
  const MapCanvas({
    super.key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = 13,
    this.layers = const [],
    this.onMapReady,
    this.interactive = true,
  });

  final MapController controller;
  final LatLng initialCenter;
  final double initialZoom;
  final List<Widget> layers;
  final VoidCallback? onMapReady;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: MapConfig.minZoom,
        maxZoom: MapConfig.maxZoom,
        backgroundColor: uiFill,
        onMapReady: onMapReady,
        interactionOptions: InteractionOptions(
          flags: interactive
              ? InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.flingAnimation
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrl,
          userAgentPackageName: MapConfig.userAgentPackageName,
          maxNativeZoom: 18,
          tileDimension: 512,
          zoomOffset: -1,
        ),
        ...layers,
        const _Attribution(),
      ],
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '© Mapbox © OpenStreetMap',
            style: TextStyle(fontSize: 9.5, color: uiInkSecondary),
          ),
        ),
      ),
    );
  }
}

class UserDotMarker extends StatelessWidget {
  const UserDotMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF1A73D4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class PointPin extends StatelessWidget {
  const PointPin({
    super.key,
    required this.type,
    this.selected = false,
    this.onTap,
  });

  final CollectionPointType type;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = pointColor(type);
    final size = selected ? 40.0 : 30.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: uiQuick,
          curve: uiEase,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? uiInk : color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2.4),
            boxShadow: [
              BoxShadow(
                color: uiInk.withValues(alpha: selected ? 0.34 : 0.2),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: HugeIcon(
            icon: pointIcon(type),
            color: Colors.white,
            size: selected ? 19 : 15,
          ),
        ),
      ),
    );
  }
}

class SequencePin extends StatelessWidget {
  const SequencePin({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: uiQuick,
          curve: uiEase,
          width: selected ? 40 : 32,
          height: selected ? 40 : 32,
          decoration: BoxDecoration(
            color: uiInk,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: selected ? 3.4 : 2.6,
            ),
            boxShadow: [
              BoxShadow(
                color: uiInk.withValues(alpha: 0.3),
                blurRadius: selected ? 14 : 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: selected ? 15 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class DepotPin extends StatelessWidget {
  const DepotPin({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: uiGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 2.8),
          boxShadow: [
            BoxShadow(
              color: uiInk.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const HugeIcon(
          icon: HugeIcons.strokeRoundedWarehouse,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

Color pointColor(CollectionPointType type) => switch (type) {
  CollectionPointType.mrf => const Color(0xFF1A73D4),
  CollectionPointType.binCluster => uiGreen,
  CollectionPointType.scrapYard => const Color(0xFFB4741C),
  CollectionPointType.compostHub => const Color(0xFF7A4FBF),
  CollectionPointType.unknown => uiInkSecondary,
};

dynamic pointIcon(CollectionPointType type) => switch (type) {
  CollectionPointType.mrf => HugeIcons.strokeRoundedRecycle01,
  CollectionPointType.binCluster => HugeIcons.strokeRoundedDelete02,
  CollectionPointType.scrapYard => HugeIcons.strokeRoundedPackage,
  CollectionPointType.compostHub => HugeIcons.strokeRoundedLeaf01,
  CollectionPointType.unknown => HugeIcons.strokeRoundedLocation01,
};
