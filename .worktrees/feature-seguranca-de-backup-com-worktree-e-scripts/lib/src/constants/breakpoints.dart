import 'package:flutter/material.dart';

/// Layout breakpoints used in the app.
class Breakpoint {
  static const double mobile = 0;
  static const double mobileLarge = 400;
  static const double tablet = 600;
  static const double tabletLarge = 900;
  static const double desktop = 1200;
  static const double desktopLarge = 1800;
}

/// Tipos de dispositivo baseados em breakpoints
enum DeviceType {
  mobile,
  mobileLarge,
  tablet,
  tabletLarge,
  desktop,
  desktopLarge,
}

/// Orientação do dispositivo
enum DeviceOrientation {
  portrait,
  landscape,
}

/// Informações responsivas do dispositivo atual
class ResponsiveInfo {
  final double screenWidth;
  final double screenHeight;
  final DeviceType deviceType;
  final DeviceOrientation orientation;
  final double devicePixelRatio;
  final EdgeInsets padding;
  final EdgeInsets viewInsets;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final bool isLargeScreen;

  const ResponsiveInfo({
    required this.screenWidth,
    required this.screenHeight,
    required this.deviceType,
    required this.orientation,
    required this.devicePixelRatio,
    required this.padding,
    required this.viewInsets,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.isLargeScreen,
  });

  factory ResponsiveInfo.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;

    DeviceType deviceType;
    if (width >= Breakpoint.desktopLarge) {
      deviceType = DeviceType.desktopLarge;
    } else if (width >= Breakpoint.desktop) {
      deviceType = DeviceType.desktop;
    } else if (width >= Breakpoint.tabletLarge) {
      deviceType = DeviceType.tabletLarge;
    } else if (width >= Breakpoint.tablet) {
      deviceType = DeviceType.tablet;
    } else if (width >= Breakpoint.mobileLarge) {
      deviceType = DeviceType.mobileLarge;
    } else {
      deviceType = DeviceType.mobile;
    }

    final orientation = width > height
        ? DeviceOrientation.landscape
        : DeviceOrientation.portrait;

    return ResponsiveInfo(
      screenWidth: width,
      screenHeight: height,
      deviceType: deviceType,
      orientation: orientation,
      devicePixelRatio: mediaQuery.devicePixelRatio,
      padding: mediaQuery.padding,
      viewInsets: mediaQuery.viewInsets,
      isSmallScreen: width < Breakpoint.tablet,
      isMediumScreen: width >= Breakpoint.tablet && width < Breakpoint.desktop,
      isLargeScreen: width >= Breakpoint.desktop,
    );
  }

  /// Verifica se é mobile (incluindo mobile large)
  bool get isMobile => deviceType == DeviceType.mobile || deviceType == DeviceType.mobileLarge;

  /// Verifica se é tablet (incluindo tablet large)
  bool get isTablet => deviceType == DeviceType.tablet || deviceType == DeviceType.tabletLarge;

  /// Verifica se é desktop (incluindo desktop large)
  bool get isDesktop => deviceType == DeviceType.desktop || deviceType == DeviceType.desktopLarge;

  /// Verifica se está em landscape
  bool get isLandscape => orientation == DeviceOrientation.landscape;

  /// Verifica se está em portrait
  bool get isPortrait => orientation == DeviceOrientation.portrait;

  /// Retorna o número de colunas recomendado para grid
  int get gridColumns {
    switch (deviceType) {
      case DeviceType.mobile:
        return 2;
      case DeviceType.mobileLarge:
        return 2;
      case DeviceType.tablet:
        return 3;
      case DeviceType.tabletLarge:
        return 4;
      case DeviceType.desktop:
        return 4;
      case DeviceType.desktopLarge:
        return 6;
    }
  }

  /// Retorna o padding horizontal recomendado
  double get horizontalPadding {
    switch (deviceType) {
      case DeviceType.mobile:
        return 16;
      case DeviceType.mobileLarge:
        return 20;
      case DeviceType.tablet:
        return 24;
      case DeviceType.tabletLarge:
        return 32;
      case DeviceType.desktop:
        return 48;
      case DeviceType.desktopLarge:
        return 64;
    }
  }

  /// Retorna a largura máxima de conteúdo recomendada
  double get maxContentWidth {
    switch (deviceType) {
      case DeviceType.mobile:
      case DeviceType.mobileLarge:
        return screenWidth;
      case DeviceType.tablet:
        return 600;
      case DeviceType.tabletLarge:
        return 800;
      case DeviceType.desktop:
        return 1000;
      case DeviceType.desktopLarge:
        return 1200;
    }
  }
}

/// Widget que fornece informações responsivas para seus filhos
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveInfo info) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final info = ResponsiveInfo.of(context);
        return builder(context, info);
      },
    );
  }
}

/// Widget que mostra diferentes layouts baseado no tamanho da tela
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? mobileLarge;
  final Widget? tablet;
  final Widget? tabletLarge;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.mobileLarge,
    this.tablet,
    this.tabletLarge,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        switch (info.deviceType) {
          case DeviceType.desktopLarge:
          case DeviceType.desktop:
            return desktop ?? tabletLarge ?? tablet ?? mobileLarge ?? mobile;
          case DeviceType.tabletLarge:
            return tabletLarge ?? tablet ?? mobileLarge ?? mobile;
          case DeviceType.tablet:
            return tablet ?? mobileLarge ?? mobile;
          case DeviceType.mobileLarge:
            return mobileLarge ?? mobile;
          case DeviceType.mobile:
            return mobile;
        }
      },
    );
  }
}

/// Widget que adiciona padding responsivo automaticamente
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final bool horizontal;
  final bool vertical;
  final double? customHorizontal;
  final double? customVertical;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontal = true,
    this.vertical = false,
    this.customHorizontal,
    this.customVertical,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal ? (customHorizontal ?? info.horizontalPadding) : 0,
            vertical: vertical ? (customVertical ?? 16) : 0,
          ),
          child: child,
        );
      },
    );
  }
}

/// Widget que centraliza conteúdo com largura máxima responsiva
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? info.maxContentWidth,
            ),
            child: Padding(
              padding: padding ?? EdgeInsets.symmetric(horizontal: info.horizontalPadding),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Grid responsivo que ajusta colunas automaticamente
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? columns;
  final double childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.columns,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, info) {
        final gridColumns = columns ?? info.gridColumns;
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Extensão para obter ResponsiveInfo facilmente
extension ResponsiveContext on BuildContext {
  ResponsiveInfo get responsive => ResponsiveInfo.of(this);
  
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  bool get isLandscape => responsive.isLandscape;
  bool get isPortrait => responsive.isPortrait;
  
  double get screenWidth => responsive.screenWidth;
  double get screenHeight => responsive.screenHeight;
}

/// Valores responsivos baseados no tipo de dispositivo
class ResponsiveValue<T> {
  final T mobile;
  final T? mobileLarge;
  final T? tablet;
  final T? tabletLarge;
  final T? desktop;

  const ResponsiveValue({
    required this.mobile,
    this.mobileLarge,
    this.tablet,
    this.tabletLarge,
    this.desktop,
  });

  T resolve(BuildContext context) {
    final info = ResponsiveInfo.of(context);
    
    switch (info.deviceType) {
      case DeviceType.desktopLarge:
      case DeviceType.desktop:
        return desktop ?? tabletLarge ?? tablet ?? mobileLarge ?? mobile;
      case DeviceType.tabletLarge:
        return tabletLarge ?? tablet ?? mobileLarge ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobileLarge ?? mobile;
      case DeviceType.mobileLarge:
        return mobileLarge ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// Tamanhos de fonte responsivos
class ResponsiveFontSize {
  static double xs(BuildContext context) => const ResponsiveValue<double>(
    mobile: 10,
    tablet: 11,
    desktop: 12,
  ).resolve(context);

  static double sm(BuildContext context) => const ResponsiveValue<double>(
    mobile: 12,
    tablet: 13,
    desktop: 14,
  ).resolve(context);

  static double md(BuildContext context) => const ResponsiveValue<double>(
    mobile: 14,
    tablet: 15,
    desktop: 16,
  ).resolve(context);

  static double lg(BuildContext context) => const ResponsiveValue<double>(
    mobile: 16,
    tablet: 18,
    desktop: 20,
  ).resolve(context);

  static double xl(BuildContext context) => const ResponsiveValue<double>(
    mobile: 18,
    tablet: 20,
    desktop: 24,
  ).resolve(context);

  static double xxl(BuildContext context) => const ResponsiveValue<double>(
    mobile: 20,
    tablet: 24,
    desktop: 28,
  ).resolve(context);

  static double display(BuildContext context) => const ResponsiveValue<double>(
    mobile: 24,
    tablet: 32,
    desktop: 40,
  ).resolve(context);
}

/// Espaçamentos responsivos
class ResponsiveSpacing {
  static double xs(BuildContext context) => const ResponsiveValue<double>(
    mobile: 4,
    tablet: 6,
    desktop: 8,
  ).resolve(context);

  static double sm(BuildContext context) => const ResponsiveValue<double>(
    mobile: 8,
    tablet: 10,
    desktop: 12,
  ).resolve(context);

  static double md(BuildContext context) => const ResponsiveValue<double>(
    mobile: 12,
    tablet: 16,
    desktop: 20,
  ).resolve(context);

  static double lg(BuildContext context) => const ResponsiveValue<double>(
    mobile: 16,
    tablet: 20,
    desktop: 24,
  ).resolve(context);

  static double xl(BuildContext context) => const ResponsiveValue<double>(
    mobile: 20,
    tablet: 28,
    desktop: 32,
  ).resolve(context);

  static double xxl(BuildContext context) => const ResponsiveValue<double>(
    mobile: 24,
    tablet: 32,
    desktop: 48,
  ).resolve(context);
}

