import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  const NextButton({
    super.key,
    required this.enabled,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.arrow_forward_rounded,
    this.semanticLabel = 'Continue',
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;
  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = enabled && !busy;

    return Semantics(
      button: true,
      enabled: active,
      label: semanticLabel,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: active ? 1 : 0.55,
        child: Material(
          color: active ? colors.onSurface : colors.surfaceContainerHighest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: active ? onPressed : null,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.onSurface,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 22,
                        color: active ? Colors.white : colors.outline,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Go back',
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(
          side: BorderSide(color: colors.surfaceContainerHighest),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back_rounded,
              size: 19,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class StepNavBar extends StatelessWidget {
  const StepNavBar({super.key, this.onBack, required this.next, this.middle});

  final VoidCallback? onBack;
  final Widget next;
  final Widget? middle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: onBack == null
              ? const SizedBox.shrink()
              : BackCircleButton(onPressed: onBack!),
        ),
        Expanded(
          child: middle == null
              ? const SizedBox.shrink()
              : Center(child: middle!),
        ),
        SizedBox(width: 56, child: next),
      ],
    );
  }
}

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.filled = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool filled;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !busy;

    final background = filled
        ? (enabled ? colors.onSurface : colors.surfaceContainerHighest)
        : Colors.transparent;
    final foreground = filled
        ? (enabled ? Colors.white : colors.outline)
        : colors.onSurface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(30),
      clipBehavior: Clip.antiAlias,
      shape: filled
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(color: colors.surfaceContainerHighest),
            ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(foreground),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[icon!, const SizedBox(width: 10)],
                      Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
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

class ErrorNote extends StatelessWidget {
  const ErrorNote(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.error.withValues(alpha: 0.22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 17,
                    color: colors.error,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      message!,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
