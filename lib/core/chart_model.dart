import 'dart:math' as math;

/// Immutable, validated daily OHLC sample. Volume is intentionally omitted
/// because the initial forex data source has no exchange-wide real volume.
class Candle {
  Candle({required this.date, required this.open, required this.high,
    required this.low, required this.close}) {
    if ([open, high, low, close].any((v) => !v.isFinite || v <= 0) ||
        high < math.max(open, close) || low > math.min(open, close)) {
      throw ArgumentError('Invalid OHLC candle');
    }
  }
  final DateTime date;
  final double open, high, low, close;
  bool get rising => close >= open;
}

/// Deterministic synthetic input, not a market feed or historical assertion.
List<Candle> sampleCandles(List<double> closes) => List.unmodifiable(
  List.generate(closes.length, (i) {
    final close = closes[i];
    final open = i == 0 ? close * .998 : closes[i - 1];
    final spread = close * (.002 + (i % 7) * .0003);
    return Candle(date: DateTime.utc(2024, 1, 1 + i), open: open,
      high: math.max(open, close) + spread,
      low: math.min(open, close) - spread, close: close);
  }),
);

List<double?> simpleMovingAverage(List<Candle> candles, int period) {
  if (period < 1) throw ArgumentError.value(period, 'period');
  var sum = 0.0;
  return List.generate(candles.length, (i) {
    sum += candles[i].close;
    if (i >= period) sum -= candles[i - period].close;
    return i + 1 >= period ? sum / period : null;
  });
}

/// Half-open interval [start, end), always contained in the visible dataset.
class ChartViewport {
  ChartViewport(this.length, {int? count, int? start}) {
    if (length < 0) throw ArgumentError.value(length, 'length');
    this.count = (count ?? math.min(60, length)).clamp(math.min(8, length), length).toInt();
    this.start = (start ?? length - this.count).clamp(0, length - this.count).toInt();
  }
  final int length;
  late final int start, count;
  int get end => start + count;
  bool get atLatest => end == length;
  ChartViewport pan(int bars) => ChartViewport(length, count: count, start: start + bars);
  ChartViewport zoom(double factor, {double anchor = .5}) {
    if (!factor.isFinite || factor <= 0) return this;
    final a = anchor.clamp(0.0, 1.0).toDouble();
    final next = (count / factor).clamp(math.min(8, length).toDouble(), length.toDouble()).round();
    return ChartViewport(length, count: next, start: (start + (count - next) * a).round());
  }
  ChartViewport resize(int newLength) => ChartViewport(newLength, count: count,
    start: atLatest ? newLength - count : start);
  int? indexAt(double fraction) => count == 0 || !fraction.isFinite ? null : start +
    (fraction.clamp(0.0, 1.0) * count).floor().clamp(0, count - 1).toInt();
}
