import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../design_system/theme.dart';

class MarketChart extends StatelessWidget {
  const MarketChart({super.key, required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) => Semantics(label: 'Historical value chart',
    child: SizedBox(height: 240, width: double.infinity,
      child: RepaintBoundary(child: CustomPaint(painter: _ChartPainter(values)))));
}
class _ChartPainter extends CustomPainter {
  final List<double> values;
  _ChartPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final width = math.max(1.0, size.width - 54);
    final height = math.max(1.0, size.height - 26);
    final min = values.reduce(math.min), max = values.reduce(math.max);
    final span = math.max(max - min, .000001);
    final grid = Paint()..color = FinTheme.border..strokeWidth = .7;
    for (var i = 0; i <= 4; i++) {
      final y = 8 + i * (height - 16) / 4;
      canvas.drawLine(Offset(0,y), Offset(width,y), grid);
      final label = TextPainter(text: TextSpan(text: (max - span * i / 4).toStringAsFixed(3),
        style: const TextStyle(fontSize: 10, color: FinTheme.steel)), textDirection: TextDirection.ltr)..layout();
      label.paint(canvas, Offset(width + 5, y - 6));
    }
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * width / math.max(values.length - 1, 1);
      final y = 8 + (max - values[i]) / span * (height - 16);
      if (i == 0) { path.moveTo(x,y); } else { path.lineTo(x,y); }
    }
    final area = Path.from(path)..lineTo(values.length == 1 ? 0 : width,height)..lineTo(0,height)..close();
    canvas.drawPath(area, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0x4492BCA9), Color(0x0092BCA9)]).createShader(Rect.fromLTWH(0,0,width,height)));
    canvas.drawPath(path, Paint()..color = FinTheme.gain..strokeWidth = 1.7..style = PaintingStyle.stroke..isAntiAlias = true);
  }
  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => oldDelegate.values != values;
}
