import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Widget/UiKit.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.child,
    this.onBack,
    this.stepLabel,
    this.footer,
    this.actions,
  });

  final Widget child;
  final VoidCallback? onBack;
  final String? stepLabel;
  final Widget? footer;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: SizedBox(
                  height: 46,
                  child: Row(
                    children: [
                      if (onBack != null)
                        UiCircleButton(
                          icon: HugeIcons.strokeRoundedArrowLeft01,
                          onTap: onBack!,
                        ),
                      const Spacer(),
                      if (stepLabel != null)
                        Text(
                          stepLabel!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: uiInkTertiary,
                            letterSpacing: 0.1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: child,
                  ),
                ),
              ),
              if (actions != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      actions!,
                      if (footer != null) ...[
                        const SizedBox(height: 16),
                        footer!,
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

class AuthHeadline extends StatelessWidget {
  const AuthHeadline(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 33,
            height: 1.14,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            color: uiInk,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.45,
              color: uiInkSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthFootnote extends StatelessWidget {
  const AuthFootnote(this.text, {super.key, this.icon});

  final String text;
  final dynamic icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: HugeIcon(
            icon: icon ?? HugeIcons.strokeRoundedShield01,
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
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
  });

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 14.5,
              color: uiInkSecondary,
              letterSpacing: -0.1,
            ),
            children: [
              TextSpan(text: '$question '),
              TextSpan(
                text: action,
                style: const TextStyle(
                  color: uiInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
