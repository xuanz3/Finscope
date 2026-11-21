import 'dart:ui' show FontFeature;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/trading.dart';
import '../design_system/theme.dart';
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
  @override Widget build(BuildContext context) => Material(color:FinTheme.surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(5),side:const BorderSide(color:FinTheme.border)),clipBehavior:Clip.antiAlias, child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),child:Row(children:[Expanded(child:Text(title,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w500))),if(action!=null)action!])),
    const Divider(height:1), Padding(padding:const EdgeInsets.all(12),child:child),
  ]));
}

class TerminalWorkspace extends StatefulWidget {
  const TerminalWorkspace({super.key,required this.model,required this.symbol,required this.onSymbol,required this.onWatch,required this.onReplay,required this.onNewReplay,required this.onPortfolio,required this.onImport,this.overview=false});
  final ProductState model; final String symbol; final ValueChanged<String> onSymbol,onWatch,onNewReplay; final VoidCallback onReplay,onPortfolio,onImport; final bool overview;
  @override State<TerminalWorkspace> createState()=>_TerminalWorkspaceState();
}
class _TerminalWorkspaceState extends State<TerminalWorkspace> {
  String filter='All',query='',sort='Symbol'; bool descending=false,watchOnly=false,heatmap=false; int period=60; String detail='Technical';
  List<MarketMetrics> get all=>widget.model.series.values.map(MarketMetrics.new).toList()..sort((a,b)=>a.sample==b.sample?0:a.sample?1:-1);
  MarketMetrics get current=>MarketMetrics(widget.model.series[widget.symbol]??widget.model.series.values.first);
  List<MarketMetrics> get filtered {
    final rows=all.where((m)=>(filter=='All'||m.category==filter)&&(!watchOnly||widget.model.watchlist.contains(m.series.symbol))&&m.series.symbol.toLowerCase().contains(query.toLowerCase())).toList();
    rows.sort((a,b){final c=switch(sort){'Price'=>a.close.compareTo(b.close),'1D'=>a.change(1).compareTo(b.change(1)),'5D'=>a.change(5).compareTo(b.change(5)),'20D'=>a.change(20).compareTo(b.change(20)),_=>a.series.symbol.compareTo(b.series.symbol)};return descending?-c:c;});return rows;
  }
  Widget label(String s)=>Text(s,style:const TextStyle(fontSize:10,color:FinTheme.steel));
  Widget number(String s,{Color? color,double size=12})=>Text(s,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:size,color:color??FinTheme.ink,fontWeight:size>=18?FontWeight.w500:FontWeight.w400,fontFeatures:const [FontFeature.tabularFigures()]));
  Widget chip(String name,bool active,VoidCallback action)=>Padding(padding:const EdgeInsets.only(right:3),child:InkWell(borderRadius:BorderRadius.circular(4),onTap:action,child:AnimatedContainer(duration:const Duration(milliseconds:130),padding:const EdgeInsets.symmetric(horizontal:9,vertical:7),decoration:BoxDecoration(color:active?FinTheme.slate:Colors.transparent,borderRadius:BorderRadius.circular(4)),child:Text(name,style:TextStyle(fontSize:11,color:active?FinTheme.ink:FinTheme.steel)))));
  Widget spread(String a,String b,{Color? color})=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:label(a)),number(b,color:color)]));
  Widget mark(MarketMetrics m){
    final symbol=m.series.symbol;
    final glyph=switch(symbol){'AUD/USD'=>'AU','EUR/USD'=>'EU','GBP/USD'=>'GB','USD/JPY'=>'JP','BTC/USD'=>'₿','S&P 500'=>'SP',_=>symbol.substring(0,math.min(2,symbol.length))};
    final color=switch(symbol){'BTC/USD'=>const Color(0xFFD49643),'EUR/USD'=>const Color(0xFF526FA9),'USD/JPY'=>const Color(0xFFB15A68),'AUD/USD'=>const Color(0xFF567F92),'GBP/USD'=>const Color(0xFF817CA5),_=>FinTheme.steel};
    return Container(width:28,height:28,alignment:Alignment.center,decoration:BoxDecoration(color:color.withAlpha(35),shape:BoxShape.circle,border:Border.all(color:color.withAlpha(90))),child:Text(glyph,style:TextStyle(color:color,fontSize:10,fontWeight:FontWeight.w600)));
  }
  Widget ticker(MarketMetrics m)=>InkWell(
    onTap:()=>widget.onSymbol(m.series.symbol),
    child:Padding(padding:const EdgeInsets.symmetric(horizontal:9,vertical:8),
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
    final metrics=[('Portfolio equity','A\$${formatAmount(p.equity)}','Manual valuation',null),('Simulation equity','A\$${formatAmount(s.equity)}',terminalPct(s.totalReturn*100),terminalColor(s.totalReturn))];
    return LayoutBuilder(builder:(_,c){
      final n=c.maxWidth>=720?4:2;
      final width=(c.maxWidth-(n-1)*8)/n;
      return Wrap(spacing:8,runSpacing:8,children:[
        for(final v in metrics)SizedBox(width:width,child:Panel(padding:12,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[label(v.$1),const SizedBox(height:8),number(v.$2,size:21),const SizedBox(height:6),number(v.$3,color:v.$4??FinTheme.steel,size:11)]))),
        for(final m in all.take(2))SizedBox(width:width,child:Panel(padding:12,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:label(m.series.symbol)),label(m.sample?'Sample':'Daily')]),const SizedBox(height:8),number(terminalPrice(m.close),size:21),const SizedBox(height:5),Row(children:[Expanded(child:number(terminalPct(m.change(1)),color:terminalColor(m.change(1)),size:11)),if(width>165)SizedBox(width:62,height:19,child:CustomPaint(painter:_Spark(m.spark,terminalColor(m.change(1)))))])]))),
      ]);
    });
  }
  Widget directory()=>DeskPanel(title:'Markets',action:IconButton(tooltip:'Import market data',visualDensity:VisualDensity.compact,icon:const Icon(Icons.add,size:16),onPressed:widget.onImport),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[TextField(onChanged:(s)=>setState(()=>query=s),style:const TextStyle(fontSize:12),decoration:const InputDecoration(isDense:true,prefixIcon:Icon(Icons.search,size:16),hintText:'Find a symbol',contentPadding:EdgeInsets.all(8))),const SizedBox(height:8),Wrap(children:[for(final v in ['All','Forex','Indices','Crypto','Imported'])chip(v,filter==v,()=>setState(()=>filter=v))]),const Divider(height:12),for(final m in filtered.take(18))Material(color:m.series.symbol==widget.symbol?FinTheme.slate:Colors.transparent,child:ticker(m)),if(filtered.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('No matching datasets.'))]));
  Widget graph(MarketMetrics m,double height){final bars=m.bars.skip(math.max(0,m.bars.length-period)).map((b)=>b.candle).toList();return DeskPanel(title:'Price chart',action:IconButton(tooltip:'Toggle watchlist',visualDensity:VisualDensity.compact,icon:Icon(widget.model.watchlist.contains(m.series.symbol)?Icons.star:Icons.star_border,size:18),onPressed:()=>widget.onWatch(m.series.symbol)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[mark(m),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[number(m.series.symbol,size:22),label('${m.category}  /  ${m.sample?'Synthetic sample':m.series.source}')])),Column(crossAxisAlignment:CrossAxisAlignment.end,children:[number(terminalPrice(m.close),size:27),number(terminalPct(m.change(1)),color:terminalColor(m.change(1)))])]),const SizedBox(height:8),Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[for(final n in [20,60,90,100000])chip(n==100000?'All':'${n}D',period==n,()=>setState(()=>period=n)),const SizedBox(width:6),label(m.series.source.startsWith('ECB')?'Reference observations':'Daily bars')]),const SizedBox(height:4),TradingChart(key:ValueKey('${m.series.symbol}-$period'),candles:bars,height:height,decimals:m.close<10?4:2),const Divider(height:14),Wrap(spacing:8,runSpacing:5,children:[MotionButton(label:'New replay',icon:Icons.history,onPressed:()=>widget.onNewReplay(m.series.symbol)),OutlinedButton(onPressed:widget.onImport,child:const Text('Import data'))]) ]));}
  Widget details(MarketMetrics m)=>DeskPanel(title:'Instrument details',child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(children:[for(final v in ['Technical','Returns','Data'])chip(v,detail==v,()=>setState(()=>detail=v))]),const Divider(height:14),if(detail=='Technical')...[spread('Open',terminalPrice(m.bars.last.candle.open)),spread('High',terminalPrice(m.bars.last.candle.high)),spread('Low',terminalPrice(m.bars.last.candle.low)),spread('SMA 20',terminalPrice(m.sma20)),spread('RSI 14 (simple)',m.rsi?.toStringAsFixed(1)??'N/A'),const SizedBox(height:5),label('20-bar price range'),const SizedBox(height:6),LinearProgressIndicator(value:((m.close-m.rangeLow)/math.max(m.rangeHigh-m.rangeLow,1e-9)).clamp(0.0,1.0).toDouble(),color:FinTheme.ivory,backgroundColor:FinTheme.rail),spread(terminalPrice(m.rangeLow),terminalPrice(m.rangeHigh)),spread('Price vs average',m.close>=m.sma20?'Above SMA':'Below SMA',color:terminalColor(m.close-m.sma20))]else if(detail=='Returns')...[for(final d in [1,5,20,60])spread('$d bars',terminalPct(m.change(d)),color:terminalColor(m.change(d)))]else...[spread('Coverage','${m.bars.length} bars'),spread('First date',terminalDate(m.bars.first.candle.date)),spread('Last date',terminalDate(m.bars.last.candle.date)),label(m.series.source)],const Divider(height:15),label('Watchlist'),const SizedBox(height:5),for(final v in all.where((v)=>widget.model.watchlist.contains(v.series.symbol)))ticker(v)]));
  Widget screener()=>DeskPanel(title:'Market screener',action:TextButton.icon(onPressed:()=>setState(()=>heatmap=!heatmap),icon:Icon(heatmap?Icons.table_rows:Icons.grid_view,size:15),label:Text(heatmap?'Table':'Heatmap',style:const TextStyle(fontSize:11))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[for(final v in ['All','Forex','Indices','Crypto','Imported'])chip(v,filter==v,()=>setState(()=>filter=v)),chip('Watchlist',watchOnly,()=>setState(()=>watchOnly=!watchOnly))]),const SizedBox(height:6),if(heatmap)LayoutBuilder(builder:(_,c){final n=c.maxWidth>=600?4:2;return Wrap(spacing:4,runSpacing:4,children:[for(final m in filtered)SizedBox(width:(c.maxWidth-(n-1)*4)/n,height:65,child:Material(color:terminalColor(m.change(1)).withAlpha((45+m.change(1).abs()*15).clamp(45,150).toInt()),borderRadius:BorderRadius.circular(3),child:InkWell(onTap:()=>widget.onSymbol(m.series.symbol),child:Center(child:Column(mainAxisSize:MainAxisSize.min,children:[number(m.series.symbol),number(terminalPct(m.change(1)))]))))) ]);})else LayoutBuilder(builder:(_,bounds)=>SingleChildScrollView(scrollDirection:Axis.horizontal,child:ConstrainedBox(constraints:BoxConstraints(minWidth:bounds.maxWidth),child:DataTable(horizontalMargin:5,columnSpacing:16,headingRowHeight:34,dataRowMinHeight:36,dataRowMaxHeight:40,sortColumnIndex:['Symbol','Price','1D','5D','20D'].indexOf(sort),sortAscending:!descending,columns:[for(final v in ['Symbol','Price','1D','5D','20D'])DataColumn(label:label(v),numeric:v!='Symbol',onSort:(_,asc)=>setState((){sort=v;descending=!asc;})),DataColumn(label:label('Trend')),DataColumn(label:label('Source'))],rows:[for(final m in filtered.take(100))DataRow(selected:m.series.symbol==widget.symbol,onSelectChanged:(_)=>widget.onSymbol(m.series.symbol),cells:[DataCell(number(m.series.symbol)),DataCell(number(terminalPrice(m.close))),for(final d in [1,5,20])DataCell(number(terminalPct(m.change(d)),color:terminalColor(m.change(d)))),DataCell(SizedBox(width:55,height:22,child:CustomPaint(painter:_Spark(m.spark,terminalColor(m.change(5)))))),DataCell(label(m.sample?'Sample':m.series.source.startsWith('ECB')?'ECB':'CSV'))])],showCheckboxColumn:false)))),if(filtered.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('No matching instruments.')),const SizedBox(height:5),label('Returns use available daily bars; sample data is not market history.') ]));
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
      for(final m in ranked.take(4))InkWell(onTap:()=>widget.onSymbol(m.series.symbol),child:Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:number(m.series.symbol)),number(terminalPct(m.change(5)),color:terminalColor(m.change(5)),size:11)]))),
      const SizedBox(height:6),label('Local datasets only')
    ]));
  }
  Widget marketTape()=>SizedBox(height:54,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:all.take(12).length,separatorBuilder:(_,__)=>const SizedBox(width:8),itemBuilder:(_,i){final m=all[i];return Material(color:FinTheme.surface,borderRadius:BorderRadius.circular(4),child:InkWell(onTap:()=>widget.onSymbol(m.series.symbol),borderRadius:BorderRadius.circular(4),child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),child:Row(children:[mark(m),const SizedBox(width:8),SizedBox(width:111,child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[number(m.series.symbol),label(m.sample?'Sample':terminalDate(m.bars.last.candle.date))])),const SizedBox(width:7),Column(crossAxisAlignment:CrossAxisAlignment.end,mainAxisAlignment:MainAxisAlignment.center,children:[number(terminalPrice(m.close)),number(terminalPct(m.change(1)),color:terminalColor(m.change(1)),size:11)]),const SizedBox(width:8),SizedBox(width:44,height:24,child:CustomPaint(painter:_Spark(m.spark,terminalColor(m.change(1))))) ]))));}));
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(_,c){final wide=c.maxWidth>=1050,medium=c.maxWidth>=710;final m=current;final center=Column(children:[graph(m,wide?350:medium?290:220),const SizedBox(height:8),screener()]);final side=Column(children:[details(m),const SizedBox(height:6),sessionCard()]);return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(widget.overview?'Market intelligence':'Market directory',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w500))),label('LOCAL DATA  /  DAILY')]),const SizedBox(height:10),marketTape(),const SizedBox(height:10),if(widget.overview)...[strip(),const SizedBox(height:10)],if(wide)Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:215,child:Column(children:[directory(),const SizedBox(height:8),marketPulse()])),const SizedBox(width:8),Expanded(child:center),const SizedBox(width:8),SizedBox(width:250,child:side)])else if(medium)Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:center),const SizedBox(width:6),SizedBox(width:215,child:Column(children:[directory(),const SizedBox(height:6),side]))])else ...[directory(),const SizedBox(height:6),center,const SizedBox(height:6),side]]);});
}
class _Spark extends CustomPainter {
  _Spark(this.values,this.color);final List<double> values;final Color color;
  @override void paint(Canvas canvas,Size size){if(values.length<2)return;final low=values.reduce(math.min),high=values.reduce(math.max),span=math.max(high-low,1e-9);final path=Path();for(var i=0;i<values.length;i++){final x=i*size.width/(values.length-1),y=2+(high-values[i])/span*(size.height-4);if(i==0){path.moveTo(x,y);}else{path.lineTo(x,y);}}canvas.drawPath(path,Paint()..color=color..strokeWidth=1.2..style=PaintingStyle.stroke);}
  @override bool shouldRepaint(covariant _Spark oldDelegate)=>oldDelegate.values!=values||oldDelegate.color!=color;
}
