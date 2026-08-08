import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:greentech/Widget/UiKit.dart';

class OtpBoxes extends StatelessWidget {
  const OtpBoxes({
    super.key,
    required this.value,
    this.length = 6,
    this.hasError = false,
  });

  final String value;
  final int length;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final cursor = value.length.clamp(0, length - 1);

    return Semantics(
      label: 'Verification code, ${value.length} of $length digits entered',
      child: Row(
        children: [
          for (var i = 0; i < length; i++) ...[
            Expanded(
              child: _Box(
                digit: i < value.length ? value[i] : null,
                active: i == cursor && value.length < length,
                hasError: hasError,
              ),
            ),
            if (i != length - 1) const SizedBox(width: 9),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.digit,
    required this.active,
    required this.hasError,
  });

  final String? digit;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final filled = digit != null;

    final borderColor = hasError
        ? uiDanger
        : active
        ? uiInk
        : filled
        ? uiInk
        : uiHairlineStrong;

    return AspectRatio(
      aspectRatio: 0.84,
      child: AnimatedContainer(
        duration: uiQuick,
        curve: uiEase,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? uiInk : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: active || hasError ? 1.8 : 1.2,
          ),
        ),
        child: Text(
          digit ?? '',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: filled ? Colors.white : uiInk,
          ),
        ),
      ),
    );
  }
}

class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          _Row(
            children: [
              for (final key in row)
                _Key(label: key, onTap: enabled ? () => _press(key) : null),
            ],
          ),
        _Row(
          children: [
            const _Key.blank(),
            _Key(label: '0', onTap: enabled ? () => _press('0') : null),
            _Key(
              transparent: true,
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onBackspace();
                    }
                  : null,
              child: const Icon(
                Icons.backspace_outlined,
                size: 22,
                color: uiInk,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _press(String digit) {
    HapticFeedback.selectionClick();
    onDigit(digit);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i != children.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.child, this.onTap, this.transparent = false})
    : blank = false;

  const _Key.blank()
    : label = null,
      child = null,
      onTap = null,
      transparent = true,
      blank = true;

  final String? label;
  final Widget? child;
  final VoidCallback? onTap;
  final bool transparent;
  final bool blank;

  @override
  Widget build(BuildContext context) {
    if (blank) return const SizedBox(height: 54);

    return Pressable(
      onTap: onTap,
      scale: 0.94,
      haptic: false,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: transparent ? Colors.transparent : uiFill,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: child != null
            ? child!
            : Text(
                label!,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  color: uiInk,
                  letterSpacing: -0.5,
                ),
              ),
      ),
    );
  }
}
