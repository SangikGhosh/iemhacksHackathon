import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final colors = Theme.of(context).colorScheme;

    final borderColor = hasError
        ? colors.error.withValues(alpha: 0.6)
        : active
        ? colors.onSurface
        : colors.outlineVariant;

    return AspectRatio(
      aspectRatio: 0.82,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor, width: active ? 1.6 : 1),
        ),
        child: Text(
          digit ?? '',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: colors.onSurface,
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

  static const _letters = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
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
                  _Key(
                    label: key,
                    sublabel: _letters[key],
                    onTap: enabled ? () => _press(key) : null,
                  ),
              ],
            ),
          _Row(
            children: [
              const _Key.blank(),
              _Key(label: '0', onTap: enabled ? () => _press('0') : null),
              _Key(
                icon: Icons.backspace_outlined,
                flat: true,
                onTap: enabled
                    ? () {
                        HapticFeedback.selectionClick();
                        onBackspace();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i != children.length - 1) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    this.label,
    this.sublabel,
    this.icon,
    this.onTap,
    this.flat = false,
  }) : blank = false;

  const _Key.blank()
    : label = null,
      sublabel = null,
      icon = null,
      onTap = null,
      flat = true,
      blank = true;

  final String? label;
  final String? sublabel;
  final IconData? icon;
  final VoidCallback? onTap;

  final bool flat;
  final bool blank;

  @override
  Widget build(BuildContext context) {
    if (blank) return const SizedBox(height: 48);

    final colors = Theme.of(context).colorScheme;

    return Material(
      color: flat ? Colors.transparent : colors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      elevation: flat ? 0 : 0.6,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 22, color: colors.onSurface)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label!,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          height: 1.05,
                          color: colors.onSurface,
                        ),
                      ),
                      if (sublabel != null)
                        Text(
                          sublabel!,
                          style: TextStyle(
                            fontSize: 8.5,
                            height: 1.2,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
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
