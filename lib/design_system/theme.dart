import 'package:flutter/material.dart';

/// Finscope terminal tokens. Brand colors are accents, not body-text colors.
abstract final class FinTheme {
  static const slate = Color(0xFF232F38);
  static const burgundy = Color(0xFF872A35);
  static const steel = Color(0xFF929FA8);
  static const ivory = Color(0xFFD9D2BF);
  static const ink = Color(0xFFE7E9EF);
  static const surface = Color(0xFF151821);
  static const rail = Color(0xFF0B0D16);
  static const border = Color(0xFF292D39);
  static const elevated = Color(0xFF1C202B);
  static const header = Color(0xFF10131D);
  static const gain = Color(0xFF54CA98);
  static const loss = Color(0xFFF17380);
  static const fast = Duration(milliseconds: 120);
  static const medium = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 420);
  static final dark = ThemeData(
    useMaterial3:true, brightness:Brightness.dark, scaffoldBackgroundColor:rail,
    colorScheme:const ColorScheme.dark(primary:ink,secondary:burgundy,surface:surface,onSurface:ink,onPrimary:rail,outline:border,outlineVariant:border),
    dividerColor:border, dividerTheme:const DividerThemeData(color:border,thickness:1,space:1),
    visualDensity:VisualDensity.compact,
    textTheme:const TextTheme(
      bodyLarge:TextStyle(color:ink,fontSize:13,fontWeight:FontWeight.w400),
      bodyMedium:TextStyle(color:ink,fontSize:12,fontWeight:FontWeight.w400),
      bodySmall:TextStyle(color:steel,fontSize:11),
      titleLarge:TextStyle(color:ink,fontSize:22,fontWeight:FontWeight.w500,letterSpacing:-.4),
      titleMedium:TextStyle(color:ink,fontSize:14,fontWeight:FontWeight.w500),
      labelLarge:TextStyle(fontSize:12,fontWeight:FontWeight.w500),
      labelMedium:TextStyle(fontSize:11,fontWeight:FontWeight.w400)),
    tooltipTheme: const TooltipThemeData(decoration: BoxDecoration(color: elevated, borderRadius: BorderRadius.all(Radius.circular(5))), textStyle: TextStyle(color: ink, fontSize: 11), waitDuration: Duration(milliseconds: 750)),
    iconTheme:const IconThemeData(color:steel,size:17),
    iconButtonTheme:IconButtonThemeData(style:IconButton.styleFrom(minimumSize:const Size(27,27),padding:const EdgeInsets.all(4),tapTargetSize:MaterialTapTargetSize.shrinkWrap)),
    inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:header,isDense:true,
      hintStyle:const TextStyle(color:steel,fontSize:12),contentPadding:const EdgeInsets.symmetric(horizontal:10,vertical:10),
      border:OutlineInputBorder(borderRadius:BorderRadius.circular(3),borderSide:const BorderSide(color:border)),
      enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(3),borderSide:const BorderSide(color:border)),
      focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(3),borderSide:const BorderSide(color:steel))),
    chipTheme:ChipThemeData(backgroundColor:header,selectedColor:slate,side:BorderSide.none,
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3)),labelStyle:const TextStyle(fontSize:11,color:ink),padding:const EdgeInsets.symmetric(horizontal:3),labelPadding:const EdgeInsets.symmetric(horizontal:5)),
    filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:slate,foregroundColor:ink,padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3)))),
    outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(foregroundColor:ink,side:const BorderSide(color:border),padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3)))),
    textButtonTheme:TextButtonThemeData(style:TextButton.styleFrom(foregroundColor:steel,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3)))),
    dataTableTheme:DataTableThemeData(headingRowColor:const WidgetStatePropertyAll(header),headingTextStyle:const TextStyle(color:steel,fontSize:10,fontWeight:FontWeight.w500),dataTextStyle:const TextStyle(color:ink,fontSize:12),dividerThickness:0.5,dataRowMinHeight:30,dataRowMaxHeight:34),
    navigationBarTheme:const NavigationBarThemeData(backgroundColor:header,indicatorColor:slate,height:65),
    pageTransitionsTheme:const PageTransitionsTheme(builders:{TargetPlatform.android:FadeUpwardsPageTransitionsBuilder(),TargetPlatform.iOS:FadeUpwardsPageTransitionsBuilder(),TargetPlatform.macOS:FadeUpwardsPageTransitionsBuilder(),TargetPlatform.windows:FadeUpwardsPageTransitionsBuilder()}),
  );
}
