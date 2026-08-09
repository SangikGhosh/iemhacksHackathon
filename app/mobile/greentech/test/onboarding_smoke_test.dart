import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greentech/Screen/Onboarding/OnboardingScreen.dart';

void main() {
  testWidgets('onboarding renders every page without errors', (tester) async {
    for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(home: OnboardingScreen(key: ValueKey(size))),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Sort it right,\nevery time.'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Turn waste into\nGreen Points.'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.text('1,240'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Pickups that\nfind you.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.drag(find.byType(PageView), Offset(size.width * 0.6, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Turn waste into\nGreen Points.'), findsOneWidget);
    }
  });
}
