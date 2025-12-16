import 'package:flutter/material.dart';

/// Sistema de design padronizado do Odyssey
/// Define constantes para bordas, espaçamentos, arredondamentos e sombras

class OdysseySpacing {
  OdysseySpacing._();

  // Espaçamentos base
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Margens de página
  static const double pageHorizontal = 20.0;
  static const double pageVertical = 16.0;
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: pageHorizontal, vertical: pageVertical);

  // Espaçamento entre cards
  static const double cardGap = 12.0;

  // Espaçamento interno de cards
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20.0);
}

class OdysseyRadius {
  OdysseyRadius._();

  // Arredondamentos
  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 18.0;
  static const double xl = 22.0;
  static const double xxl = 28.0;
  static const double full = 100.0;

  // BorderRadius prontos
  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlAll = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius fullAll = BorderRadius.all(Radius.circular(full));

  // Para cards principais
  static const BorderRadius card = BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius cardLarge = BorderRadius.all(Radius.circular(24.0));

  // Para botões
  static const BorderRadius button = BorderRadius.all(Radius.circular(14.0));
  static const BorderRadius buttonLarge = BorderRadius.all(Radius.circular(18.0));

  // Para inputs
  static const BorderRadius input = BorderRadius.all(Radius.circular(12.0));

  // Para chips e tags
  static const BorderRadius chip = BorderRadius.all(Radius.circular(10.0));

  // Para avatars e ícones
  static const BorderRadius icon = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius iconLarge = BorderRadius.all(Radius.circular(16.0));
}

class OdysseyShadows {
  OdysseyShadows._();

  // Sombras sutis
  static List<BoxShadow> subtle(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Sombras médias
  static List<BoxShadow> medium(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Sombras elevadas
  static List<BoxShadow> elevated(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Sombra de glow para elementos interativos
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.4),
      blurRadius: 16,
      spreadRadius: 2,
    ),
  ];

  // Sombra para cards flutuantes
  static List<BoxShadow> card(Color shadowColor) => [
    BoxShadow(
      color: shadowColor.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Sombra para botões pressionados
  static List<BoxShadow> pressed(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

class OdysseyDurations {
  OdysseyDurations._();

  // Durações de animação
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);
  static const Duration slowest = Duration(milliseconds: 1200);
}

class OdysseyCurves {
  OdysseyCurves._();

  // Curvas de animação
  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeInOutCubic;
}

/// Extensão para facilitar uso de bordas com tema
extension BorderExtension on BuildContext {
  BoxDecoration cardDecoration({Color? color, List<BoxShadow>? shadows}) {
    final colors = Theme.of(this).colorScheme;
    return BoxDecoration(
      color: color ?? colors.surface,
      borderRadius: OdysseyRadius.card,
      border: Border.all(
        color: colors.outline.withValues(alpha: 0.08),
        width: 1,
      ),
      boxShadow: shadows ?? OdysseyShadows.card(colors.shadow),
    );
  }

  BoxDecoration elevatedCardDecoration({Color? color, Color? glowColor}) {
    final colors = Theme.of(this).colorScheme;
    return BoxDecoration(
      color: color ?? colors.surface,
      borderRadius: OdysseyRadius.cardLarge,
      border: Border.all(
        color: colors.outline.withValues(alpha: 0.1),
        width: 1,
      ),
      boxShadow: OdysseyShadows.elevated(glowColor ?? colors.primary),
    );
  }

  BoxDecoration buttonDecoration({Color? color, bool isPressed = false}) {
    final colors = Theme.of(this).colorScheme;
    return BoxDecoration(
      color: color ?? colors.primary,
      borderRadius: OdysseyRadius.button,
      boxShadow: isPressed
          ? OdysseyShadows.pressed(color ?? colors.primary)
          : OdysseyShadows.medium(color ?? colors.primary),
    );
  }

  BoxDecoration chipDecoration({Color? backgroundColor, Color? borderColor}) {
    final colors = Theme.of(this).colorScheme;
    return BoxDecoration(
      color: backgroundColor ?? colors.surfaceContainerHighest,
      borderRadius: OdysseyRadius.chip,
      border: borderColor != null
          ? Border.all(color: borderColor, width: 1)
          : null,
    );
  }
}

/// Widget helper para aplicar animações consistentes
class OdysseyAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration? duration;
  final Curve? curve;
  final BoxDecoration? decoration;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  const OdysseyAnimatedContainer({
    super.key,
    required this.child,
    this.duration,
    this.curve,
    this.decoration,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration ?? OdysseyDurations.normal,
      curve: curve ?? OdysseyCurves.standard,
      decoration: decoration,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
}
