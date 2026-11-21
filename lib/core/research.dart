import 'dart:math' as math;
import 'chart_model.dart';
import 'trading.dart';

List<double?> ema(List<Candle> candles, int n) {
  if(n<1) throw ArgumentError.value(n);
  double? prev;
  final sma=simpleMovingAverage(candles,n);
  return List.generate(candles.length,(i){
    if(i<n-1)return null;
    prev=prev==null?sma[i]:prev!+(candles[i].close-prev!)*2/(n+1);
    return prev;
  });
}
List<double?> bollinger(List<Candle> candles,int n,double deviation){
  final avg=simpleMovingAverage(candles,n);
  return List.generate(candles.length,(i){if(avg[i]==null)return null;final a=avg[i]!;var v=0.0;for(var j=i-n+1;j<=i;j++){v+=math.pow(candles[j].close-a,2).toDouble();}return a+deviation*math.sqrt(v/n);});
}
Map<String,double> dailyReturns(MarketSeries s)=>{for(var i=1;i<s.bars.length;i++) s.bars[i].candle.date.toIso8601String().substring(0,10):s.bars[i].candle.close/s.bars[i-1].candle.close-1};
double? correlation(MarketSeries a,MarketSeries b){
  final x=dailyReturns(a),y=dailyReturns(b);final keys=x.keys.where(y.containsKey).toList();if(keys.length<3)return null;
  final ax=keys.fold(0.0,(s,k)=>s+x[k]!)/keys.length,ay=keys.fold(0.0,(s,k)=>s+y[k]!)/keys.length;
  var xx=0.0,yy=0.0,xy=0.0;for(final k in keys){final dx=x[k]!-ax,dy=y[k]!-ay;xx+=dx*dx;yy+=dy*dy;xy+=dx*dy;}return xx*yy==0?null:(xy/math.sqrt(xx*yy)).clamp(-1.0,1.0).toDouble();
}
/// Long/flat, close-based SMA crossover. Signals execute at the next bar;
/// allocation leaves a 5% buffer for fees and market gaps. Same engine as replay.
TradingSession backtest(MarketSeries data,{int fast=10,int slow=30,double capital=100000,double allocation=.95}){
  if(fast<1||slow<=fast||slow>=data.bars.length||allocation<=0||allocation>.95)throw ArgumentError('Invalid strategy parameters or insufficient data');
  final candles=data.bars.map((x)=>x.candle).toList();final a=simpleMovingAverage(candles,fast),b=simpleMovingAverage(candles,slow);
  final s=TradingSession(data,start:slow-1,initialCapital:capital);
  while(s.canAdvance){final i=s.index;final long=a[i]!>b[i]!;if(long&&s.units==0&&s.equity>0){final units=s.equity*allocation/(s.bar.candle.close*s.bar.audPerQuote);if(units>=.000001)s.submit(TradeOrder(units:math.min(units,1e9),kind:OrderKind.market));}else if(!long&&s.units!=0){s.submit(TradeOrder(units:-s.units,kind:OrderKind.market));}s.advance();}return s;
}
