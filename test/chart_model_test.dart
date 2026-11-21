import 'package:finscope/core/chart_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('synthetic candles preserve close and valid high/low bounds', () {
    final series = sampleCandles([1, 1.2, .9]);
    expect(series.map((c) => c.close), [1, 1.2, .9]);
    expect(series[1].open, 1);
    expect(series[2].rising, isFalse);
    expect(series[2].date.difference(series[0].date).inDays, 2);
    expect(() => Candle(date: DateTime.utc(2024), open: 1, high: .9, low: .8, close: 1), throwsArgumentError);
  });
  test('moving average is causal and rejects invalid periods', () {
    final data = sampleCandles([1, 2, 3, 4]);
    expect(simpleMovingAverage(data, 2), [null, 1.5, 2.5, 3.5]);
    expect(simpleMovingAverage(data.take(3).toList(), 2), simpleMovingAverage(data, 2).take(3));
    expect(() => simpleMovingAverage(data, 0), throwsArgumentError);
  });
  test('viewport clamps pan, zoom and lookup to visible data', () {
    final v = ChartViewport(100);
    expect(v.start, 40);
    expect(v.pan(-500).start, 0);
    expect(v.pan(500).end, 100);
    expect(v.zoom(100).count, 8);
    expect(v.zoom(.0001).count, 100);
    expect(v.indexAt(1), 99);
    expect(v.indexAt(-1), 40);
    expect(ChartViewport(0).indexAt(.5), isNull);
  });
  test('latest viewport follows new data, historical viewport does not', () {
    final v = ChartViewport(100);
    expect(v.resize(101).end, 101);
    expect(v.pan(-10).resize(101).start, 30);
    expect(v.resize(3).count, 3);
  });
}
