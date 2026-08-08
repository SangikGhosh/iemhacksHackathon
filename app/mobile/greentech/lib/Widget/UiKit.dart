import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Model/Detection.dart';

const Color uiInk = Color(0xFF0B0B0C);
const Color uiInkSecondary = Color(0xFF6E6E73);
const Color uiInkTertiary = Color(0xFFA6A6AB);
const Color uiHairline = Color(0xFFEDEDF0);
const Color uiHairlineStrong = Color(0xFFD9D9DF);
const Color uiFill = Color(0xFFF6F6F8);
const Color uiFillStrong = Color(0xFFEDEDF1);
const Color uiGreen = Color(0xFF12885A);
const Color uiGreenSoft = Color(0xFFEEF9F3);
const Color uiGreenLine = Color(0xFFD5EEE2);
const Color uiDanger = Color(0xFFD1373C);
const Color uiDangerSoft = Color(0xFFFDF0F0);
const Color uiAmber = Color(0xFF9A6B12);
const Color uiAmberSoft = Color(0xFFFDF7EA);
const Color uiAmberLine = Color(0xFFF2E4C4);

const Duration uiQuick = Duration(milliseconds: 220);
const Duration uiSmooth = Duration(milliseconds: 420);
const Curve uiEase = Curves.easeOutCubic;

Color binColor(WasteBin bin) => switch (bin) {
  WasteBin.blue => const Color(0xFF1A73D4),
  WasteBin.green => const Color(0xFF1DA45C),
  WasteBin.red => const Color(0xFFDC3B41),
  WasteBin.grey => const Color(0xFF8A8A8E),
  WasteBin.unknown => uiInkTertiary,
};

String rupees(double value) {
  if (value >= 1000) return '₹${value.toStringAsFixed(0)}';
  return '₹${value.toStringAsFixed(2)}';
}

String kilograms(double value) {
  if (value >= 10) return '${value.toStringAsFixed(1)} kg';
  if (value >= 1) return '${value.toStringAsFixed(2)} kg';
  return '${(value * 1000).round()} g';
}

class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.haptic = true,
    this.dimWhenDisabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final bool dimWhenDisabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down == value || widget.onTap == null) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setDown(true),
      onTapCancel: () => _setDown(false),
      onTapUp: (_) => _setDown(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!.call();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: widget.onTap == null && widget.dimWhenDisabled
              ? 0.45
              : (_down ? 0.9 : 1.0),
          duration: const Duration(milliseconds: 130),
          child: widget.child,
        ),
      ),
    );
  }
}

class UiPrimaryButton extends StatelessWidget {
  const UiPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final dynamic icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !busy;
    final foreground = disabled ? uiInkTertiary : Colors.white;

    return Pressable(
      onTap: busy ? null : onTap,
      dimWhenDisabled: false,
      child: AnimatedContainer(
        duration: uiQuick,
        curve: uiEase,
        height: 56,
        decoration: BoxDecoration(
          color: disabled ? uiFillStrong : uiInk,
          borderRadius: BorderRadius.circular(28),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: uiInk.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    HugeIcon(icon: icon, color: foreground, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class UiSecondaryButton extends StatelessWidget {
  const UiSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onTap;
  final dynamic icon;
  final Widget? leading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: outlined ? Colors.white : uiFill,
          borderRadius: BorderRadius.circular(28),
          border: outlined
              ? Border.all(color: uiHairlineStrong, width: 1.2)
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            if (leading == null && icon != null) ...[
              HugeIcon(icon: icon, color: uiInk, size: 20),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                color: uiInk,
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showUiConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: uiInk.withValues(alpha: 0.32),
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: uiInk,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 7),
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
                  const SizedBox(height: 22),
                  Pressable(
                    onTap: () => Navigator.of(sheetContext).pop(true),
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: destructive ? uiDanger : uiInk,
                        borderRadius: BorderRadius.circular(27),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Pressable(
              onTap: () => Navigator.of(sheetContext).pop(false),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: Text(
                  cancelLabel,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: uiInk,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class UiSectionLabel extends StatelessWidget {
  const UiSectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: uiInkSecondary,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(fontSize: 13, color: uiInkTertiary),
            ),
        ],
      ),
    );
  }
}

class UiHairline extends StatelessWidget {
  const UiHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: const Divider(height: 1, thickness: 1, color: uiHairline),
    );
  }
}

class UiTextField extends StatefulWidget {
  const UiTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.autofocus = false,
    this.enabled = true,
    this.autofillHints,
    this.inputFormatters,
    this.errorText,
    this.onSubmitted,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final bool obscure;
  final bool autofocus;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<UiTextField> createState() => _UiTextFieldState();
}

class _UiTextFieldState extends State<UiTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  late final bool _ownsFocusNode = widget.focusNode == null;
  bool _focused = false;
  late bool _obscured = widget.obscure;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    final borderColor = hasError
        ? uiDanger
        : _focused
        ? uiInk
        : uiHairlineStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: uiInkSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: uiEase,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: widget.enabled ? Colors.white : uiFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: _focused || hasError ? 1.6 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  obscureText: _obscured,
                  keyboardType: widget.keyboardType,
                  textCapitalization: widget.textCapitalization,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  inputFormatters: widget.inputFormatters,
                  onSubmitted: widget.onSubmitted,
                  cursorColor: uiInk,
                  cursorWidth: 1.8,
                  cursorRadius: const Radius.circular(2),
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w500,
                    color: uiInk,
                    letterSpacing: -0.2,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w400,
                      color: uiInkTertiary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              if (widget.obscure)
                Pressable(
                  onTap: () => setState(() => _obscured = !_obscured),
                  scale: 0.9,
                  haptic: false,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: HugeIcon(
                      icon: _obscured
                          ? HugeIcons.strokeRoundedView
                          : HugeIcons.strokeRoundedViewOff,
                      color: uiInkTertiary,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: uiQuick,
          curve: uiEase,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: uiDanger,
                      letterSpacing: -0.1,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class UiCircleButton extends StatelessWidget {
  const UiCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  final dynamic icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: uiHairlineStrong, width: 1.2),
        ),
        alignment: Alignment.center,
        child: HugeIcon(icon: icon, color: uiInk, size: 20),
      ),
    );
  }
}

class UiOrDivider extends StatelessWidget {
  const UiOrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: uiHairline, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: uiInkTertiary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: uiHairline, height: 1)),
      ],
    );
  }
}

class UiErrorNote extends StatelessWidget {
  const UiErrorNote(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: uiQuick,
      curve: uiEase,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 18),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: uiDangerSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: uiDanger.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedAlertCircle,
                    color: uiDanger,
                    size: 18,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      message!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: uiDanger,
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

class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    this.color = uiHairline,
    this.radius = 32,
    this.dash = 7,
    this.gap = 6,
    this.strokeWidth = 1.6,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height).deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offset = 18,
  });

  final Widget child;
  final int delayMs;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: uiEase,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delayMs == 0) {
      _controller.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) => Opacity(
        opacity: _curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
