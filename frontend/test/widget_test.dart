import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shubamasthu_matrimony/main.dart';

void main() {
  testWidgets('App starts and displays splash screen', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MatrimonyApp(),
      ),
    );

    // Verify that the splash screen shows key brand texts.
    expect(find.text('Shubamasthu'), findsOneWidget);
    expect(find.text('Connecting Hearts, Uniting Souls'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
