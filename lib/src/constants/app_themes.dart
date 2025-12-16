import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

/// Enum com os temas disponíveis no app
enum AppThemeType {
  // Temas escuros
  ultraviolet,     // Tema atual (compatibilidade)
  midnight,        // Azul profundo
  sakura,          // Rosa/Roxo
  emerald,         // Verde esmeralda
  sunset,          // Laranja/Vermelho
  ocean,           // Azul oceano
  
  // Temas claros  
  lightUltraviolet, // Versão clara do tema atual
  lightMint,        // Verde menta suave
  lightPeach,       // Pêssego suave
  lightSky,         // Azul céu
}

/// Modelo de tema com metadados
class AppThemeData {
  final String name;
  final String description;
  final IconData icon;
  final List<Color> previewColors;
  final bool isDark;
  final ThemeData Function() themeBuilder;

  const AppThemeData({
    required this.name,
    required this.description,
    required this.icon,
    required this.previewColors,
    required this.isDark,
    required this.themeBuilder,
  });
}

/// Classe principal de temas usando FlexColorScheme
class AppThemes {
  // ============================================================
  // CORES CUSTOMIZADAS - Mantendo compatibilidade com UltravioletColors
  // ============================================================
  
  static const _ultravioletPrimary = Color(0xFFA78BFA);
  static const _ultravioletSecondary = Color(0xFF22D3EE);
  static const _ultravioletTertiary = Color(0xFFFBBF24);
  static const _ultravioletBackground = Color(0xFF0A0A0F);
  static const _ultravioletSurface = Color(0xFF111118);
  
  // ============================================================
  // MAPA DE TEMAS DISPONÍVEIS
  // ============================================================
  
  static final Map<AppThemeType, AppThemeData> themes = {
    // ==================== TEMAS ESCUROS ====================
    
    AppThemeType.ultraviolet: AppThemeData(
      name: 'Ultravioleta',
      description: 'Roxo vibrante com cyan',
      icon: Icons.auto_awesome,
      previewColors: [_ultravioletPrimary, _ultravioletSecondary, _ultravioletTertiary],
      isDark: true,
      themeBuilder: () => _buildUltravioletDark(),
    ),
    
    AppThemeType.midnight: AppThemeData(
      name: 'Meia-Noite',
      description: 'Azul profundo elegante',
      icon: Icons.nightlight_round,
      previewColors: [const Color(0xFF60A5FA), const Color(0xFF818CF8), const Color(0xFFA78BFA)],
      isDark: true,
      themeBuilder: () => FlexThemeData.dark(
        scheme: FlexScheme.indigoM3,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 18,
        subThemesData: _subThemesData,
        useMaterial3: true,
        scaffoldBackground: const Color(0xFF0D0D14),
      ),
    ),
    
    AppThemeType.sakura: AppThemeData(
      name: 'Sakura',
      description: 'Rosa suave com roxo',
      icon: Icons.local_florist,
      previewColors: [const Color(0xFFF472B6), const Color(0xFFA78BFA), const Color(0xFFE879F9)],
      isDark: true,
      themeBuilder: () => FlexThemeData.dark(
        scheme: FlexScheme.sakura,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 18,
        subThemesData: _subThemesData,
        useMaterial3: true,
        scaffoldBackground: const Color(0xFF100D12),
      ),
    ),
    
    AppThemeType.emerald: AppThemeData(
      name: 'Esmeralda',
      description: 'Verde natureza',
      icon: Icons.eco,
      previewColors: [const Color(0xFF34D399), const Color(0xFF10B981), const Color(0xFF6EE7B7)],
      isDark: true,
      themeBuilder: () => FlexThemeData.dark(
        scheme: FlexScheme.jungle,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 18,
        subThemesData: _subThemesData,
        useMaterial3: true,
        scaffoldBackground: const Color(0xFF0A0F0D),
      ),
    ),
    
    AppThemeType.sunset: AppThemeData(
      name: 'Pôr do Sol',
      description: 'Laranja quente',
      icon: Icons.wb_twilight,
      previewColors: [const Color(0xFFF97316), const Color(0xFFFB923C), const Color(0xFFEF4444)],
      isDark: true,
      themeBuilder: () => FlexThemeData.dark(
        scheme: FlexScheme.mandyRed,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 18,
        subThemesData: _subThemesData,
        useMaterial3: true,
        scaffoldBackground: const Color(0xFF0F0A0A),
      ),
    ),
    
    AppThemeType.ocean: AppThemeData(
      name: 'Oceano',
      description: 'Azul água profunda',
      icon: Icons.water,
      previewColors: [const Color(0xFF06B6D4), const Color(0xFF0891B2), const Color(0xFF22D3EE)],
      isDark: true,
      themeBuilder: () => FlexThemeData.dark(
        scheme: FlexScheme.cyanM3,
        surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
        blendLevel: 18,
        subThemesData: _subThemesData,
        useMaterial3: true,
        scaffoldBackground: const Color(0xFF0A0D0F),
      ),
    ),
    
    // ==================== TEMAS CLAROS ====================
    
    AppThemeType.lightUltraviolet: AppThemeData(
      name: 'Ultravioleta Claro',
      description: 'Versão clara do tema padrão',
      icon: Icons.auto_awesome_outlined,
      previewColors: [const Color(0xFF7C3AED), const Color(0xFF06B6D4), const Color(0xFFF59E0B)],
      isDark: false,
      themeBuilder: () => _buildUltravioletLight(),
    ),
    
    AppThemeType.lightMint: AppThemeData(
      name: 'Menta',
      description: 'Verde refrescante',
      icon: Icons.spa,
      previewColors: [const Color(0xFF10B981), const Color(0xFF34D399), const Color(0xFF6EE7B7)],
      isDark: false,
      themeBuilder: () => FlexThemeData.light(
        scheme: FlexScheme.jungle,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 10,
        subThemesData: _subThemesData,
        useMaterial3: true,
      ),
    ),
    
    AppThemeType.lightPeach: AppThemeData(
      name: 'Pêssego',
      description: 'Tom quente acolhedor',
      icon: Icons.brightness_5,
      previewColors: [const Color(0xFFF97316), const Color(0xFFFB923C), const Color(0xFFFED7AA)],
      isDark: false,
      themeBuilder: () => FlexThemeData.light(
        scheme: FlexScheme.mandyRed,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 10,
        subThemesData: _subThemesData,
        useMaterial3: true,
      ),
    ),
    
    AppThemeType.lightSky: AppThemeData(
      name: 'Céu',
      description: 'Azul sereno',
      icon: Icons.cloud,
      previewColors: [const Color(0xFF3B82F6), const Color(0xFF60A5FA), const Color(0xFF93C5FD)],
      isDark: false,
      themeBuilder: () => FlexThemeData.light(
        scheme: FlexScheme.indigoM3,
        surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
        blendLevel: 10,
        subThemesData: _subThemesData,
        useMaterial3: true,
      ),
    ),
  };
  
  // ============================================================
  // CONFIGURAÇÃO DE SUB-TEMAS (componentes)
  // ============================================================
  
  static const FlexSubThemesData _subThemesData = FlexSubThemesData(
    // Botões
    elevatedButtonSchemeColor: SchemeColor.primary,
    elevatedButtonRadius: 16.0,
    outlinedButtonRadius: 16.0,
    textButtonRadius: 12.0,
    
    // Cards
    cardRadius: 20.0,
    
    // Inputs
    inputDecoratorRadius: 16.0,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    inputDecoratorUnfocusedHasBorder: true,
    inputDecoratorFocusedHasBorder: true,
    inputDecoratorIsFilled: true,
    
    // Dialogs & Bottom Sheets
    dialogRadius: 24.0,
    bottomSheetRadius: 24.0,
    
    // Navigation
    navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
    navigationBarSelectedIconSchemeColor: SchemeColor.primary,
    navigationBarIndicatorSchemeColor: SchemeColor.primary,
    navigationBarIndicatorOpacity: 0.15,
    navigationBarHeight: 70,
    
    // FAB
    fabRadius: 16.0,
    fabSchemeColor: SchemeColor.primary,
    
    // Chips
    chipRadius: 12.0,
    
    // App Bar
    appBarScrolledUnderElevation: 0,
    appBarCenterTitle: false,
    
    // Switches, Checkboxes, etc
    unselectedToggleIsColored: true,
  );
  
  // ============================================================
  // TEMA ULTRAVIOLET CUSTOMIZADO (compatibilidade com código existente)
  // ============================================================
  
  static ThemeData _buildUltravioletDark() {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: _ultravioletPrimary,
        primaryContainer: Color(0xFF4C1D95),
        secondary: _ultravioletSecondary,
        secondaryContainer: Color(0xFF0E7490),
        tertiary: _ultravioletTertiary,
        tertiaryContainer: Color(0xFFB45309),
        error: Color(0xFFF87171),
      ),
      surfaceMode: FlexSurfaceMode.highBackgroundLowScaffold,
      blendLevel: 15,
      subThemesData: _subThemesData,
      useMaterial3: true,
      scaffoldBackground: _ultravioletBackground,
      surface: _ultravioletSurface,
    ).copyWith(
      // Extensões customizadas para manter compatibilidade
      extensions: [
        const OdysseyColorsExtension(
          cardBackground: Color(0xFF16161E),
          cardBackgroundElevated: Color(0xFF1E1E2A),
          divider: Color(0xFF2D2D3A),
          accent: Color(0xFF8B5CF6),
          glow: Color(0xFF7C3AED),
          accentPink: Color(0xFFF472B6),
          accentBlue: Color(0xFF60A5FA),
          accentGreen: Color(0xFF34D399),
          moodGreat: Color(0xFF34D399),
          moodGood: Color(0xFF60A5FA),
          moodOkay: Color(0xFFFBBF24),
          moodBad: Color(0xFFF97316),
          moodTerrible: Color(0xFFF87171),
        ),
      ],
    );
  }
  
  static ThemeData _buildUltravioletLight() {
    final baseTheme = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: Color(0xFF7C3AED),
        primaryContainer: Color(0xFFEDE9FE),
        secondary: Color(0xFF06B6D4),
        secondaryContainer: Color(0xFFCFFAFE),
        tertiary: Color(0xFFF59E0B),
        tertiaryContainer: Color(0xFFFEF3C7),
        error: Color(0xFFEF4444),
      ),
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
      blendLevel: 5,
      subThemesData: _subThemesData,
      useMaterial3: true,
    );

    // Corrigir explicitamente as cores de surface e onSurface para tema claro
    return baseTheme.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      colorScheme: baseTheme.colorScheme.copyWith(
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF1C1B1F),
        onSurfaceVariant: const Color(0xFF49454F),
        surfaceContainerHighest: const Color(0xFFF0EDF5),
        outline: const Color(0xFF79747E),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFFFFFFF),
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF5F5F7),
        foregroundColor: Color(0xFF1C1B1F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      extensions: [
        const OdysseyColorsExtension(
          cardBackground: Color(0xFFFFFFFF),
          cardBackgroundElevated: Color(0xFFF9FAFB),
          divider: Color(0xFFE5E7EB),
          accent: Color(0xFF7C3AED),
          glow: Color(0xFF7C3AED),
          accentPink: Color(0xFFEC4899),
          accentBlue: Color(0xFF3B82F6),
          accentGreen: Color(0xFF10B981),
          moodGreat: Color(0xFF10B981),
          moodGood: Color(0xFF3B82F6),
          moodOkay: Color(0xFFF59E0B),
          moodBad: Color(0xFFF97316),
          moodTerrible: Color(0xFFEF4444),
        ),
      ],
    );
  }
  
  // ============================================================
  // MÉTODOS AUXILIARES
  // ============================================================
  
  /// Obtém o tema pelo tipo
  static ThemeData getTheme(AppThemeType type) {
    return themes[type]!.themeBuilder();
  }
  
  /// Obtém os metadados do tema
  static AppThemeData getThemeData(AppThemeType type) {
    return themes[type]!;
  }
  
  /// Lista apenas os temas escuros
  static List<AppThemeType> get darkThemes => 
      themes.entries.where((e) => e.value.isDark).map((e) => e.key).toList();
  
  /// Lista apenas os temas claros
  static List<AppThemeType> get lightThemes => 
      themes.entries.where((e) => !e.value.isDark).map((e) => e.key).toList();
  
  // ============================================================
  // TEMAS PADRÃO (para ThemeMode.system)
  // ============================================================
  
  static ThemeData get defaultLightTheme => _buildUltravioletLight();
  static ThemeData get defaultDarkTheme => _buildUltravioletDark();
}

// ============================================================
// EXTENSÃO DE CORES CUSTOMIZADAS DO ODYSSEY
// ============================================================

/// Extensão para cores customizadas que não existem no ColorScheme padrão
class OdysseyColorsExtension extends ThemeExtension<OdysseyColorsExtension> {
  final Color cardBackground;
  final Color cardBackgroundElevated;
  final Color divider;
  final Color accent;
  final Color glow;
  final Color accentPink;
  final Color accentBlue;
  final Color accentGreen;
  final Color moodGreat;
  final Color moodGood;
  final Color moodOkay;
  final Color moodBad;
  final Color moodTerrible;

  const OdysseyColorsExtension({
    required this.cardBackground,
    required this.cardBackgroundElevated,
    required this.divider,
    required this.accent,
    required this.glow,
    required this.accentPink,
    required this.accentBlue,
    required this.accentGreen,
    required this.moodGreat,
    required this.moodGood,
    required this.moodOkay,
    required this.moodBad,
    required this.moodTerrible,
  });

  @override
  ThemeExtension<OdysseyColorsExtension> copyWith({
    Color? cardBackground,
    Color? cardBackgroundElevated,
    Color? divider,
    Color? accent,
    Color? glow,
    Color? accentPink,
    Color? accentBlue,
    Color? accentGreen,
    Color? moodGreat,
    Color? moodGood,
    Color? moodOkay,
    Color? moodBad,
    Color? moodTerrible,
  }) {
    return OdysseyColorsExtension(
      cardBackground: cardBackground ?? this.cardBackground,
      cardBackgroundElevated: cardBackgroundElevated ?? this.cardBackgroundElevated,
      divider: divider ?? this.divider,
      accent: accent ?? this.accent,
      glow: glow ?? this.glow,
      accentPink: accentPink ?? this.accentPink,
      accentBlue: accentBlue ?? this.accentBlue,
      accentGreen: accentGreen ?? this.accentGreen,
      moodGreat: moodGreat ?? this.moodGreat,
      moodGood: moodGood ?? this.moodGood,
      moodOkay: moodOkay ?? this.moodOkay,
      moodBad: moodBad ?? this.moodBad,
      moodTerrible: moodTerrible ?? this.moodTerrible,
    );
  }

  @override
  ThemeExtension<OdysseyColorsExtension> lerp(
    covariant ThemeExtension<OdysseyColorsExtension>? other,
    double t,
  ) {
    if (other is! OdysseyColorsExtension) return this;
    return OdysseyColorsExtension(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBackgroundElevated: Color.lerp(cardBackgroundElevated, other.cardBackgroundElevated, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      accentPink: Color.lerp(accentPink, other.accentPink, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      accentGreen: Color.lerp(accentGreen, other.accentGreen, t)!,
      moodGreat: Color.lerp(moodGreat, other.moodGreat, t)!,
      moodGood: Color.lerp(moodGood, other.moodGood, t)!,
      moodOkay: Color.lerp(moodOkay, other.moodOkay, t)!,
      moodBad: Color.lerp(moodBad, other.moodBad, t)!,
      moodTerrible: Color.lerp(moodTerrible, other.moodTerrible, t)!,
    );
  }
}

// ============================================================
// EXTENSÃO PARA FACILITAR ACESSO ÀS CORES CUSTOMIZADAS
// ============================================================

extension OdysseyColorsContext on BuildContext {
  /// Acessa as cores customizadas do Odyssey
  OdysseyColorsExtension get odysseyColors {
    return Theme.of(this).extension<OdysseyColorsExtension>() ??
        const OdysseyColorsExtension(
          cardBackground: Color(0xFF16161E),
          cardBackgroundElevated: Color(0xFF1E1E2A),
          divider: Color(0xFF2D2D3A),
          accent: Color(0xFF8B5CF6),
          glow: Color(0xFF7C3AED),
          accentPink: Color(0xFFF472B6),
          accentBlue: Color(0xFF60A5FA),
          accentGreen: Color(0xFF34D399),
          moodGreat: Color(0xFF34D399),
          moodGood: Color(0xFF60A5FA),
          moodOkay: Color(0xFFFBBF24),
          moodBad: Color(0xFFF97316),
          moodTerrible: Color(0xFFF87171),
        );
  }
  
  /// Atalho para ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Verifica se o tema atual é escuro
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
