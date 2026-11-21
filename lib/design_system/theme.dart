import 'package:flutter/material.dart';

// FinScope / Studio theme — designed for dense financial workspaces.
abstract final class FinTheme {
  static const slate = Color(0xFF232F38);
  static const burgundy = Color(0xFF872A35);
  static const steel = Color(0xFF929FA8);
  static const ivory = Color(0xFFD9D2BF);
  static const ink = Color(0xFFE6EAEE);
  static const surface = Color(0xFF141A20);
  static const rail = Color(0xFF0D1216);
  static const border = Color(0xFF252D35);
  static const gain = Color(0xFF3CC398);
  static const loss = Color(0xFFF07987);
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 420);
  static final dark = ThemeData(
    useMaterial3: true, brightness: Brightness.dark,
    scaffoldBackgroundColor: rail,
    colorScheme: const ColorScheme.dark(primary: ink, secondary: burgundy,
      surface: surface, onSurface: ink, onPrimary: rail, outline: border, outlineVariant: border),
    dividerColor: border,
    dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
    visualDensity: VisualDensity.compact,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(color: steel, fontSize: 11),
      titleLarge: TextStyle(color: ink, fontSize: 24, fontWeight: FontWeight.w500),
      labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    iconTheme: const IconThemeData(color: steel, size: 19),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: rail,
      hintStyle: const TextStyle(color: steel, fontWeight: FontWeight.w400),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: border))),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent, selectedColor: slate,
      checkmarkColor: ivory, side: const BorderSide(color: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: ink),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1)),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorColor: slate, selectedIconTheme: IconThemeData(color: ivory, size: 20),
      unselectedIconTheme: IconThemeData(color: steel, size: 20),
      selectedLabelTextStyle: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelTextStyle: TextStyle(color: steel, fontSize: 12, fontWeight: FontWeight.w400)),
    navigationBarTheme: const NavigationBarThemeData(backgroundColor: rail, indicatorColor: slate),
  );
}
