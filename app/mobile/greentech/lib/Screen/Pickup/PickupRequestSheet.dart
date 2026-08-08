import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:latlong2/latlong.dart';

import 'package:greentech/Config/MapConfig.dart';
import 'package:greentech/Model/CollectionPoint.dart';
import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Model/Pickup.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/LocationService.dart';
import 'package:greentech/Widget/CitizenWidgets/CitizenKit.dart';
import 'package:greentech/Widget/MapWidgets/MapCanvas.dart';
import 'package:greentech/Widget/UiKit.dart';

Future<Pickup?> showPickupRequestSheet(
  BuildContext context, {
  DetectionHistoryItem? scan,
}) {
  return showModalBottomSheet<Pickup>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: uiInk.withValues(alpha: 0.34),
    builder: (_) => PickupRequestSheet(initialScan: scan),
  );
}

class PickupRequestSheet extends ConsumerStatefulWidget {
  const PickupRequestSheet({super.key, this.initialScan});

  final DetectionHistoryItem? initialScan;

  @override
  ConsumerState<PickupRequestSheet> createState() => _PickupRequestSheetState();
}

class _PickupRequestSheetState extends ConsumerState<PickupRequestSheet> {
  final MapController _map = MapController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  DetectionHistoryItem? _scan;
  PickupMode _mode = PickupMode.dropOff;
  List<CollectionPoint> _points = const [];
  CollectionPoint? _point;
  LatLng? _origin;
  bool _loadingPoints = false;
  bool _submitting = false;
  bool _showErrors = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan = widget.initialScan;
    _loadPoints();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<DetectionHistoryItem> get _eligibleScans {
    final history = ref.read(detectionHistoryProvider).value;
    if (history == null) return const [];

    final usedIds = (ref.read(pickupsProvider).value ?? const <Pickup>[])
        .where((pickup) => pickup.status != PickupStatus.cancelled)
        .map((pickup) => pickup.detectionId)
        .toSet();

    return history.items
        .where((item) => item.eligible && !usedIds.contains(item.id))
        .toList();
  }

  Future<void> _loadPoints() async {
    setState(() => _loadingPoints = true);
    try {
      LatLng? origin;
      try {
        origin = await LocationService.current();
      } on LocationException {
        origin = null;
      }

      final points = origin == null
          ? (await ApiService.collectionPoints()).take(5).toList()
          : await ApiService.nearestCollectionPoints(
              lat: origin.latitude,
              lon: origin.longitude,
            );

      if (!mounted) return;
      setState(() {
        _origin = origin;
        _points = points;
        _point = points.isEmpty ? null : points.first;
        _loadingPoints = false;
      });
      _frameMap();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingPoints = false;
        _error = error.message;
      });
    }
  }

  void _frameMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _points.isEmpty) return;
      if (_map.camera.nonRotatedSize.shortestSide < 1) return;

      final coords = [
        if (_origin != null) _origin!,
        ..._points.map((point) => point.position),
      ];

      if (coords.length == 1) {
        _map.move(coords.first, 15);
        return;
      }

      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: coords,
          padding: const EdgeInsets.all(40),
          maxZoom: 15.5,
        ),
      );
    });
  }

  bool get _canSubmit {
    if (_scan == null || _submitting) return false;
    if (_mode == PickupMode.dropOff) return _point != null;
    return _addressController.text.trim().length >= 4 &&
        _phoneController.text.trim().length >= 8;
  }

  Future<void> _submit() async {
    if (_scan == null) {
      setState(() => _showErrors = true);
      return;
    }
    if (!_canSubmit) {
      setState(() => _showErrors = true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final pickup = await ApiService.requestPickup(
        detectionId: _scan!.id,
        mode: _mode,
        collectionPointId: _mode == PickupMode.dropOff ? _point?.id : null,
        address: _mode == PickupMode.doorstep
            ? _addressController.text.trim()
            : null,
        landmark: _mode == PickupMode.doorstep
            ? _landmarkController.text.trim()
            : null,
        contactPhone: _mode == PickupMode.doorstep
            ? _phoneController.text.trim()
            : null,
        notes: _notesController.text.trim(),
        latitude: _mode == PickupMode.doorstep ? _origin?.latitude : null,
        longitude: _mode == PickupMode.doorstep ? _origin?.longitude : null,
      );

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ref.read(pickupsProvider.notifier).adopt(pickup);
      Navigator.of(context).pop(pickup);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final scans = _eligibleScans;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: uiHairlineStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  children: [
                    const Text(
                      'Request a pickup',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: uiInk,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pick a scan, then choose how to hand the waste over.',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.45,
                        color: uiInkSecondary,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const UiSectionLabel('Which scan?'),
                    _ScanPicker(
                      scans: scans,
                      selected: _scan,
                      showError: _showErrors && _scan == null,
                      onSelect: (item) => setState(() {
                        _scan = item;
                        _showErrors = false;
                      }),
                    ),
                    const SizedBox(height: 26),
                    const UiSectionLabel('How will you hand it over?'),
                    _ModeSelector(
                      mode: _mode,
                      onChanged: (mode) => setState(() => _mode = mode),
                    ),
                    const SizedBox(height: 22),
                    if (_mode == PickupMode.dropOff)
                      _buildDropOff()
                    else
                      _buildDoorstep(),
                    UiErrorNote(_error),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  6,
                  20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: UiPrimaryButton(
                  label: _submitting ? 'Requesting' : 'Request pickup',
                  busy: _submitting,
                  onTap: _canSubmit ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropOff() {
    if (_loadingPoints) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: uiFill,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: uiInk, strokeWidth: 2.5),
      );
    }

    if (_points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: uiAmberSoft,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: uiAmberLine),
        ),
        child: const Text(
          'No collection point found near you. Choose a doorstep pickup instead.',
          style: TextStyle(fontSize: 14.5, height: 1.45, color: uiInkSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 190,
            child: MapCanvas(
              controller: _map,
              initialZoom: 13,
              initialCenter:
                  _origin ??
                  const LatLng(MapConfig.fallbackLat, MapConfig.fallbackLon),
              onMapReady: _frameMap,
              layers: [
                MarkerLayer(
                  markers: [
                    for (final point in _points)
                      Marker(
                        point: point.position,
                        width: 42,
                        height: 42,
                        child: PointPin(
                          type: point.type,
                          selected: point.id == _point?.id,
                          onTap: () => setState(() => _point = point),
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
        ),
        const SizedBox(height: 14),
        for (final point in _points)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PointOption(
              point: point,
              selected: point.id == _point?.id,
              onTap: () {
                setState(() => _point = point);
                HapticFeedback.selectionClick();
                _map.move(point.position, 16);
              },
            ),
          ),
        const SizedBox(height: 4),
        _NotesField(controller: _notesController),
      ],
    );
  }

  Widget _buildDoorstep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiTextField(
          label: 'Address',
          controller: _addressController,
          hint: '14 Belilious Road, Howrah',
          textInputAction: TextInputAction.next,
          errorText: _showErrors && _addressController.text.trim().length < 4
              ? 'Enter the address the collector should come to.'
              : null,
          onSubmitted: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        UiTextField(
          label: 'Landmark (optional)',
          controller: _landmarkController,
          hint: 'Near Howrah Maidan',
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),
        UiTextField(
          label: 'Contact phone',
          controller: _phoneController,
          hint: '9800000001',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
            LengthLimitingTextInputFormatter(20),
          ],
          errorText: _showErrors && _phoneController.text.trim().length < 8
              ? 'Enter a phone number the collector can call.'
              : null,
          onSubmitted: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _NotesField(controller: _notesController),
        const SizedBox(height: 14),
        if (_origin == null)
          const AuthLikeNote(
            'Location is off, so this pickup cannot be added to a collector route. '
            'Turn location on for a faster collection.',
          )
        else
          const AuthLikeNote(
            'Your current location will be attached so a collector can route to you.',
          ),
      ],
    );
  }
}

class AuthLikeNote extends StatelessWidget {
  const AuthLikeNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedLocation01,
            color: uiInkTertiary,
            size: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: uiInkTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return UiTextField(
      label: 'Notes (optional)',
      controller: controller,
      hint: 'Ring the bell twice',
      textInputAction: TextInputAction.done,
      inputFormatters: [LengthLimitingTextInputFormatter(300)],
    );
  }
}

class _ScanPicker extends StatelessWidget {
  const _ScanPicker({
    required this.scans,
    required this.selected,
    required this.showError,
    required this.onSelect,
  });

  final List<DetectionHistoryItem> scans;
  final DetectionHistoryItem? selected;
  final bool showError;
  final ValueChanged<DetectionHistoryItem> onSelect;

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: uiFill,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedScanImage,
              color: uiInkTertiary,
              size: 20,
            ),
            SizedBox(width: 13),
            Expanded(
              child: Text(
                'No scan is waiting for a pickup. Scan some waste first.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: uiInkSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final scan in scans.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectableRow(
              selected: scan.id == selected?.id,
              title: scan.materialSummary,
              subtitle:
                  '${scan.totalObjects} items · ${kilograms(scan.estimatedWeightKg)} · '
                  '${relativeTime(scan.createdAt)}',
              trailing: rupees(scan.estimatedOffer),
              onTap: () => onSelect(scan),
            ),
          ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 4, top: 2),
            child: Text(
              'Choose the scan you want collected.',
              style: TextStyle(fontSize: 13, color: uiDanger),
            ),
          ),
      ],
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.99,
      child: AnimatedContainer(
        duration: uiQuick,
        curve: uiEase,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: selected ? uiInk : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? uiInk : uiHairlineStrong,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: selected ? Colors.white : uiHairlineStrong,
                  width: 1.8,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(Icons.check_rounded, size: 13, color: uiInk)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : uiInk,
                      letterSpacing: -0.25,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: selected
                          ? Colors.white.withValues(alpha: 0.62)
                          : uiInkTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              Text(
                trailing!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : uiInk,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PointOption extends StatelessWidget {
  const _PointOption({
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

    return _SelectableRow(
      selected: selected,
      title: point.name,
      subtitle: [
        point.type.label,
        if (distance != null) '${distance.toStringAsFixed(2)} km',
        if (minutes != null) minutes < 1 ? '<1 min' : '${minutes.round()} min',
      ].join(' · '),
      onTap: onTap,
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final PickupMode mode;
  final ValueChanged<PickupMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: HugeIcons.strokeRoundedLocation01,
            title: 'Drop off',
            points: '8 pts / kg',
            note: 'Best value',
            selected: mode == PickupMode.dropOff,
            onTap: () => onChanged(PickupMode.dropOff),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            icon: HugeIcons.strokeRoundedTruck,
            title: 'Doorstep',
            points: '5 pts / kg',
            note: 'We come to you',
            selected: mode == PickupMode.doorstep,
            onTap: () => onChanged(PickupMode.doorstep),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.points,
    required this.note,
    required this.selected,
    required this.onTap,
  });

  final dynamic icon;
  final String title;
  final String points;
  final String note;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.97,
      child: AnimatedContainer(
        duration: uiQuick,
        curve: uiEase,
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: selected ? uiInk : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? uiInk : uiHairlineStrong,
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HugeIcon(
              icon: icon,
              color: selected ? Colors.white : uiInk,
              size: 20,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : uiInk,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              points,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? uiGreenSoft : uiGreen,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              note,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? Colors.white.withValues(alpha: 0.55)
                    : uiInkTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
