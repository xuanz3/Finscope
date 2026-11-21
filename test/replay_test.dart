import 'package:flutter_test/flutter_test.dart';
import 'package:finscope/core/replay.dart';
void main() {
  test('future prices remain hidden and advancing stops at end', () {
    final t = ReplayTimeline([1.0, 1.2, 1.3]);
    expect(t.visible, [1.0]);
    expect(t.advance(), isTrue);
    expect(t.visible, [1.0, 1.2]);
    expect(t.advance(), isTrue);
    expect(t.advance(), isFalse);
    expect(t.current, 1.3);
  });
  test('invalid input rejected', () {
    expect(() => ReplayTimeline([]), throwsArgumentError);
    expect(() => ReplayTimeline([double.nan]), throwsArgumentError);
    expect(() => ReplayTimeline([1], initialIndex: 1), throwsArgumentError);
  });
}
