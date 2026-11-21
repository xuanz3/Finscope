import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/chart_model.dart';
import '../core/research.dart';
import '../design_system/theme.dart';
import '../design_system/motion.dart';

/// A responsive chart, rendering only the current viewport. No future candles
/// are accepted by the replay chart; its caller supplies revealed history only.
class TradingChart extends StatefulWidget {
  const TradingChart({super.key, required this.candles, this.height = 350,
    this.decimals = 4});
  final List<Candle> candles;
  final double height;
  final int decimals;
  @override
  State<TradingChart> createState() => _TradingChartState();
}

class _TradingChartState extends State<TradingChart> {
  late ChartViewport viewport = ChartViewport(widget.candles.length);
  late List<double?> average = simpleMovingAverage(widget.candles, 20);
  ChartViewport? gestureStart;
  double anchor = .5, originX = 0;
  int? hoverIndex;
  late List<double?> exponential=ema(widget.candles,20);
  late List<double?> upper=bollinger(widget.candles,20,2);
  late List<double?> lower=bollinger(widget.candles,20,-2);
  bool line = false, sma = true, showEma=false, bands=false;
  int? firstAnchor,secondAnchor;
  bool drawing=false;
  @override
  void didUpdateWidget(covariant TradingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.candles != widget.candles) {
      viewport = viewport.resize(widget.candles.length);
      average = simpleMovingAverage(widget.candles, 20);
      exponential=ema(widget.candles,20);upper=bollinger(widget.candles,20,2);lower=bollinger(widget.candles,20,-2);
      if(firstAnchor!=null&&firstAnchor!>=widget.candles.length)firstAnchor=null;
      if(secondAnchor!=null&&secondAnchor!>=widget.candles.length)secondAnchor=null;
      hoverIndex = null;
    }
  }
  void reset() => setState(() {
    viewport = ChartViewport(widget.candles.length);
    hoverIndex = null;
  });
  void zoom(double factor) => setState(() {
    viewport = viewport.zoom(factor);
    hoverIndex = null;
  });
  @override
  Widget build(BuildContext context) {
    final candles = widget.candles;
    if (candles.isEmpty) return const SizedBox(height: 180,
      child: Center(child: Text('No chart data available')));
    final i = hoverIndex ?? viewport.end - 1;
    final selected = candles[i];
    String price(double value) => value.toStringAsFixed(widget.decimals);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        ChoiceChip(label: const Text('Candles'), selected: !line,
          onSelected: (_) => setState(() => line = false)),
        ChoiceChip(label: const Text('Line'), selected: line,
          onSelected: (_) => setState(() => line = true)),
        FilterChip(label: const Text('SMA 20'), selected: sma,
          onSelected: (value) => setState(() => sma = value)),
        FilterChip(label:const Text('EMA 20'),selected:showEma,onSelected:(v)=>setState(()=>showEma=v)),
        FilterChip(label:const Text('BB 20'),selected:bands,onSelected:(v)=>setState(()=>bands=v)),
        IconButton(tooltip:'Draw trend line: select two bars',onPressed:()=>setState((){drawing=!drawing;firstAnchor=null;secondAnchor=null;}),icon:Icon(Icons.trending_up,color:drawing?FinTheme.ink:FinTheme.steel)),
        IconButton(tooltip: 'Zoom in', onPressed: () => zoom(1.25), icon: const Icon(Icons.zoom_in)),
        IconButton(tooltip: 'Zoom out', onPressed: () => zoom(.8), icon: const Icon(Icons.zoom_out)),
        IconButton(tooltip: 'Reset chart', onPressed: reset, icon: const Icon(Icons.restart_alt)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 14, runSpacing: 5, children: [
        Text(_day(selected.date), style: const TextStyle(color: FinTheme.steel, fontSize: 11)),
        for (final entry in {'O': selected.open, 'H': selected.high, 'L': selected.low, 'C': selected.close}.entries)
          Text('${entry.key} ${price(entry.value)}', style: TextStyle(fontSize: 11,
            color: selected.rising ? FinTheme.gain : FinTheme.loss)),
      ]),
      const SizedBox(height: 8),
      LayoutBuilder(builder: (context, constraints) {
        final plotWidth = math.max(1.0, constraints.maxWidth - 67);
        int? at(double x) => viewport.indexAt(x / plotWidth);
        return SizedBox(height: widget.height, width: double.infinity,
          child: MouseRegion(onHover: (event) {
              final index = at(event.localPosition.dx);
              if (index != hoverIndex) setState(() => hoverIndex = index);
            },
            onExit: (_) => setState(() => hoverIndex = null),
            child: Listener(onPointerSignal: (event) {
              if (event is PointerScrollEvent && event.scrollDelta.dy != 0) {
                GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
                  final scroll = resolved as PointerScrollEvent;
                  setState(() {
                    viewport = viewport.zoom(scroll.scrollDelta.dy > 0 ? .85 : 1.18,
                      anchor: scroll.localPosition.dx / plotWidth);
                    hoverIndex = null;
                  });
                });
              }
            }, child: GestureDetector(behavior: HitTestBehavior.opaque,
              onTapDown: (details) => setState(() {hoverIndex=at(details.localPosition.dx);if(drawing&&hoverIndex!=null){if(firstAnchor==null){firstAnchor=hoverIndex;}else{secondAnchor=hoverIndex;drawing=false;}}}),
              onScaleStart: (details) {
                gestureStart = viewport;
                originX = details.localFocalPoint.dx;
                anchor = (originX / plotWidth).clamp(0.0, 1.0).toDouble();
              },
              onScaleUpdate: (details) {
                final initial = gestureStart;
                if (initial == null) return;
                setState(() {
                  final zoomed = initial.zoom(details.scale, anchor: anchor);
                  final delta = details.localFocalPoint.dx - originX;
                  viewport = zoomed.pan((-delta / plotWidth * zoomed.count).round());
                  hoverIndex = null;
                });
              },
              onScaleEnd: (_) => gestureStart = null,
              child: Semantics(label: 'Daily price chart. Use zoom controls or drag to explore.',
                child: DataArrival(key:ValueKey('$line-$sma-$showEma-$bands'),child: RepaintBoundary(child: CustomPaint(painter: _TradingPainter(
                  candles: candles, viewport: viewport, average: average,
                  line: line || candles.every((c)=>c.high==c.low), sma: sma, selected: hoverIndex, decimals: widget.decimals, overlays:[if(showEma)exponential,if(bands)upper,if(bands)lower],overlayColors:[if(showEma)const Color(0xFF78A6E8),if(bands)const Color(0xFF8F82C4),if(bands)const Color(0xFF8F82C4)],anchorA:firstAnchor,anchorB:secondAnchor)))))))));
      }),
      const SizedBox(height: 5),
      if(drawing)const Text('Select two bars to draw a trend line.',style:TextStyle(color:FinTheme.steel,fontSize:11)),
      Text('${viewport.start + 1}–${viewport.end} of ${candles.length} bars  ·  Drag to pan, scroll or pinch to zoom',
        style: const TextStyle(color: FinTheme.steel, fontSize: 10)),
    ]);
  }
}

String _day(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _TradingPainter extends CustomPainter {
  _TradingPainter({required this.candles, required this.viewport, required this.average,
    required this.line, required this.sma, required this.selected, required this.decimals,required this.overlays,required this.overlayColors,this.anchorA,this.anchorB});
  final List<List<double?>> overlays;final List<Color> overlayColors;final int? anchorA,anchorB;
  final List<Candle> candles;
  final ChartViewport viewport;
  final List<double?> average;
  final bool line, sma;
  final int? selected;
  final int decimals;
  void label(Canvas canvas, String value, Offset position, {Color color = FinTheme.steel}) {
    final text = TextPainter(text: TextSpan(text: value, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr)..layout();
    text.paint(canvas, position);
    text.dispose();
  }
  @override
  void paint(Canvas canvas, Size size) {
    if (viewport.count == 0 || size.width < 100 || size.height < 50) return;
    final w = size.width - 67, h = size.height - 24;
    var low = double.infinity, high = -double.infinity;
    for (var i = viewport.start; i < viewport.end; i++) {
      low = math.min(low, candles[i].low);
      high = math.max(high, candles[i].high);
      final a = average[i];
      if (sma && a != null) { low = math.min(low, a); high = math.max(high, a); }
      for(final overlay in overlays){final value=overlay[i];if(value!=null){low=math.min(low,value);high=math.max(high,value);}}
    }
    final pad = math.max((high - low) * .08, high * .0001);
    low -= pad; high += pad;
    final span = high - low, step = w / viewport.count;
    double x(int i) => (i - viewport.start + .5) * step;
    double y(double price) => (high - price) / span * h;
    final grid = Paint()..color = FinTheme.border.withAlpha(125)..strokeWidth = .65;
    for (var i = 0; i <= 5; i++) {
      final yy = i * h / 5;
      canvas.drawLine(Offset(0, yy), Offset(w, yy), grid);
      label(canvas, (high - span * i / 5).toStringAsFixed(decimals), Offset(w + 5, yy.clamp(0.0, h - 11).toDouble()));
    }
    final ticks = math.min(4, math.max(1, (w / 90).floor()));
    for (var i = 0; i < ticks; i++) {
      final index = viewport.start + (i * (viewport.count - 1) / math.max(1, ticks - 1)).round();
      final xx = x(index);
      canvas.drawLine(Offset(xx, 0), Offset(xx, h), grid);
      label(canvas, _day(candles[index].date).substring(5), Offset((xx - 14).clamp(0.0, w - 30).toDouble(), h + 6));
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    final series = Path(), indicator = Path();
    var indicatorStarted = false;
    final candlePaint = Paint()..isAntiAlias = true;
    for (var i = viewport.start; i < viewport.end; i++) {
      final c = candles[i], xx = x(i);
      if (line) {
        if (i == viewport.start) { series.moveTo(xx, y(c.close)); } else { series.lineTo(xx, y(c.close)); }
      } else {
        candlePaint.color = c.rising ? FinTheme.gain : FinTheme.loss;
        canvas.drawLine(Offset(xx, y(c.high)), Offset(xx, y(c.low)), candlePaint);
        final body = math.max(1.0, math.min(11.0, step * .52));
        canvas.drawRect(Rect.fromLTWH(xx - body / 2, math.min(y(c.open), y(c.close)),
          body, math.max(1.0, (y(c.open) - y(c.close)).abs())), candlePaint);
      }
      final a = average[i];
      if (sma && a != null) {
        if (!indicatorStarted) { indicator.moveTo(xx, y(a)); indicatorStarted = true; }
        else { indicator.lineTo(xx, y(a)); }
      }
    }
    if (line) {
      final lineColor=candles[viewport.end-1].close>=candles[viewport.start].close?FinTheme.gain:FinTheme.loss;
      final area=Path.from(series)..lineTo(x(viewport.end-1),h)..lineTo(x(viewport.start),h)..close();
      canvas.drawPath(area,Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[lineColor.withAlpha(44),lineColor.withAlpha(0)]).createShader(Rect.fromLTWH(0,0,w,h)));
      canvas.drawPath(series, Paint()..color = lineColor..strokeWidth = 1.5..style = PaintingStyle.stroke);
    }
    if (sma) canvas.drawPath(indicator, Paint()..color = FinTheme.ivory..strokeWidth = 1.2..style = PaintingStyle.stroke);
    for(final (j,overlay) in overlays.indexed){final path=Path();var started=false;for(var i=viewport.start;i<viewport.end;i++){final value=overlay[i];if(value==null)continue;if(!started){path.moveTo(x(i),y(value));started=true;}else{path.lineTo(x(i),y(value));}}canvas.drawPath(path,Paint()..color=overlayColors[j]..strokeWidth=1.2..style=PaintingStyle.stroke);}
    if(anchorA!=null&&anchorB!=null){canvas.drawLine(Offset(x(anchorA!),y(candles[anchorA!].close)),Offset(x(anchorB!),y(candles[anchorB!].close)),Paint()..color=const Color(0xFFE0AD64)..strokeWidth=1.7);}
    final index = selected;
    if (index != null && index >= viewport.start && index < viewport.end) {
      final xx = x(index), yy = y(candles[index].close);
      final cross = Paint()..color = FinTheme.steel..strokeWidth = .8;
      for(double d=0;d<h;d+=7){canvas.drawLine(Offset(xx,d),Offset(xx,math.min(h,d+3)),cross);}
      for(double d=0;d<w;d+=7){canvas.drawLine(Offset(d,yy),Offset(math.min(w,d+3),yy),cross);}
      canvas.drawCircle(Offset(xx, yy), 3, Paint()..color = FinTheme.ivory);
    }
    canvas.restore();
    if(index!=null && index>=viewport.start && index<viewport.end && w>=105){
      final tagX=(x(index)-40).clamp(0.0,w-80).toDouble();
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tagX,h+2,80,17),const Radius.circular(2)),Paint()..color=FinTheme.elevated);
      label(canvas,_day(candles[index].date),Offset(tagX+7,h+5),color:FinTheme.ink);
    }
    final last=candles[viewport.end-1];
    final yy=y(last.close).clamp(9.0,h-9).toDouble();
    final priceColor=last.rising?FinTheme.gain:FinTheme.loss;
    final p=Paint()..color=priceColor.withAlpha(115)..strokeWidth=.7;
    for(double xx=0;xx<w;xx+=7){canvas.drawLine(Offset(xx,yy),Offset(math.min(xx+3,w),yy),p);}
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w+2,yy-8,63,16),const Radius.circular(2)),Paint()..color=priceColor);
    label(canvas,last.close.toStringAsFixed(decimals),Offset(w+5,yy-6),color:FinTheme.rail);
  }
  @override
  bool shouldRepaint(covariant _TradingPainter old) => old.candles != candles ||
    old.viewport != viewport || old.average != average || old.line != line ||
    old.sma != sma || old.selected != selected || old.decimals != decimals || old.overlays != overlays || old.anchorA!=anchorA || old.anchorB!=anchorB;
}
