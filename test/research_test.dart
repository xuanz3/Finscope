import 'package:flutter_test/flutter_test.dart';
import 'package:finscope/core/chart_model.dart';
import 'package:finscope/core/research.dart';
import 'package:finscope/core/trading.dart';
import 'package:finscope/core/ecb_data.dart';
void main(){
  final c=sampleCandles(List.generate(70,(i)=>100.0+i));
  final s=MarketSeries('TEST',c.map((x)=>DailyBar(x,1)),source:'Imported CSV');
  test('EMA and Bollinger warm-up and values',(){expect(ema(c,3)[1],isNull);expect(ema(c,3)[2],101);expect(ema(c,3)[3],102);expect(bollinger(c,3,2)[2],closeTo(101+2*.81649658,1e-6));});
  test('SMA strategy advances with next-bar fills',(){final result=backtest(s,fast:5,slow:10);expect(result.index,69);expect(result.fills,isNotEmpty);expect(result.fills.first['date'],c[10].date.toIso8601String().substring(0,10));expect(result.equity,result.equityHistory.last);expect(correlation(s,s),closeTo(1,1e-10));});
  test('ECB derived FX reference observations and AUD quote conversion',(){final data=EcbData.parse('CURRENCY,TIME_PERIOD,OBS_VALUE\nUSD,2020-01-02,1.1\nAUD,2020-01-02,1.6\nUSD,2020-01-03,1.2\nAUD,2020-01-03,1.7','2020-01-02','2020-01-03');final a=data.firstWhere((s)=>s.symbol.startsWith('AUD/USD'));expect(a.bars.first.candle.close,closeTo(1.1/1.6,1e-10));expect(a.bars.first.audPerQuote,closeTo(1.6/1.1,1e-10));expect(a.bars.first.candle.high,a.bars.first.candle.low);expect(()=>TradingSession(a).submit(TradeOrder(units:10,kind:OrderKind.limit,trigger:.6)),throwsStateError);});
}
