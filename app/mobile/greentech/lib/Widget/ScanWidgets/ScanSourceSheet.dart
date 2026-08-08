import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:greentech/Widget/UiKit.dart';

Future<ImageSource?> showScanSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: uiInk.withValues(alpha: 0.32),
    isScrollControlled: true,
    builder: (sheetContext) => const _ScanSourceSheet(),
  );
}

class _ScanSourceSheet extends StatelessWidget {
  const _ScanSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add a photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: uiInk,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Frame the waste clearly and keep it in good light.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: uiInkSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SourceRow(
                    icon: HugeIcons.strokeRoundedCamera01,
                    title: 'Take a photo',
                    subtitle: 'Open the camera',
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                  const UiHairline(indent: 60),
                  _SourceRow(
                    icon: HugeIcons.strokeRoundedImage02,
                    title: 'Choose from library',
                    subtitle: 'Pick an existing picture',
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Pressable(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
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
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: uiFill,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: HugeIcon(icon: icon, color: uiInk, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: uiInk,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: uiInkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: uiInkTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
