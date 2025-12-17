import 'package:flutter/material.dart';

/// Constant sizes to be used in the app (paddings, gaps, rounded corners etc.)
/// Baseado em múltiplos de 4 para consistência visual
class Sizes {
  // Spacing base (múltiplos de 4)
  static const p2 = 2.0;
  static const p4 = 4.0;
  static const p6 = 6.0;
  static const p8 = 8.0;
  static const p10 = 10.0;
  static const p12 = 12.0;
  static const p14 = 14.0;
  static const p16 = 16.0;
  static const p20 = 20.0;
  static const p24 = 24.0;
  static const p28 = 28.0;
  static const p32 = 32.0;
  static const p40 = 40.0;
  static const p48 = 48.0;
  static const p56 = 56.0;
  static const p64 = 64.0;
  static const p80 = 80.0;
  static const p96 = 96.0;
  static const p128 = 128.0;
}

/// Constant gap widths
const gapW2 = SizedBox(width: Sizes.p2);
const gapW4 = SizedBox(width: Sizes.p4);
const gapW6 = SizedBox(width: Sizes.p6);
const gapW8 = SizedBox(width: Sizes.p8);
const gapW10 = SizedBox(width: Sizes.p10);
const gapW12 = SizedBox(width: Sizes.p12);
const gapW16 = SizedBox(width: Sizes.p16);
const gapW20 = SizedBox(width: Sizes.p20);
const gapW24 = SizedBox(width: Sizes.p24);
const gapW32 = SizedBox(width: Sizes.p32);
const gapW48 = SizedBox(width: Sizes.p48);
const gapW64 = SizedBox(width: Sizes.p64);

/// Constant gap heights
const gapH2 = SizedBox(height: Sizes.p2);
const gapH4 = SizedBox(height: Sizes.p4);
const gapH6 = SizedBox(height: Sizes.p6);
const gapH8 = SizedBox(height: Sizes.p8);
const gapH10 = SizedBox(height: Sizes.p10);
const gapH12 = SizedBox(height: Sizes.p12);
const gapH16 = SizedBox(height: Sizes.p16);
const gapH20 = SizedBox(height: Sizes.p20);
const gapH24 = SizedBox(height: Sizes.p24);
const gapH32 = SizedBox(height: Sizes.p32);
const gapH48 = SizedBox(height: Sizes.p48);
const gapH64 = SizedBox(height: Sizes.p64);

/// Raios de borda padronizados
class AppRadius {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const full = 999.0;
  
  // BorderRadius pré-definidos
  static final xsBorder = BorderRadius.circular(xs);
  static final smBorder = BorderRadius.circular(sm);
  static final mdBorder = BorderRadius.circular(md);
  static final lgBorder = BorderRadius.circular(lg);
  static final xlBorder = BorderRadius.circular(xl);
  static final xxlBorder = BorderRadius.circular(xxl);
  static final fullBorder = BorderRadius.circular(full);
}

/// Tamanhos de fonte padronizados
class AppFontSize {
  static const xs = 10.0;
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 18.0;
  static const xxl = 20.0;
  static const display1 = 24.0;
  static const display2 = 28.0;
  static const display3 = 32.0;
  static const display4 = 40.0;
}

/// Pesos de fonte padronizados
class AppFontWeight {
  static const light = FontWeight.w300;
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semiBold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extraBold = FontWeight.w800;
}

/// Tamanhos de ícones padronizados
class AppIconSize {
  static const xs = 14.0;
  static const sm = 18.0;
  static const md = 22.0;
  static const lg = 24.0;
  static const xl = 28.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Durações de animação padronizadas
class AppDuration {
  static const fastest = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 400);
  static const slower = Duration(milliseconds: 500);
  static const slowest = Duration(milliseconds: 600);
  static const page = Duration(milliseconds: 350);
}

/// Curvas de animação padronizadas
class AppCurves {
  static const easeIn = Curves.easeIn;
  static const easeOut = Curves.easeOut;
  static const easeInOut = Curves.easeInOut;
  static const bounce = Curves.elasticOut;
  static const spring = Curves.easeOutBack;
  static const smooth = Curves.easeOutCubic;
}

/// Espaçamentos de padding padronizados
class AppPadding {
  static const screenH = EdgeInsets.symmetric(horizontal: Sizes.p20);
  static const screenV = EdgeInsets.symmetric(vertical: Sizes.p16);
  static const screen = EdgeInsets.symmetric(horizontal: Sizes.p20, vertical: Sizes.p16);
  
  static const cardAll = EdgeInsets.all(Sizes.p16);
  static const cardCompact = EdgeInsets.all(Sizes.p12);
  static const cardLarge = EdgeInsets.all(Sizes.p20);
  
  static const buttonH = EdgeInsets.symmetric(horizontal: Sizes.p20);
  static const buttonV = EdgeInsets.symmetric(vertical: Sizes.p12);
  static const button = EdgeInsets.symmetric(horizontal: Sizes.p20, vertical: Sizes.p12);
  
  static const chipH = EdgeInsets.symmetric(horizontal: Sizes.p12);
  static const chipV = EdgeInsets.symmetric(vertical: Sizes.p6);
  static const chip = EdgeInsets.symmetric(horizontal: Sizes.p12, vertical: Sizes.p6);
}

/// Sombras padronizadas
class AppShadows {
  static List<BoxShadow> none = [];
  
  static List<BoxShadow> sm(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> md(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> lg(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
}

/// Extensão para EdgeInsets
extension EdgeInsetsExtension on EdgeInsets {
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: left);
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: top);
}
