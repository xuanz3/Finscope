import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import '../design_system/theme.dart';
import '../design_system/motion.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 18});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Material(color: FinTheme.surface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5), side: const BorderSide(color: FinTheme.border)),
    clipBehavior: Clip.antiAlias, child: Padding(padding: EdgeInsets.all(padding), child: child));
}

class MotionButton extends StatefulWidget {
  const MotionButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  State<MotionButton> createState() => _MotionButtonState();
}
class _MotionButtonState extends State<MotionButton> {
  bool pressed = false;
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: widget.onPressed == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() { hovered = false; pressed = false; }),
      child: Listener(onPointerDown: (_) => setState(() => pressed = true),
      onPointerUp: (_) => setState(() => pressed = false),
      onPointerCancel: (_) => setState(() => pressed = false),
      child: AnimatedScale(scale: widget.onPressed == null || reduced ? 1 : pressed ? .965 : hovered ? 1.015 : 1,
        duration: FinMotion.duration(context, FinMotion.press), curve: FinMotion.curve,
        child: FilledButton(onPressed: widget.onPressed,
          style: FilledButton.styleFrom(backgroundColor: FinTheme.burgundy, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [if (widget.icon != null) ...[
            Icon(widget.icon, size: 17), const SizedBox(width: 8)], Flexible(child: Text(widget.label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis))])))));
  }
}

class AnimatedAmount extends StatelessWidget {
  const AnimatedAmount({super.key, required this.value, this.prefix = 'A\$'});
  final double value;
  final String prefix;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value), duration: FinMotion.duration(context, FinMotion.value),
    curve: FinMotion.curve,
    builder: (context, amount, _) => Text('$prefix${formatAmount(amount)}',
      style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w600,
        fontFeatures: [FontFeature.tabularFigures()])));
}
String formatAmount(double value) {
  final parts = value.abs().toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${value < 0 ? '-' : ''}$whole.${parts[1]}';
}
