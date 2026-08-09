import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Model/Detection.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Screen/Pickup/PickupRequestSheet.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/ToastService.dart';
import 'package:greentech/Utils/avatar_helper.dart';
import 'package:greentech/Widget/ScanWidgets/ScanResultView.dart';
import 'package:greentech/Widget/ScanWidgets/ScanSourceSheet.dart';
import 'package:greentech/Widget/ScanWidgets/ScanStage.dart';
import 'package:greentech/Widget/UiKit.dart';
import 'package:greentech/Utils/AppColors.dart';

class ImageScreen extends ConsumerStatefulWidget {
  const ImageScreen({super.key, this.standalone = false});

  final bool standalone;

  @override
  ConsumerState<ImageScreen> createState() => _ImageScreenState();
}

class _ImageScreenState extends ConsumerState<ImageScreen> {
  static const double _maxBytes = 10 * 1024 * 1024;
  static const double _idleAspect = 4 / 4.4;
  static const double _resultAspect = 4 / 2.9;

  final ImagePicker _picker = ImagePicker();
  final ScrollController _scroll = ScrollController();

  File? _file;
  int _fileBytes = 0;
  Detection? _result;
  String? _failure;
  bool _analyzing = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _hasImage => _file != null;

  Role get _role => ref.watch(sessionProvider).value?.role ?? Role.citizen;

  Future<void> _pickFrom(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (picked == null || !mounted) return;

      final file = File(picked.path);
      final bytes = await file.length();

      if (!mounted) return;

      if (bytes > _maxBytes) {
        ToastService.show(
          'That photo is over 10 MB. Please pick a smaller one.',
          ToastType.error,
          context,
        );
        return;
      }

      setState(() {
        _file = file;
        _fileBytes = bytes;
        _result = null;
        _failure = null;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      ToastService.show(
        error.code == 'camera_access_denied' ||
                error.code == 'photo_access_denied'
            ? 'Green Route needs permission to use that. Enable it in Settings.'
            : 'That photo could not be opened. Please try another one.',
        ToastType.error,
        context,
      );
    }
  }

  Future<void> _choosePhoto() async {
    final source = await showScanSourceSheet(context);
    if (source == null || !mounted) return;
    await _pickFrom(source);
  }

  Future<void> _analyze() async {
    final file = _file;
    if (file == null || _analyzing) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _analyzing = true;
      _result = null;
      _failure = null;
    });

    try {
      final detection = await ApiService.scanWaste(file);
      if (!mounted) return;

      setState(() {
        _analyzing = false;
        _result = detection;
      });

      HapticFeedback.heavyImpact();

      if (detection.pointsAwarded) {
        ref.read(sessionProvider.notifier).refresh();
      }

      ref.read(detectionHistoryProvider.notifier).refresh();

      _revealResult();
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _analyzing = false;
        _failure = error.message;
      });

      HapticFeedback.vibrate();
      ToastService.show(error.message, ToastType.error, context);
    }
  }

  void _revealResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        260,
        duration: const Duration(milliseconds: 620),
        curve: uiEase,
      );
    });
  }

  Future<void> _requestPickup() async {
    final detection = _result;
    if (detection == null) return;

    final pickup = await showPickupRequestSheet(
      context,
      scan: detection.toHistoryItem(),
    );

    if (pickup == null || !mounted) return;

    ToastService.show(
      'Pickup requested. We are finding a collector.',
      ToastType.success,
      context,
    );

    await ref.read(pickupsProvider.notifier).refresh();

    if (!mounted) return;
    context.go('/pickup');
  }

  void _reset() {
    setState(() {
      _file = null;
      _fileBytes = 0;
      _result = null;
      _failure = null;
    });

    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: uiSmooth, curve: uiEase);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final showingResult = result != null;
    final earnsRewards = _role.earnsRewards;

    return Scaffold(
      backgroundColor: appBackground,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStage(showingResult),
            if (_hasImage && !_analyzing && !showingResult) ...[
              const SizedBox(height: 14),
              _buildFileMeta(),
            ],
            const SizedBox(height: 24),
            AnimatedSize(
              duration: uiSmooth,
              curve: uiEase,
              alignment: Alignment.topCenter,
              child: _buildActions(showingResult),
            ),
            if (!_hasImage) ...[
              const SizedBox(height: 36),
              _HowItWorks(earnsRewards: earnsRewards),
              const SizedBox(height: 28),
              const _PrivacyNote(),
            ],
            if (_analyzing) ...[
              const SizedBox(height: 24),
              const ScanProgressSteps(),
            ],
            if (_failure != null && !_analyzing) ...[
              const SizedBox(height: 24),
              _FailureCard(message: _failure!, onRetry: _analyze),
            ],
            if (showingResult) ...[
              const SizedBox(height: 32),
              ScanResultView(detection: result, showRewards: earnsRewards),
            ],
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final user = ref.watch(sessionProvider).value;
    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName
        : 'Green Route user';

    return AppBar(
      backgroundColor: appBackground,
      surfaceTintColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 82,
      titleSpacing: widget.standalone ? 4 : 20,
      leadingWidth: widget.standalone ? 72 : null,
      leading: widget.standalone
          ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: UiCircleButton(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  size: 40,
                ),
              ),
            )
          : null,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan',
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
            _result != null
                ? 'Here is what we found'
                : _hasImage
                ? 'Ready when you are'
                : _role.earnsRewards
                ? 'Turn your waste into points and cash'
                : 'Check what a material is worth',
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

  Widget _buildStage(bool showingResult) {
    final file = _file;

    if (file == null) {
      return ScanEmptyCard(onTap: _choosePhoto);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: _idleAspect,
        end: showingResult ? _resultAspect : _idleAspect,
      ),
      duration: uiSmooth,
      curve: uiEase,
      builder: (context, aspect, child) => ScanImageCard(
        file: file,
        aspectRatio: aspect,
        analyzing: _analyzing,
        onChange: showingResult ? null : _choosePhoto,
        onClear: showingResult ? null : _reset,
      ),
    );
  }

  Widget _buildFileMeta() {
    final kilobytes = _fileBytes / 1024;
    final size = kilobytes >= 1024
        ? '${(kilobytes / 1024).toStringAsFixed(1)} MB'
        : '${kilobytes.round()} KB';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedImage02,
          color: uiInkTertiary,
          size: 15,
        ),
        const SizedBox(width: 7),
        Text(
          '$size  ·  ready to analyze',
          style: const TextStyle(
            fontSize: 13,
            color: uiInkTertiary,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool showingResult) {
    if (showingResult) {
      final detection = _result!;
      final canRequestPickup =
          _role.canRequestPickup &&
          detection.eligible &&
          detection.recommendation.pickupRecommended;

      return Column(
        key: const ValueKey('actions.result'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canRequestPickup) ...[
            UiPrimaryButton(
              label: 'Request a pickup',
              icon: HugeIcons.strokeRoundedDeliveryBox01,
              onTap: _requestPickup,
            ),
            const SizedBox(height: 12),
            UiSecondaryButton(
              label: 'Scan another photo',
              icon: HugeIcons.strokeRoundedRefresh,
              onTap: _reset,
            ),
          ] else
            UiPrimaryButton(
              label: detection.eligible ? 'Scan another photo' : 'Retake photo',
              icon: detection.eligible
                  ? HugeIcons.strokeRoundedRefresh
                  : HugeIcons.strokeRoundedCamera01,
              onTap: detection.eligible
                  ? _reset
                  : () => _pickFrom(ImageSource.camera),
            ),
        ],
      );
    }

    if (!_hasImage) {
      return Column(
        key: const ValueKey('actions.empty'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiPrimaryButton(
            label: 'Take a photo',
            icon: HugeIcons.strokeRoundedCamera01,
            onTap: () => _pickFrom(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          UiSecondaryButton(
            label: 'Choose from library',
            icon: HugeIcons.strokeRoundedImage02,
            onTap: () => _pickFrom(ImageSource.gallery),
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey('actions.ready'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        UiPrimaryButton(
          label: _analyzing ? 'Analyzing' : 'Analyze photo',
          icon: HugeIcons.strokeRoundedSparkles,
          busy: _analyzing,
          onTap: _analyze,
        ),
        const SizedBox(height: 12),
        AnimatedOpacity(
          opacity: _analyzing ? 0.35 : 1,
          duration: uiQuick,
          child: UiSecondaryButton(
            label: 'Use a different photo',
            icon: HugeIcons.strokeRoundedImageAdd02,
            onTap: _analyzing ? null : _choosePhoto,
          ),
        ),
      ],
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.earnsRewards});

  final bool earnsRewards;

  static const List<List<String>> _rewardSteps = [
    ['Snap the waste', 'One clear photo, good light, nothing overlapping.'],
    ['We identify it', 'Materials, weight and resale value in seconds.'],
    ['Earn or hand it over', 'Collect points, or request a doorstep pickup.'],
  ];

  static const List<List<String>> _valuationSteps = [
    ['Snap the material', 'One clear photo, good light, nothing overlapping.'],
    ['We identify it', 'Materials, weight and resale value in seconds.'],
    ['Price the lot', 'Use the catalogue rate to judge what it is worth.'],
  ];

  @override
  Widget build(BuildContext context) {
    final steps = earnsRewards ? _rewardSteps : _valuationSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const UiSectionLabel('How it works'),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: uiHairline),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                if (index > 0) const UiHairline(indent: 44),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: uiInk,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[index][0],
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: uiInk,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              steps[index][1],
                              style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.4,
                                color: uiInkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HugeIcon(
          icon: HugeIcons.strokeRoundedShield01,
          color: uiInkTertiary,
          size: 18,
        ),
        const SizedBox(height: 8),
        const Text(
          'Your photo is used only to identify this waste.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: uiInkTertiary,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'JPEG, PNG, WEBP or BMP  ·  up to 10 MB',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: uiInkTertiary),
        ),
      ],
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: uiAmberSoft,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: uiAmberLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: uiAmber,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                "That scan didn't go through",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: uiInk,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: uiInkSecondary,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 16),
          Pressable(
            onTap: onRetry,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: uiAmberLine),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Try again',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: uiInk,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
