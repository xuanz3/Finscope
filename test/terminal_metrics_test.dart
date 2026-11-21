import 'package:flutter_test/flutter_test.dart';
import 'package:finscope/core/chart_model.dart';
import 'package:finscope/core/trading.dart';
import 'package:finscope/features/terminal_workspace.dart';
void main(){
  test('Terminal metrics derive from local candles',(){
    final s=MarketSeries('TEST',sampleCandles(List.generate(25,(i)=>100.0+i)).map((c)=>DailyBar(c,1)),source:'Imported CSV');
    final m=MarketMetrics(s);
    expect(m.close,124);expect(m.change(1),closeTo(100/123,.00001));
    expect(m.sma20,114.5);expect(m.rsi,100);expect(m.spark.length,25);
  });
}
