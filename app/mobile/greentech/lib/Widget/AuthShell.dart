import 'package:flutter/material.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.progress,
    this.footer,
    this.bottomBar,
  });

  final Widget child;

  final double? progress;

  final Widget? footer;

  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            const _Wordmark(),
            _ProgressRule(value: progress),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                  child: child,
                ),
              ),
            ),
            if (bottomBar != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                child: Column(
                  children: [
                    if (footer != null) ...[
                      footer!,
                      const SizedBox(height: 14),
                    ],
                    bottomBar!,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors.onSurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text(
            'GreenTech',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRule extends StatelessWidget {
  const _ProgressRule({this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      height: 2.5,
      child: Stack(
        children: [
          Container(color: colors.outlineVariant),
          if (value != null)
            LayoutBuilder(
              builder: (context, constraints) => AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * value!.clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class StepHeadline extends StatelessWidget {
  const StepHeadline(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 27,
            height: 1.22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.7,
            color: colors.onSurface,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class PrivacyNote extends StatelessWidget {
  const PrivacyNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: colors.outline,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: captionStyle(context))),
      ],
    );
  }
}

TextStyle captionStyle(BuildContext context) => TextStyle(
  fontSize: 12.5,
  height: 1.4,
  color: Theme.of(context).colorScheme.outline,
);
