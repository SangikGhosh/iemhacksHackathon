import 'package:flutter/material.dart';

import 'package:greentech/Widget/UiKit.dart';

class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = <String, bool>{
      'At least 8 characters': password.length >= 8,
      'A letter and a number':
          RegExp(r'[A-Za-z]').hasMatch(password) &&
          RegExp(r'\d').hasMatch(password),
      'A symbol makes it stronger': RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in rules.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: uiQuick,
                  curve: uiEase,
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: rule.value ? uiGreen : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rule.value ? uiGreen : uiHairlineStrong,
                      width: 1.4,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: rule.value
                      ? const Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 11),
                AnimatedDefaultTextStyle(
                  duration: uiQuick,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: rule.value ? FontWeight.w600 : FontWeight.w500,
                    color: rule.value ? uiInk : uiInkTertiary,
                    letterSpacing: -0.1,
                  ),
                  child: Text(rule.key),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
