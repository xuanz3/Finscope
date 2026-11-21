import 'package:flutter/material.dart';

/// Shared motion tokens; all transitions respect the OS accessibility setting.
abstract final class FinMotion {
  static const press = Duration(milliseconds: 100);
  static const hover = Duration(milliseconds: 150);
  static const navigation = Duration(milliseconds: 260);
  static const value = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;
  static const transition = Cubic(.2, .8, .2, 1);
  static Duration duration(BuildContext context, Duration desired) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : desired;
}
