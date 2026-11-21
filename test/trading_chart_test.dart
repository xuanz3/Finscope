import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finscope/core/chart_model.dart';
import 'package:finscope/widgets/trading_chart.dart';

void main() {
  testWidgets('chart controls switch view and clamp zoom on a narrow screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(350, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TradingChart(
      height: 200, candles: sampleCandles(List.generate(90, (i) => 1 + i / 100))))));
    expect(find.text('31–90 of 90 bars  ·  Drag to pan, scroll or pinch to zoom'), findsOneWidget);
    await tester.tap(find.text('Line'));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.ancestor(of: find.text('Line'), matching: find.byType(ChoiceChip))).selected, isTrue);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Reset chart'));
    await tester.pumpAndSettle();
    expect(find.text('31–90 of 90 bars  ·  Drag to pan, scroll or pinch to zoom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
