import 'package:flutter/material.dart';

abstract final class FinMotion {
  static const press = Duration(milliseconds: 95);
  static const hover = Duration(milliseconds: 140);
  static const navigation = Duration(milliseconds: 280);
  static const value = Duration(milliseconds: 380);
  static const curve = Curves.easeOutCubic;
  static const transition = Cubic(.2,.8,.2,1);
  static Duration duration(BuildContext context, Duration desired) => MediaQuery.disableAnimationsOf(context)?Duration.zero:desired;
}

/// Lightweight transitions without blur, backdrop filters or layout animation.
class DeskTransition extends StatelessWidget {
  const DeskTransition({super.key,required this.child});
  final Widget child;
  @override Widget build(BuildContext context)=>AnimatedSwitcher(
    duration:FinMotion.duration(context,FinMotion.navigation),
    reverseDuration:FinMotion.duration(context,const Duration(milliseconds:120)),
    switchInCurve:FinMotion.transition,switchOutCurve:Curves.easeInQuad,
    layoutBuilder:(current,previous)=>Stack(alignment:Alignment.topLeft,fit:StackFit.passthrough,children:[for(final old in previous)Positioned.fill(child:IgnorePointer(child:old)),if(current!=null)current]),
    transitionBuilder:(child,animation)=>FadeTransition(opacity:animation,child:SlideTransition(position:Tween(begin:const Offset(.008,.016),end:Offset.zero).animate(animation),child:child)),child:child);
}

/// A subtle entry animation for newly selected data, never changes the data.
class DataArrival extends StatelessWidget {
  const DataArrival({super.key,required this.child});
  final Widget child;
  @override Widget build(BuildContext context)=>TweenAnimationBuilder<double>(tween:Tween(begin:0,end:1),duration:FinMotion.duration(context,const Duration(milliseconds:270)),curve:FinMotion.transition,child:child,builder:(_,v,child)=>Opacity(opacity:v,child:Transform.translate(offset:Offset(0,5*(1-v)),child:child)));
}
