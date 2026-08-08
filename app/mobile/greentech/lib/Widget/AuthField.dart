import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:greentech/Widget/AuthShell.dart' show captionStyle;

class AuthField extends StatefulWidget {
  const AuthField({
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
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _ownsFocusNode = false;
  bool _focused = false;
  late bool _obscured = widget.obscure;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
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
    final colors = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;

    final borderColor = hasError
        ? colors.error.withValues(alpha: 0.55)
        : _focused
        ? colors.onSurface
        : colors.outlineVariant;

    final valueStyle = TextStyle(
      fontSize: 16.5,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.1,
      color: colors.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          decoration: BoxDecoration(
            color: widget.enabled
                ? colors.surfaceContainerLowest
                : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: _focused ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: colors.outline,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextField(
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
                      style: valueStyle,
                      cursorWidth: 1.6,
                      cursorRadius: const Radius.circular(2),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle: valueStyle.copyWith(
                          color: colors.outline.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.obscure)
                IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 19,
                    color: colors.outline,
                  ),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 7),
            child: Text(
              widget.errorText!,
              style: TextStyle(fontSize: 12.5, color: colors.error),
            ),
          ),
      ],
    );
  }
}

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  int get _score {
    if (password.length < 8) return 0;
    var score = 1;
    if (password.length >= 12) score++;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    if (hasLetter && hasDigit && hasSymbol) score++;
    return score.clamp(0, 3);
  }

  static const _labels = ['At least 8 characters', 'Weak', 'Fair', 'Strong'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final score = _score;

    final scale = [
      colors.surfaceContainerHighest,
      const Color(0xFFD98324),
      const Color(0xFFB8A22E),
      colors.primary,
    ];

    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 3,
              decoration: BoxDecoration(
                color: i < score ? scale[score] : colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
        const SizedBox(width: 5),
        SizedBox(
          width: 118,
          child: Text(
            _labels[score],
            textAlign: TextAlign.right,
            style: captionStyle(context).copyWith(
              color: score == 0 ? colors.outline : scale[score],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
