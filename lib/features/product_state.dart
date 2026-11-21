import 'dart:math' as math;
import '../core/chart_model.dart';
import '../core/trading.dart';
import '../core/portfolio.dart';
import '../core/storage.dart';

class ProductState {
  ProductState({this.store, Map<String,dynamic>? snapshot}) {
    final saved=snapshot??store?.read('workspace');
    sampleVersion=saved==null?2:(saved['sampleVersion'] as int? ?? 1);
    for(final e in {'EUR/USD':1.08,'AUD/USD':.65,'GBP/USD':1.27,'USD/JPY':149.0,'S&P 500':5200.0,'BTC/USD':65000.0}.entries){
      final seed=e.key.codeUnits.fold(0,(a,b)=>a+b); final phase=seed%19; final candles=sampleCandles(List.generate(90,(i)=>e.value*(sampleVersion==1 ? (1+i*.0004+math.sin(i*.67)*.008+math.cos(i*.21)*.013) : (1+i*(seed%7-3)*.00018+math.sin(i*(.21+(seed%9)*.075)+phase)*.008+math.cos(i*.13+phase)*.013)))); 
      series[e.key]=MarketSeries(e.key,candles.map((c)=>DailyBar(c,e.key=='USD/JPY' ? .01 : 1.5)),source:'Synthetic sample — not historical data');
    }
    if(saved!=null){
      for(final raw in saved['imports'] as List){final s=MarketSeries.fromJson(Map<String,dynamic>.from(raw as Map));series[s.symbol]=s;}
      watchlist.addAll((saved['watchlist'] as List).cast<String>());if(watchlist.any((s)=>!series.containsKey(s)))throw const FormatException('Unknown watchlist symbol');journal.addAll((saved['journal'] as List).map((r)=>Map<String,dynamic>.from(r as Map)));
      portfolio=PortfolioBook.restore(Map<String,dynamic>.from(saved['portfolio'] as Map));
      final r=Map<String,dynamic>.from(saved['session'] as Map);session=TradingSession.restore(series[r['symbol']]!,r);
    }else{watchlist.addAll(['EUR/USD','AUD/USD','S&P 500']);session=TradingSession(series['EUR/USD']!,start:24);}
  }
  final LocalStore? store;
  late int sampleVersion;
  final series=<String,MarketSeries>{};
  final watchlist=<String>{};
  final journal=<Map<String,dynamic>>[];
  late TradingSession session;
  PortfolioBook portfolio=PortfolioBook();
  void save()=>store?.write('workspace',toJson());
  void restore(Map<String,dynamic> json){final validated=ProductState(snapshot:json);store?.write('workspace',validated.toJson());series..clear()..addAll(validated.series);watchlist..clear()..addAll(validated.watchlist);journal..clear()..addAll(validated.journal);portfolio=validated.portfolio;session=validated.session;sampleVersion=validated.sampleVersion;}
  Map<String,dynamic> toJson()=>{'sampleVersion':sampleVersion,'imports':series.values.where((s)=>!s.source.startsWith('Synthetic')).map((s)=>s.toJson()).toList(),'watchlist':watchlist.toList(),'journal':journal,'portfolio':portfolio.toJson(),'session':session.toJson()};
  void importSeries(MarketSeries s){if(series.containsKey(s.symbol))throw StateError('Symbol already exists. Choose a unique dataset name.');series[s.symbol]=s;save();}
}
