import 'dart:async';
import 'dart:ui' show FontFeature;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/trading.dart';
import '../design_system/theme.dart';
import '../design_system/motion.dart';
import '../widgets/primitives.dart';
import '../widgets/trading_chart.dart';
import 'product_state.dart';

String terminalDate(DateTime d) => d.toIso8601String().substring(0,10);
String terminalPrice(double v) => v.toStringAsFixed(v.abs() < 10 ? 4 : 2);
String terminalPct(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}%';
Color terminalColor(double v) => v >= 0 ? FinTheme.gain : FinTheme.loss;

class MarketMetrics {
  MarketMetrics(this.series);
  final MarketSeries series;
  List<DailyBar> get bars => series.bars;
  double get close => bars.last.candle.close;
  double change(int days) => (close / bars[math.max(0,bars.length-1-days)].candle.close - 1)*100;
  double get sma20 { final sample=bars.skip(math.max(0,bars.length-20)); return sample.fold(0.0,(v,b)=>v+b.candle.close)/sample.length; }
  double? get rsi {
    if(bars.length < 15) return null;
    var up=0.0,down=0.0;
    for(var i=bars.length-14;i<bars.length;i++) { final diff=bars[i].candle.close-bars[i-1].candle.close; up+=math.max(0.0,diff); down+=math.max(0.0,-diff); }
    return up+down==0 ? 50.0 : 100*up/(up+down);
  }
  double get rangeHigh => bars.skip(math.max(0,bars.length-20)).map((b)=>b.candle.high).reduce(math.max);
  double get rangeLow => bars.skip(math.max(0,bars.length-20)).map((b)=>b.candle.low).reduce(math.min);
  List<double> get spark => bars.skip(math.max(0,bars.length-28)).map((b)=>b.candle.close).toList();
  String get category => series.source.startsWith('ECB') ? 'Forex' : series.symbol=='S&P 500' ? 'Indices' : series.symbol.startsWith('BTC/') ? 'Crypto' : ['EUR/USD','AUD/USD','GBP/USD','USD/JPY'].contains(series.symbol) ? 'Forex' : 'Imported';
  bool get sample => series.source.startsWith('Synthetic');
}

class DeskPanel extends StatelessWidget {
  const DeskPanel({super.key, required this.title, required this.child, this.action});
  final String title; final Widget child; final Widget? action;
  @override Widget build(BuildContext context) => Material(color:FinTheme.surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3),side:const BorderSide(color:FinTheme.border)),clipBehavior:Clip.antiAlias, child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),child:Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w500))),if(action!=null)action!])),
    const Divider(height:1), Padding(padding:const EdgeInsets.all(9),child:child),
  ]));
}

class TerminalWorkspace extends StatefulWidget {
  const TerminalWorkspace({super.key,required this.model,required this.symbol,required this.onSymbol,required this.onWatch,required this.onReplay,required this.onNewReplay,required this.onPortfolio,required this.onImport,this.overview=false,this.autoplay=false,this.archive});
  final ProductState model; final String symbol; final ValueChanged<String> onSymbol,onWatch,onNewReplay; final VoidCallback onReplay,onPortfolio,onImport; final bool overview,autoplay; final Widget? archive;
  @override State<TerminalWorkspace> createState()=>_TerminalWorkspaceState();
}
class _TerminalWorkspaceState extends State<TerminalWorkspace> {
  String filter='All',query='',sort='Symbol'; bool descending=false,watchOnly=false,heatmap=false; int period=60; String detail='Technical';
  Timer? ambientTimer;
  final tapeController=ScrollController();
  bool tapeHover=false;
  bool ambientPaused=false;
  @override void didChangeDependencies(){super.didChangeDependencies();scheduleAmbient();}
  @override void didUpdateWidget(covariant TerminalWorkspace old){super.didUpdateWidget(old);if(old.autoplay!=widget.autoplay)scheduleAmbient();}
  void scheduleAmbient(){ambientTimer?.cancel();if(widget.autoplay&&!ambientPaused&&!MediaQuery.disableAnimationsOf(context)){ambientTimer=Timer.periodic(const Duration(seconds:8),(_){if(!mounted||!TickerMode.of(context)||ModalRoute.of(context)?.isCurrent==false)return;if(!tapeHover&&tapeController.hasClients&&tapeController.position.hasContentDimensions){final p=tapeController.position;final target=p.pixels+240>=p.maxScrollExtent?p.minScrollExtent:math.min(p.maxScrollExtent,p.pixels+240);if((target-p.pixels).abs()>1)tapeController.animateTo(target,duration:const Duration(milliseconds:650),curve:Curves.easeInOutCubic);}final rows=all;if(rows.length>1){final i=rows.indexWhere((m)=>m.series.symbol==widget.symbol);widget.onSymbol(rows[(i+1)%rows.length].series.symbol);}});}}
  void selectSymbol(String symbol){ambientPaused=true;scheduleAmbient();widget.onSymbol(symbol);}
  @override void dispose(){ambientTimer?.cancel();tapeController.dispose();super.dispose();}
  List<MarketMetrics> get all=>widget.model.series.values.map(MarketMetrics.new).toList()..sort((a,b)=>a.sample==b.sample?0:a.sample?1:-1);
  MarketMetrics get current=>MarketMetrics(widget.model.series[widget.symbol]??widget.model.series.values.first);
  List<MarketMetrics> get filtered {
    final rows=all.where((m)=>(filter=='All'||m.category==filter)&&(!watchOnly||widget.model.watchlist.contains(m.series.symbol))&&m.series.symbol.toLowerCase().contains(query.toLowerCase())).toList();
    rows.sort((a,b){final c=switch(sort){'Price'=>a.close.compareTo(b.close),'1D'=>a.change(1).compareTo(b.change(1)),'5D'=>a.change(5).compareTo(b.change(5)),'20D'=>a.change(20).compareTo(b.change(20)),_=>a.series.symbol.compareTo(b.series.symbol)};return descending?-c:c;});return rows;
  }
  Widget label(String s)=>Text(s,style:const TextStyle(fontSize:10,color:FinTheme.steel));
  Widget number(String s,{Color? color,double size=12})=>Text(s,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:size,color:color??FinTheme.ink,fontWeight:size>=18?FontWeight.w500:FontWeight.w400,fontFeatures:const [FontFeature.tabularFigures()]));
  Widget animatedNumber(double value,String Function(double) format,{double size=21,Color? color})=>TweenAnimationBuilder<double>(tween:Tween(end:value),duration:FinMotion.duration(context,FinMotion.value),curve:FinMotion.curve,builder:(_,v,__)=>number(format(v),size:size,color:color));
  Widget chip(String name,bool active,VoidCallback action)=>Padding(padding:const EdgeInsets.only(right:3),child:InkWell(borderRadius:BorderRadius.circular(4),onTap:action,child:AnimatedContainer(duration:FinMotion.duration(context,FinMotion.hover),padding:const EdgeInsets.symmetric(horizontal:7,vertical:5),decoration:BoxDecoration(color:active?FinTheme.slate:Colors.transparent,borderRadius:BorderRadius.circular(4)),child:Text(name,style:TextStyle(fontSize:11,color:active?FinTheme.ink:FinTheme.steel)))));
  Widget spread(String a,String b,{Color? color})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:label(a)),number(b,color:color)]));
  Widget mark(MarketMetrics m){
    final symbol=m.series.symbol;
    final glyph=switch(symbol){'AUD/USD'=>'AU','EUR/USD'=>'EU','GBP/USD'=>'GB','USD/JPY'=>'JP','BTC/USD'=>'₿','S&P 500'=>'SP',_=>symbol.substring(0,math.min(2,symbol.length))};
    final color=switch(symbol){'BTC/USD'=>const Color(0xFFD49643),'EUR/USD'=>const Color(0xFF526FA9),'USD/JPY'=>const Color(0xFFB15A68),'AUD/USD'=>const Color(0xFF567F92),'GBP/USD'=>const Color(0xFF817CA5),_=>FinTheme.steel};
    return Container(width:28,height:28,alignment:Alignment.center,decoration:BoxDecoration(color:color.withAlpha(35),shape:BoxShape.circle,border:Border.all(color:color.withAlpha(90))),child:Text(glyph,style:TextStyle(color:color,fontSize:10,fontWeight:FontWeight.w600)));
  }
  Widget ticker(MarketMetrics m)=>InkWell(
    onTap:()=>selectSymbol(m.series.symbol),
    child:Padding(padding:const EdgeInsets.symmetric(horizontal:6,vertical:6),
      child:LayoutBuilder(builder:(context,c){
        final showMark=c.maxWidth>=140;
        final showSpark=c.maxWidth>=245;
        return Row(children:[
          if(showMark)...[mark(m),const SizedBox(width:7)],
          Expanded(flex:5,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            number(m.series.symbol),
            Text(m.category,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:FinTheme.steel)),
          ])),
          if(showSpark)...[const SizedBox(width:5),SizedBox(width:48,height:23,child:CustomPaint(painter:_Spark(m.spark,terminalColor(m.change(1)))))],
          const SizedBox(width:6),
          Expanded(flex:6,child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
            number(terminalPrice(m.close)),
            number(terminalPct(m.change(1)),color:terminalColor(m.change(1)),size:10),
          ])),
        ]);
      }),
    ),
  );
  Widget strip(){
    final p=widget.model.portfolio,s=widget.model.session;
    final metrics=[('PORTFOLIO VALUE',p.equity,'Manual valuation',FinTheme.steel),('REPLAY EQUITY',s.equity,terminalPct(s.totalReturn*100),terminalColor(s.totalReturn)),('CASH BALANCE',p.cash,'AUD ledger',FinTheme.steel),('DATASETS',all.length.toDouble(),'Local observations',FinTheme.steel)];
    return LayoutBuilder(builder:(_,c){final n=c.maxWidth>=650?4:2;return Material(color:FinTheme.surface,shape:const RoundedRectangleBorder(side:BorderSide(color:FinTheme.border)),child:Wrap(children:[for(final (i,v) in metrics.indexed)SizedBox(width:(c.maxWidth-2)/n,child:Container(decoration:BoxDecoration(border:Border(right:BorderSide(color:(i+1)%n==0?Colors.transparent:FinTheme.border),bottom:BorderSide(color:n==2&&i<2?FinTheme.border:Colors.transparent))),padding:const EdgeInsets.fromLTRB(11,9,8,9),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[label(v.$1),const SizedBox(height:5),animatedNumber(v.$2,(n)=>i==3?n.round().toString():'A\$${formatAmount(n)}',size:20),const SizedBox(height:3),number(v.$3,size:10,color:v.$4)])))]));});
  }
  Widget directory()=>DeskPanel(title:'Markets',action:IconButton(tooltip:'Import market data',visualDensity:VisualDensity.compact,icon:const Icon(Icons.add,size:16),onPressed:widget.onImport),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[TextField(onChanged:(s)=>setState(()=>query=s),style:const TextStyle(fontSize:12),decoration:const InputDecoration(isDense:true,prefixIcon:Icon(Icons.search,size:16),hintText:'Find a symbol',contentPadding:EdgeInsets.all(8))),const SizedBox(height:8),Wrap(children:[for(final v in ['All','Forex','Indices','Crypto','Imported'])chip(v,filter==v,()=>setState(()=>filter=v))]),const Divider(height:12),for(final (i,m) in filtered.take(18).indexed)Material(color:m.series.symbol==widget.symbol?FinTheme.slate:i.isEven?FinTheme.elevated:FinTheme.surface,child:ticker(m)),if(filtered.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('No matching datasets.'))]));
  Widget graph(MarketMetrics m,double height){final bars=m.bars.skip(math.max(0,m.bars.length-period)).map((b)=>b.candle).toList();return DeskPanel(title:'Price chart',action:IconButton(tooltip:'Toggle watchlist',visualDensity:VisualDensity.compact,icon:Icon(widget.model.watchlist.contains(m.series.symbol)?Icons.star:Icons.star_border,size:18),onPressed:()=>widget.onWatch(m.series.symbol)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[mark(m),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[number(m.series.symbol,size:22),label('${m.category}  /  ${m.sample?'Synthetic sample':m.series.source}')])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[animatedNumber(m.close,terminalPrice,size:27),animatedNumber(m.change(1),terminalPct,size:12,color:terminalColor(m.change(1)))])]),const SizedBox(height:8),Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[for(final n in [20,60,90,100000])chip(n==100000?'All':'${n}D',period==n,()=>setState(()=>period=n)),const SizedBox(width:6),label(m.series.source.startsWith('ECB')?'Reference observations':'Daily bars')]),const SizedBox(height:4),DataArrival(key:ValueKey('${m.series.symbol}-$period'),child:TradingChart(candles:bars,height:height,decimals:m.close<10?4:2)),const Divider(height:14),Wrap(spacing:8,runSpacing:5,children:[MotionButton(label:'New replay',icon:Icons.history,onPressed:()=>widget.onNewReplay(m.series.symbol)),OutlinedButton(onPressed:widget.onImport,child:const Text('Import data'))]) ]));}
  Widget details(MarketMetrics m)=>DeskPanel(title:'Instrument details',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(children:[for(final v in ['Technical','Returns','Data'])chip(v,detail==v,()=>setState(()=>detail=v))]),const Divider(height:14),if(detail=='Technical')...[spread('Open',terminalPrice(m.bars.last.candle.open)),spread('High',terminalPrice(m.bars.last.candle.high)),spread('Low',terminalPrice(m.bars.last.candle.low)),spread('SMA 20',terminalPrice(m.sma20)),spread('RSI 14 (simple)',m.rsi?.toStringAsFixed(1)??'N/A'),const SizedBox(height:5),label('20-bar price range'),const SizedBox(height:6),LinearProgressIndicator(value:((m.close-m.rangeLow)/math.max(m.rangeHigh-m.rangeLow,1e-9)).clamp(0.0,1.0).toDouble(),color:FinTheme.ivory,backgroundColor:FinTheme.rail),spread(terminalPrice(m.rangeLow),terminalPrice(m.rangeHigh)),spread('Price vs average',m.close>=m.sma20?'Above SMA':'Below SMA',color:terminalColor(m.close-m.sma20))]else if(detail=='Returns')...[for(final d in [1,5,20,60])spread('$d bars',terminalPct(m.change(d)),color:terminalColor(m.change(d)))]else...[spread('Coverage','${m.bars.length} bars'),spread('First date',terminalDate(m.bars.first.candle.date)),spread('Last date',terminalDate(m.bars.last.candle.date)),label(m.series.source)],const Divider(height:15),label('Watchlist'),const SizedBox(height:5),for(final v in all.where((v)=>widget.model.watchlist.contains(v.series.symbol)))ticker(v)]));
  Widget screener()=>DeskPanel(title:'Market screener',action:TextButton.icon(onPressed:()=>setState(()=>heatmap=!heatmap),icon:Icon(heatmap?Icons.table_rows:Icons.grid_view,size:15),label:Text(heatmap?'Table':'Heatmap',style:const TextStyle(fontSize:11))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[for(final v in ['All','Forex','Indices','Crypto','Imported'])chip(v,filter==v,()=>setState(()=>filter=v)),chip('Watchlist',watchOnly,()=>setState(()=>watchOnly=!watchOnly))]),const SizedBox(height:6),if(heatmap)LayoutBuilder(builder:(_,c){final n=c.maxWidth>=600?4:2;return Wrap(spacing:4,runSpacing:4,children:[for(final m in filtered)SizedBox(width:(c.maxWidth-(n-1)*4)/n,height:65,child:Material(color:terminalColor(m.change(1)).withAlpha((45+m.change(1).abs()*15).clamp(45,150).toInt()),borderRadius:BorderRadius.circular(3),child:InkWell(onTap:()=>selectSymbol(m.series.symbol),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[number(m.series.symbol),number(terminalPct(m.change(1)))]))))) ]);})else LayoutBuilder(builder:(_,bounds)=>SingleChildScrollView(scrollDirection:Axis.horizontal,child:ConstrainedBox(constraints:BoxConstraints(minWidth:bounds.maxWidth),child:DataTable(horizontalMargin:5,columnSpacing:16,headingRowHeight:27,dataRowMinHeight:29,dataRowMaxHeight:32,sortColumnIndex:['Symbol','Price','1D','5D','20D'].indexOf(sort),sortAscending:!descending,columns:[for(final v in ['Symbol','Price','1D','5D','20D'])DataColumn(label:label(v),numeric:v!='Symbol',onSort:(_,asc)=>setState((){sort=v;descending=!asc;})),DataColumn(label:label('Trend')),DataColumn(label:label('Source'))],rows:[for(final (i,m) in filtered.take(100).indexed)DataRow(color:WidgetStateProperty.resolveWith((states)=>states.contains(WidgetState.selected)?FinTheme.slate:states.contains(WidgetState.hovered)?FinTheme.slate.withAlpha(150):i.isEven?FinTheme.elevated:FinTheme.surface),selected:m.series.symbol==widget.symbol,onSelectChanged:(_)=>selectSymbol(m.series.symbol),cells:[DataCell(number(m.series.symbol)),DataCell(number(terminalPrice(m.close))),for(final d in [1,5,20])DataCell(number(terminalPct(m.change(d)),color:terminalColor(m.change(d)))),DataCell(SizedBox(width:55,height:22,child:CustomPaint(painter:_Spark(m.spark,terminalColor(m.change(5)))))),DataCell(label(m.sample?'Sample':m.series.source.startsWith('ECB')?'ECB':'CSV'))])],showCheckboxColumn:false)))),if(filtered.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('No matching instruments.')),const SizedBox(height:5),label('Returns use available daily bars; sample data is not market history.') ]));
  Widget sessionCard()=>DeskPanel(title:'Saved replay',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[spread('Instrument',widget.model.session.series.symbol),spread('Replay date',terminalDate(widget.model.session.bar.candle.date)),spread('Pending orders','${widget.model.session.pending.length}'),spread('Trade fills','${widget.model.session.fills.length}'),const SizedBox(height:7),MotionButton(label:'Resume replay',icon:Icons.play_arrow,onPressed:widget.onReplay),const SizedBox(height:5),TextButton(onPressed:widget.onPortfolio,child:const Text('Open portfolio'))]));
  Widget marketPulse(){
    final rows=all;
    final rising=rows.where((m)=>m.change(1)>0).length;
    final falling=rows.where((m)=>m.change(1)<0).length;
    final flat=rows.length-rising-falling;
    final ranked=List<MarketMetrics>.of(rows)..sort((a,b)=>b.change(5).compareTo(a.change(5)));
    return DeskPanel(title:'Market pulse',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      label('DAILY BREADTH'),const SizedBox(height:8),
      SizedBox(height:6,child:ClipRRect(borderRadius:BorderRadius.circular(3),child:Row(children:[if(rising>0)Expanded(flex:rising,child:const ColoredBox(color:FinTheme.gain)),if(flat>0)Expanded(flex:flat,child:const ColoredBox(color:FinTheme.steel)),if(falling>0)Expanded(flex:falling,child:const ColoredBox(color:FinTheme.loss))]))),
      const SizedBox(height:8),spread('Advancing','$rising',color:FinTheme.gain),spread('Declining','$falling',color:FinTheme.loss),spread('Unchanged','$flat'),
      const Divider(height:18),label('5-BAR PERFORMANCE'),const SizedBox(height:6),
      for(final m in ranked.take(4))InkWell(onTap:()=>selectSymbol(m.series.symbol),child:Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:number(m.series.symbol)),number(terminalPct(m.change(5)),color:terminalColor(m.change(5)),size:11)]))),
      const SizedBox(height:6),label('Local datasets only')
    ]));
  }
  Widget marketTape()=>MouseRegion(onEnter:(_)=>tapeHover=true,onExit:(_)=>tapeHover=false,child:SizedBox(height:54,child:ListView.separated(controller:tapeController,scrollDirection:Axis.horizontal,itemCount:all.take(12).length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){final m=all[i];return Material(color:FinTheme.surface,borderRadius:BorderRadius.circular(4),child:InkWell(onTap:()=>selectSymbol(m.series.symbol),borderRadius:BorderRadius.circular(4),child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),child:Row(children:[mark(m),const SizedBox(width:8),SizedBox(width:111,child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[number(m.series.symbol),label(m.sample?'Sample':terminalDate(m.bars.last.candle.date))])),const SizedBox(width:7),Column(crossAxisAlignment:CrossAxisAlignment.end,mainAxisAlignment:MainAxisAlignment.center,children:[number(terminalPrice(m.close)),number(terminalPct(m.change(1)),color:terminalColor(m.change(1)),size:11)]),const SizedBox(width:8),SizedBox(width:44,height:24,child:CustomPaint(painter:_Spark(m.spark,terminalColor(m.change(1))))) ]))));})));
  Widget comparison(){
    final candidates=all.take(5).toList();
    return DeskPanel(title:'Relative performance',action:label('20 obs / %'),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      SizedBox(height:126,child:RepaintBoundary(child:CustomPaint(painter:_RelativePainter(candidates)))),const SizedBox(height:8),
      Wrap(spacing:12,runSpacing:5,children:[for(final (i,m) in candidates.indexed)Row(mainAxisSize:MainAxisSize.min,children:[Container(width:8,height:3,color:_seriesColors[i%_seriesColors.length]),const SizedBox(width:5),label(m.series.symbol)])]),
      const SizedBox(height:6),label('Each series normalized to its own first observation. Dates may differ.')
    ]));
  }
  Widget returnBars(){final ranked=all.toList()..sort((a,b)=>b.change(20).compareTo(a.change(20)));final maxAbs=ranked.fold(0.01,(double v,m)=>math.max(v,m.change(20).abs()));
    return DeskPanel(title:'Performance ranking',action:label('20 bars'),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[for(final m in ranked.take(8))Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[
      SizedBox(width:63,child:Text(m.series.symbol,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:FinTheme.steel))),
      Expanded(child:LayoutBuilder(builder:(context,c){final v=m.change(20);return Row(children:[Expanded(child:Align(alignment:Alignment.centerRight,child:TweenAnimationBuilder<double>(key:ValueKey('${m.series.symbol}-negative'),tween:Tween(end:v<0?v.abs()/maxAbs:0),duration:FinMotion.duration(context,FinMotion.value),curve:FinMotion.curve,builder:(_,n,__)=>Container(height:10,width:c.maxWidth*.48*n,color:FinTheme.loss)))),Container(width:1,height:15,color:FinTheme.border),Expanded(child:Align(alignment:Alignment.centerLeft,child:TweenAnimationBuilder<double>(key:ValueKey('${m.series.symbol}-positive'),tween:Tween(end:v>0?v/maxAbs:0),duration:FinMotion.duration(context,FinMotion.value),curve:FinMotion.curve,builder:(_,n,__)=>Container(height:10,width:c.maxWidth*.48*n,color:FinTheme.gain))))]);})),
      const SizedBox(width:5),SizedBox(width:49,child:Align(alignment:Alignment.centerRight,child:number(terminalPct(m.change(20)),color:terminalColor(m.change(20)),size:10)))
    ])),const SizedBox(height:5),label('Local datasets · not live quotes')]));
  }
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(_,c){
    final wide=c.maxWidth>=1000,medium=c.maxWidth>=670;
    final m=current;
    final center=Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(widget.overview)...[graph(m,wide?300:265),const SizedBox(height:5),screener()]else ...[graph(m,wide?310:265),const SizedBox(height:5),screener()],const SizedBox(height:5),comparison()]);
    final side=Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(widget.archive!=null)...[widget.archive!,const SizedBox(height:5)],details(m),const SizedBox(height:5),returnBars(),const SizedBox(height:5),sessionCard()]);
    final left=Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[directory(),const SizedBox(height:5),marketPulse()]);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(children:[Expanded(child:Text(widget.overview?'Market intelligence':'Market directory',style:const TextStyle(fontSize:17,fontWeight:FontWeight.w500,letterSpacing:-.35))),if(widget.autoplay)TextButton.icon(onPressed:(){setState(()=>ambientPaused=!ambientPaused);scheduleAmbient();},icon:Icon(ambientPaused?Icons.play_arrow:Icons.pause,size:14),label:Text(ambientPaused?'Rotate':'Auto rotate')),label('LOCAL / DAILY')]),const SizedBox(height:7),
      marketTape(),const SizedBox(height:5),if(widget.overview)...[strip(),const SizedBox(height:5)],
      if(wide)Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:194,child:left),const SizedBox(width:5),Expanded(child:center),const SizedBox(width:5),SizedBox(width:245,child:side)])
      else if(medium)Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:center),const SizedBox(width:5),SizedBox(width:210,child:Column(children:[left,const SizedBox(height:5),side]))])
      else ...[graph(m,205),const SizedBox(height:5),left,const SizedBox(height:5),screener(),const SizedBox(height:5),side,const SizedBox(height:5),comparison()]
    ]);
  });
}
class _Spark extends CustomPainter {
  _Spark(this.values,this.color);final List<double> values;final Color color;
  @override void paint(Canvas canvas,Size size){if(values.length<2)return;final low=values.reduce(math.min),high=values.reduce(math.max),span=math.max(high-low,1e-9);final path=Path();for(var i=0;i<values.length;i++){final x=i*size.width/(values.length-1),y=2+(high-values[i])/span*(size.height-4);if(i==0){path.moveTo(x,y);}else{path.lineTo(x,y);}}canvas.drawPath(path,Paint()..color=color..strokeWidth=1.2..style=PaintingStyle.stroke);}
  @override bool shouldRepaint(covariant _Spark oldDelegate)=>oldDelegate.values!=values||oldDelegate.color!=color;
}

const _seriesColors=[FinTheme.gain,FinTheme.ivory,Color(0xFF91A5E1),Color(0xFFE0AF72),Color(0xFFB289CE)];
class _RelativePainter extends CustomPainter {
  _RelativePainter(this.rows);final List<MarketMetrics> rows;
  @override void paint(Canvas canvas,Size size){
    if(size.width<65||size.height<40||rows.isEmpty)return;
    final values=rows.map((m){final b=m.bars.skip(math.max(0,m.bars.length-20)).map((v)=>v.candle.close).toList();return b.map((v)=>(v/b.first-1)*100).toList();}).toList();
    double low=0,high=0;for(final series in values){for(final v in series){low=math.min(low,v);high=math.max(high,v);}}
    final span=math.max(high-low,.01),w=size.width-45,h=size.height-15;
    for(var i=0;i<=3;i++){final y=h*i/3;canvas.drawLine(Offset(0,y),Offset(w,y),Paint()..color=FinTheme.border..strokeWidth=.7);final tp=TextPainter(text:TextSpan(text:'${(high-span*i/3).toStringAsFixed(1)}%',style:const TextStyle(color:FinTheme.steel,fontSize:9)),textDirection:TextDirection.ltr)..layout();tp.paint(canvas,Offset(w+4,y.clamp(0.0,h-9).toDouble()));tp.dispose();}
    for(final (j,series) in values.indexed){final path=Path();for(var i=0;i<series.length;i++){final x=w*i/math.max(1,series.length-1),y=(high-series[i])/span*h;if(i==0){path.moveTo(x,y);}else{path.lineTo(x,y);}}canvas.drawPath(path,Paint()..color=_seriesColors[j%_seriesColors.length]..strokeWidth=1.35..style=PaintingStyle.stroke);}
  }
  @override bool shouldRepaint(covariant _RelativePainter oldDelegate)=>oldDelegate.rows!=rows;
}
