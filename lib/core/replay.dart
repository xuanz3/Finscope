/// A deterministic, synthetic demonstration timeline. No live market feed.
class ReplayTimeline {
  final List<double> closes;
  int _index;
  ReplayTimeline(List<double> values, {int initialIndex = 0})
      : closes = List.unmodifiable(values), _index = initialIndex {
    if (closes.isEmpty || initialIndex < 0 || initialIndex >= closes.length ||
        closes.any((v) => !v.isFinite || v <= 0)) {
      throw ArgumentError('Invalid replay series');
    }
  }
  int get index => _index;
  bool get canAdvance => _index < closes.length - 1;
  double get current => closes[_index];
  List<double> get visible => List.unmodifiable(closes.take(_index + 1));
  bool advance() {
    if (!canAdvance) return false;
    _index++;
    return true;
  }
}
