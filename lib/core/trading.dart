import 'dart:math' as math;
import 'chart_model.dart';

class DailyBar {
  DailyBar(this.candle, this.audPerQuote) {
    if (!audPerQuote.isFinite || audPerQuote <= 0 || audPerQuote > 1e6 || [candle.open,candle.high,candle.low,candle.close].any((v)=>v>1e9)) {
      throw ArgumentError('Invalid AUD conversion rate');
    }
  }
  final Candle candle;
  final double audPerQuote;
  List<Object> toJson() => [candle.date.toIso8601String().substring(0, 10),
    candle.open, candle.high, candle.low, candle.close, audPerQuote];
  factory DailyBar.fromJson(List<dynamic> row) => DailyBar(Candle(
    date: DateTime.parse('${row[0]}T00:00:00Z'), open: (row[1] as num).toDouble(),
    high: (row[2] as num).toDouble(), low: (row[3] as num).toDouble(),
    close: (row[4] as num).toDouble()), (row[5] as num).toDouble());
}

class MarketSeries {
  MarketSeries(this.symbol, Iterable<DailyBar> input, {required this.source})
      : bars = List.unmodifiable(input) {
    if (symbol.trim().isEmpty || symbol.length>80 || bars.length < 2 || bars.length>100000) throw ArgumentError('At least two daily bars are required');
    for (var i = 1; i < bars.length; i++) {
      if (!bars[i].candle.date.isAfter(bars[i-1].candle.date)) throw ArgumentError('Dates must be unique and ascending');
    }
  }
  final String symbol, source;
  final List<DailyBar> bars;
  Map<String, dynamic> toJson() => {'symbol':symbol,'source':source,'bars':bars.map((b)=>b.toJson()).toList()};
  factory MarketSeries.fromJson(Map<String,dynamic> j) => MarketSeries(j['symbol'] as String,
    (j['bars'] as List).map((r)=>DailyBar.fromJson(r as List)), source:j['source'] as String);
  factory MarketSeries.csv(String symbol, String content) {
    final lines = content.replaceFirst('\uFEFF','').split(RegExp(r'\r?\n')).where((s)=>s.trim().isNotEmpty).toList();
    if (lines.isEmpty || lines.first.trim().toLowerCase() != 'date,open,high,low,close,aud_per_quote') {
      throw const FormatException('Expected date,open,high,low,close,aud_per_quote');
    }
    if (lines.length > 100001) throw const FormatException('Maximum 100,000 daily bars');
    final rows = <DailyBar>[];
    for (var i=1;i<lines.length;i++) {
      try {
        final parts=lines[i].split(',').map((s)=>s.trim()).toList();
        if(parts.length!=6 || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(parts[0])) throw const FormatException();
        final date=DateTime.parse('${parts[0]}T00:00:00Z');
        if(date.toIso8601String().substring(0,10)!=parts[0]) throw const FormatException();
        rows.add(DailyBar.fromJson([parts[0], ...parts.skip(1).map(double.parse)]));
      } catch (_) {throw FormatException('Invalid daily candle on line ${i+1}');}
    }
    return MarketSeries(symbol.trim().toUpperCase(),rows,source:'Imported CSV');
  }
}

enum OrderKind { market, limit, stop }
class TradeOrder {
  TradeOrder({required this.units, required this.kind, this.trigger, this.stopLoss, this.takeProfit});
  final double units; // Signed base units; opposite orders close before reversing.
  final OrderKind kind;
  final double? trigger,stopLoss,takeProfit;
  Map<String,dynamic> toJson()=>{'units':units,'kind':kind.name,'trigger':trigger,'sl':stopLoss,'tp':takeProfit};
  factory TradeOrder.fromJson(Map<String,dynamic> j)=>TradeOrder(units:(j['units'] as num).toDouble(),kind:OrderKind.values.byName(j['kind'] as String),trigger:(j['trigger'] as num?)?.toDouble(),stopLoss:(j['sl'] as num?)?.toDouble(),takeProfit:(j['tp'] as num?)?.toDouble());
}

// Simulation accounting in AUD cents. No brokerage integration. Daily OHLC
// ambiguity is resolved conservatively: protective stop before profit target.
class TradingSession {
  TradingSession(this.series,{this.initialCapital=100000,this.start=0,this.leverage=1,this.spreadBps=2,this.commissionBps=1,this.slippageBps=1}) : index=start {
    if(!initialCapital.isFinite || initialCapital<0.01 || initialCapital>1e10 || start<0 || start>=series.bars.length || !leverage.isFinite || leverage<1 || leverage>10 || [spreadBps,commissionBps,slippageBps].any((v)=>!v.isFinite||v<0||v>1000)) throw ArgumentError('Invalid simulation settings');
    cashCents=(initialCapital*100).round(); equityHistory.add(equity);
  }
  final MarketSeries series;
  final double initialCapital,leverage,spreadBps,commissionBps,slippageBps;
  final int start;
  int index;
  late int cashCents;
  double units=0, entry=0;
  double? stopLoss,takeProfit;
  final pending=<TradeOrder>[];
  final fills=<Map<String,dynamic>>[];
  final events=<String>[];
  final equityHistory=<double>[];
  final actions=<Map<String,dynamic>>[];
  DailyBar get bar=>series.bars[index];
  List<Candle> get visible=>List.unmodifiable(series.bars.take(index+1).map((b)=>b.candle));
  bool get canAdvance=>index+1<series.bars.length;
  double get cash=>cashCents/100;
  double get unrealized=>units*(bar.candle.close-entry)*bar.audPerQuote;
  double get equity=>cash+unrealized;
  double get margin=>units.abs()*bar.candle.close*bar.audPerQuote/leverage;
  double get available=>equity-margin;
  double get drawdown {var peak=equityHistory.first;var dd=0.0;for(final e in equityHistory){peak=math.max(peak,e);dd=math.max(dd,(peak-e)/peak);}return dd;}
  double? get sharpe {final returns=<double>[];for(var i=1;i<equityHistory.length;i++){if(equityHistory[i-1]<=0)return null;returns.add(equityHistory[i]/equityHistory[i-1]-1);}if(returns.length<2)return null;final mean=returns.reduce((a,b)=>a+b)/returns.length;final variance=returns.fold(0.0,(sum,r)=>sum+math.pow(r-mean,2).toDouble())/(returns.length-1);return variance<=1e-20?null:mean/math.sqrt(variance)*math.sqrt(252);}
  double get totalReturn=>equity/initialCapital-1;
  void submit(TradeOrder order,{bool record=true}) {
    if(!canAdvance) throw StateError('No future trading day available');
    if(series.source.startsWith('ECB')&&(order.kind!=OrderKind.market||order.stopLoss!=null||order.takeProfit!=null))throw StateError('Reference-rate datasets support market orders only; no intraday prices are available');
    if(!order.units.isFinite || order.units.abs()<0.000001 || order.units.abs()>1e9 || [order.trigger,order.stopLoss,order.takeProfit].any((v)=>v!=null&&(!v.isFinite||v<=0)) || (order.kind!=OrderKind.market && order.trigger==null)) throw ArgumentError('Invalid order');
    if(pending.length>=100) throw StateError('Maximum 100 pending orders');
    pending.add(order);
    if(record) actions.add({'type':'submit','order':order.toJson()});
  }
  void cancelAll({bool record=true}) {pending.clear();if(record)actions.add({'type':'cancel'});}
  double? _execution(TradeOrder o,Candle c) {
    final t=o.trigger??0; final buy=o.units>0;
    switch(o.kind){
      case OrderKind.market:return c.open;
      case OrderKind.limit:return buy?(c.low<=t?math.min(c.open,t):null):(c.high>=t?math.max(c.open,t):null);
      case OrderKind.stop:return buy?(c.high>=t?math.max(c.open,t):null):(c.low<=t?math.min(c.open,t):null);
    }
  }
  bool _fill(double delta,double raw, DailyBar b,String reason,{TradeOrder? order,bool force=false}) {
    final friction=(spreadBps/2+slippageBps)/10000;
    var price=raw*(1+(delta>0?friction:-friction));
    if(order?.kind==OrderKind.limit)price=delta>0?math.min(price,order!.trigger!):math.max(price,order!.trigger!);
    final next=units+delta;
    final closing=units*delta<0?math.min(units.abs(),delta.abs()):0.0;
    final realized=closing*(price-entry)*units.sign*b.audPerQuote;
    final fee=(delta.abs()*price*b.audPerQuote*commissionBps/10000*100).round();
    final newCash=cashCents+(realized*100).round()-fee;
    final flat=next.abs()<1e-8;
    final nextEntry=flat?0.0:units==0||units*next<0?price:units*delta>0?(entry*units.abs()+price*delta.abs())/next.abs():entry;
    final eq=newCash/100+next*(raw-nextEntry)*b.audPerQuote;
    final required=next.abs()*raw*b.audPerQuote/leverage;
    final increasing=next.abs()>units.abs() || next*units<0;
    if(!force && increasing && (eq<required || eq<=0)) {events.add('Order rejected: insufficient margin');return false;}
    if(order!=null && !flat && ((order.stopLoss!=null && (next>0?order.stopLoss!>=price:order.stopLoss!<=price)) || (order.takeProfit!=null && (next>0?order.takeProfit!<=price:order.takeProfit!>=price)))) {events.add('Order rejected: invalid protective levels');return false;}
    units=flat?0:next;entry=nextEntry;cashCents=newCash;
    if(flat){stopLoss=null;takeProfit=null;}else if(order!=null){stopLoss=order.stopLoss;takeProfit=order.takeProfit;}
    fills.add({'date':b.candle.date.toIso8601String().substring(0,10),'units':delta,'price':price,'fee':fee/100,'realized':(realized*100).round()/100,'reason':reason});
    return true;
  }
  bool _protect(DailyBar b) {
    if(units==0)return false;final c=b.candle;final long=units>0;final sl=stopLoss;final tp=takeProfit;
    if(sl!=null && (long?c.low<=sl:c.high>=sl)){_fill(-units,long?math.min(c.open,sl):math.max(c.open,sl),b,'Stop loss',force:true);return true;}
    if(tp!=null && (long?c.high>=tp:c.low<=tp)){_fill(-units,long?math.max(c.open,tp):math.min(c.open,tp),b,'Take profit',force:true);return true;}
    return false;
  }
  bool advance({bool record=true}) {
    if(!canAdvance)return false;
    index++;final b=bar;
    // Existing protection takes priority. New intraday fills do not receive
    // same-day protection because OHLC does not encode intraday sequencing.
    _protect(b);
    for(final o in List<TradeOrder>.of(pending)){
      final price=_execution(o,b.candle);if(price==null)continue;
      _fill(o.units,price,b,o.kind.name,order:o);pending.remove(o);
    }
    if(units!=0 && (equity<=0||equity<margin*.5))_fill(-units,b.candle.close,b,'Margin liquidation',force:true);
    if(!canAdvance && pending.isNotEmpty){events.add('Unfilled orders expired at end of series');pending.clear();}
    equityHistory.add(equity);if(record)actions.add({'type':'advance'});return true;
  }
  Map<String,dynamic> toJson()=>{'symbol':series.symbol,'capital':initialCapital,'start':start,'leverage':leverage,'spread':spreadBps,'commission':commissionBps,'slippage':slippageBps,'actions':actions};
  factory TradingSession.restore(MarketSeries series,Map<String,dynamic> j){
    final s=TradingSession(series,initialCapital:(j['capital'] as num).toDouble(),start:j['start'] as int,leverage:(j['leverage'] as num).toDouble(),spreadBps:(j['spread'] as num).toDouble(),commissionBps:(j['commission'] as num).toDouble(),slippageBps:(j['slippage'] as num).toDouble());
    for(final a in j['actions'] as List){switch(a['type']){case 'submit':s.submit(TradeOrder.fromJson(Map<String,dynamic>.from(a['order'] as Map)));break;case 'advance':s.advance();break;case 'cancel':s.cancelAll();break;default:throw const FormatException('Unknown replay action');}}return s;
  }
}
