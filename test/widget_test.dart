import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chronolith/main.dart';

void main() {
  setUpAll(() {
    // Prevent network font fetches during unit/widget tests
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Chronolith renders header, alarms, and 5 navigation tabs',
      (WidgetTester tester) async {
    // Configure phone-sized test viewport so all cards and bottom banners are visible
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ChronolithApp());
    await tester.pump();

    // Verify top brand header
    expect(find.text('Chronolith'), findsOneWidget);
    expect(find.text('TIME FOR A BRIGHTER YOU'), findsOneWidget);

    // Verify default Alarm tab content matching mockup
    expect(find.text('Your alarms'), findsOneWidget);
    expect(find.text('Wake up'), findsOneWidget);
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Bedtime reminder'), findsOneWidget);

    // Verify all 5 bottom navigation tabs exist
    expect(find.text('Alarm'), findsOneWidget);
    expect(find.text('Clock'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Stopwatch'), findsOneWidget);

    // Navigate to Clock tab
    await tester.tap(find.text('Clock'));
    await tester.pump();
    expect(find.text('LIVE CHRONOGRAPH'), findsOneWidget);

    // Navigate to World Clock tab
    await tester.tap(find.text('World'));
    await tester.pump();
    expect(find.text('World clocks'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);

    // Navigate to Timer tab
    await tester.tap(find.text('Timer'));
    await tester.pump();
    expect(find.text('Expressive presets'), findsOneWidget);

    // Navigate to Stopwatch tab
    await tester.tap(find.text('Stopwatch'));
    await tester.pump();
    expect(find.text('PRECISION STOPWATCH'), findsOneWidget);
  });
}
