import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Widget/UiKit.dart';

class ScanEmptyCard extends StatelessWidget {
  const ScanEmptyCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: AspectRatio(
        aspectRatio: 4 / 4.4,
        child: CustomPaint(
          foregroundPainter: const DashedBorderPainter(
            radius: 32,
            color: uiHairlineStrong,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, uiFill],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: uiInk.withValues(alpha: 0.08),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedScanImage,
                    color: uiInk,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Scan your waste',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: uiInk,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Bottles, cans, paper, e-waste — one photo is all it takes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.45,
                      color: uiInkSecondary,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: uiHairline),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAdd01,
                        color: uiInk,
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Add a photo',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: uiInk,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScanImageCard extends StatelessWidget {
  const ScanImageCard({
    super.key,
    required this.file,
    required this.aspectRatio,
    this.analyzing = false,
    this.onChange,
    this.onClear,
  });

  final File file;
  final double aspectRatio;
  final bool analyzing;
  final VoidCallback? onChange;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: uiSmooth,
      curve: uiEase,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: uiInk.withValues(alpha: 0.14),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                file,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: uiInk.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
              ),
              if (analyzing) const _AnalyzingOverlay(),
              if (!analyzing && (onChange != null || onClear != null))
                Positioned(
                  top: 14,
                  right: 14,
                  child: Row(
                    children: [
                      if (onChange != null)
                        _GlassChip(
                          icon: HugeIcons.strokeRoundedImageAdd02,
                          label: 'Change',
                          onTap: onChange!,
                        ),
                      if (onClear != null) ...[
                        const SizedBox(width: 10),
                        _GlassChip(
                          icon: HugeIcons.strokeRoundedCancel01,
                          onTap: onClear!,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.icon, required this.onTap, this.label});

  final dynamic icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: label == null ? 9 : 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: icon, color: uiInk, size: 17),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: uiInk,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyzingOverlay extends StatefulWidget {
  const _AnalyzingOverlay();

  @override
  State<_AnalyzingOverlay> createState() => _AnalyzingOverlayState();
}

class _AnalyzingOverlayState extends State<_AnalyzingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: ColoredBox(color: Colors.white.withValues(alpha: 0.42)),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_controller.value);
            return Align(
              alignment: Alignment(0, t * 2 - 1),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      uiGreen.withValues(alpha: 0.0),
                      uiGreen.withValues(alpha: 0.16),
                      uiGreen.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: CustomPaint(painter: _ViewfinderPainter()),
        ),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: uiInk,
                      ),
                    ),
                    SizedBox(width: 11),
                    Text(
                      'Analyzing',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: uiInk,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const arm = 26.0;
    const radius = 16.0;

    void corner(Offset origin, double dx, double dy) {
      final path = Path()
        ..moveTo(origin.dx + dx * arm, origin.dy)
        ..lineTo(origin.dx + dx * radius, origin.dy)
        ..quadraticBezierTo(
          origin.dx,
          origin.dy,
          origin.dx,
          origin.dy + dy * radius,
        )
        ..lineTo(origin.dx, origin.dy + dy * arm);
      canvas.drawPath(path, paint);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(size.width, 0), -1, 1);
    corner(Offset(0, size.height), 1, -1);
    corner(Offset(size.width, size.height), -1, -1);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}

class ScanProgressSteps extends StatefulWidget {
  const ScanProgressSteps({super.key});

  @override
  State<ScanProgressSteps> createState() => _ScanProgressStepsState();
}

class _ScanProgressStepsState extends State<ScanProgressSteps> {
  static const List<String> _steps = [
    'Uploading your photo',
    'Detecting objects',
    'Pricing the materials',
  ];

  int _active = 0;

  @override
  void initState() {
    super.initState();
    _advance();
  }

  Future<void> _advance() async {
    for (var index = 1; index < _steps.length; index++) {
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      if (!mounted) return;
      setState(() => _active = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: uiFill,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (var index = 0; index < _steps.length; index++) ...[
            if (index > 0) const UiHairline(indent: 34),
            _StepRow(
              label: _steps[index],
              done: index < _active,
              active: index == _active,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: done
                ? Container(
                    decoration: const BoxDecoration(
                      color: uiGreen,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  )
                : active
                ? const Padding(
                    padding: EdgeInsets.all(2),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: uiInk,
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: uiInkTertiary.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: uiQuick,
            style: TextStyle(
              fontSize: 15,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: done || active ? uiInk : uiInkTertiary,
              letterSpacing: -0.2,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
