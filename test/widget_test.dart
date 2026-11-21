import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finscope/main.dart';
void main() {
  testWidgets('workspace and replay navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const FinScopeApp());
    expect(find.text('Market intelligence'), findsOneWidget);
    await tester.tap(find.text('Replay').first);
    await tester.pumpAndSettle();
    expect(find.text('Historical replay'), findsOneWidget);
    expect(find.text('Day 25 of 90'), findsOneWidget);
    await tester.ensureVisible(find.text('Next day'));
    await tester.tap(find.text('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('Day 26 of 90'), findsOneWidget);
  });
}
