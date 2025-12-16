import 'package:flutter/material.dart';

// ============================================================
// NOTA DE MIGRAÇÃO:
// Este arquivo mantém compatibilidade com o código existente.
// Para novos componentes, prefira usar:
//   - Theme.of(context).colorScheme.primary (cores do tema)
//   - context.odysseyColors.accentGreen (cores customizadas)
//
// Veja app_themes.dart para o novo sistema de temas com FlexColorScheme.
// ============================================================

// Custom theme extensions for Odyssey app
class OdysseyColors {
  // Light theme colors - Modern gradient inspired
  static const Color primary = Color(0xFF7C3AED); // Vibrant purple
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEDE9FE);
  static const Color onPrimaryContainer = Color(0xFF4C1D95);

  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFCFFAFE);
  static const Color onSecondaryContainer = Color(0xFF164E63);

  static const Color tertiary = Color(0xFFF59E0B); // Amber
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFEF3C7);
  static const Color onTertiaryContainer = Color(0xFF78350F);

  static const Color error = Color(0xFFEF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);

  static const Color background = Color(0xFFFAFAFA);
  static const Color onBackground = Color(0xFF1F2937);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1F2937);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color onSurfaceVariant = Color(0xFF6B7280);

  static const Color outline = Color(0xFFD1D5DB);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
}

// 🌸 Wellness Theme - Soft & Calming
class WellnessColors {
  // Primary - Soft Purple/Lavender
  static const Color primary = Color(0xFF9C27B0); // Purple 500
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFF3E5F5); // Purple 50
  static const Color onPrimaryContainer = Color(0xFF4A148C); // Purple 900

  // Secondary - Calming Blue
  static const Color secondary = Color(0xFFE3F2FD); // Blue 50
  static const Color onSecondary = Color(0xFF1E88E5); // Blue 600

  // Backgrounds
  static const Color background = Color(
    0xFFFDFBFE,
  ); // Very light lavender/white
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Status
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373); // Red 300

  // Gradients
  static const List<Color> purpleGradient = [
    Color(0xFFAB47BC), // Purple 400
    Color(0xFF7B1FA2), // Purple 700
  ];

  static const List<Color> softGradient = [
    Color(0xFFF3E5F5),
    Color(0xFFE1BEE7),
  ];
}

// ✨ Modern Dark Theme - Midnight Aurora
class UltravioletColors {
  // Primary - Electric Purple
  static const Color primary = Color(0xFFA78BFA); // Soft lavender
  static const Color onPrimary = Color(0xFF1E1B4B);
  static const Color primaryContainer = Color(0xFF4C1D95);
  static const Color onPrimaryContainer = Color(0xFFEDE9FE);

  // Secondary - Neon Cyan
  static const Color secondary = Color(0xFF22D3EE); // Bright cyan
  static const Color onSecondary = Color(0xFF164E63);
  static const Color secondaryContainer = Color(0xFF0E7490);
  static const Color onSecondaryContainer = Color(0xFFCFFAFE);

  // Tertiary - Warm Amber
  static const Color tertiary = Color(0xFFFBBF24); // Golden amber
  static const Color onTertiary = Color(0xFF78350F);
  static const Color tertiaryContainer = Color(0xFFB45309);
  static const Color onTertiaryContainer = Color(0xFFFEF3C7);

  // Accent colors for gradients
  static const Color accentPink = Color(0xFFF472B6); // Hot pink
  static const Color accentBlue = Color(0xFF60A5FA); // Sky blue
  static const Color accentGreen = Color(0xFF34D399); // Emerald

  static const Color error = Color(0xFFF87171);
  static const Color onError = Color(0xFF7F1D1D);
  static const Color errorContainer = Color(0xFFB91C1C);
  static const Color onErrorContainer = Color(0xFFFEE2E2);

  // Dark background - Deep space
  static const Color background = Color(
    0xFF0A0A0F,
  ); // Almost black with blue tint
  static const Color onBackground = Color(0xFFF3F4F6);

  static const Color surface = Color(0xFF111118); // Slightly lighter
  static const Color onSurface = Color(0xFFF9FAFB);
  static const Color surfaceVariant = Color(0xFF1C1C26); // Card background
  static const Color onSurfaceVariant = Color(0xFFD1D5DB);

  static const Color outline = Color(0xFF374151);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  // Additional colors for UI elements
  static const Color cardBackground = Color(0xFF16161E);
  static const Color cardBackgroundElevated = Color(0xFF1E1E2A);
  static const Color divider = Color(0xFF2D2D3A);
  static const Color accent = Color(0xFF8B5CF6); // Vibrant purple
  static const Color glow = Color(0xFF7C3AED);

  // Mood colors
  static const Color moodGreat = Color(0xFF34D399);
  static const Color moodGood = Color(0xFF60A5FA);
  static const Color moodOkay = Color(0xFFFBBF24);
  static const Color moodBad = Color(0xFFF97316);
  static const Color moodTerrible = Color(0xFFF87171);

  // Gradient definitions
  static const List<Color> primaryGradient = [
    Color(0xFF7C3AED),
    Color(0xFFA78BFA),
  ];

  static const List<Color> accentGradient = [
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> warmGradient = [
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
  ];

  static const List<Color> coolGradient = [
    Color(0xFF22D3EE),
    Color(0xFF3B82F6),
  ];

  static const List<Color> auroraGradient = [
    Color(0xFF7C3AED),
    Color(0xFF22D3EE),
    Color(0xFF34D399),
  ];
}

class OdysseyTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: OdysseyColors.background,
      colorScheme: const ColorScheme.light(
        primary: OdysseyColors.primary,
        onPrimary: OdysseyColors.onPrimary,
        primaryContainer: OdysseyColors.primaryContainer,
        onPrimaryContainer: OdysseyColors.onPrimaryContainer,
        secondary: OdysseyColors.secondary,
        onSecondary: OdysseyColors.onSecondary,
        secondaryContainer: OdysseyColors.secondaryContainer,
        onSecondaryContainer: OdysseyColors.onSecondaryContainer,
        tertiary: OdysseyColors.tertiary,
        onTertiary: OdysseyColors.onTertiary,
        tertiaryContainer: OdysseyColors.tertiaryContainer,
        onTertiaryContainer: OdysseyColors.onTertiaryContainer,
        error: OdysseyColors.error,
        onError: OdysseyColors.onError,
        errorContainer: OdysseyColors.errorContainer,
        onErrorContainer: OdysseyColors.onErrorContainer,
        surface: OdysseyColors.surface,
        onSurface: OdysseyColors.onSurface,
        surfaceContainerHighest: OdysseyColors.surfaceVariant,
        onSurfaceVariant: OdysseyColors.onSurfaceVariant,
        outline: OdysseyColors.outline,
        shadow: OdysseyColors.shadow,
        scrim: OdysseyColors.scrim,
      ),

      // Modern text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: OdysseyColors.onSurface,
          fontSize: 40,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: OdysseyColors.onSurface,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: OdysseyColors.onSurface,
          fontSize: 28,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: OdysseyColors.onSurface,
          fontSize: 28,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: OdysseyColors.onSurface,
          fontSize: 24,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: OdysseyColors.onSurface,
          fontSize: 20,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: OdysseyColors.onSurface,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: OdysseyColors.onSurface,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w500,
          color: OdysseyColors.onSurfaceVariant,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          color: OdysseyColors.onSurface,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: OdysseyColors.onSurface,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: OdysseyColors.onSurfaceVariant,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: OdysseyColors.onSurface,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: OdysseyColors.onSurfaceVariant,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w500,
          color: OdysseyColors.onSurfaceVariant,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),

      // Modern elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OdysseyColors.primary,
          foregroundColor: OdysseyColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: OdysseyColors.primary,
          side: BorderSide(
            color: OdysseyColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OdysseyColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),

      // Modern card theme
      cardTheme: CardThemeData(
        color: OdysseyColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: OdysseyColors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // Modern input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OdysseyColors.surfaceVariant.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: OdysseyColors.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OdysseyColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OdysseyColors.error, width: 1),
        ),
        labelStyle: const TextStyle(color: OdysseyColors.onSurfaceVariant),
        hintStyle: TextStyle(
          color: OdysseyColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIconColor: OdysseyColors.onSurfaceVariant,
        suffixIconColor: OdysseyColors.onSurfaceVariant,
      ),

      // Modern app bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: OdysseyColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: OdysseyColors.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Modern navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: OdysseyColors.surface,
        indicatorColor: OdysseyColors.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: OdysseyColors.primary, size: 24);
          }
          return IconThemeData(
            color: OdysseyColors.onSurfaceVariant.withValues(alpha: 0.7),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: OdysseyColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: OdysseyColors.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: OdysseyColors.surface,
        selectedItemColor: OdysseyColors.primary,
        unselectedItemColor: OdysseyColors.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: OdysseyColors.primary,
        foregroundColor: OdysseyColors.onPrimary,
        elevation: 4,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: OdysseyColors.outline.withValues(alpha: 0.3),
        thickness: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(color: OdysseyColors.onSurface, size: 24),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        iconColor: OdysseyColors.onSurface,
        textColor: OdysseyColors.onSurface,
        tileColor: OdysseyColors.surface,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: UltravioletColors.background,
      colorScheme: const ColorScheme.dark(
        primary: UltravioletColors.primary,
        onPrimary: UltravioletColors.onPrimary,
        primaryContainer: UltravioletColors.primaryContainer,
        onPrimaryContainer: UltravioletColors.onPrimaryContainer,
        secondary: UltravioletColors.secondary,
        onSecondary: UltravioletColors.onSecondary,
        secondaryContainer: UltravioletColors.secondaryContainer,
        onSecondaryContainer: UltravioletColors.onSecondaryContainer,
        tertiary: UltravioletColors.tertiary,
        onTertiary: UltravioletColors.onTertiary,
        tertiaryContainer: UltravioletColors.tertiaryContainer,
        onTertiaryContainer: UltravioletColors.onTertiaryContainer,
        error: UltravioletColors.error,
        onError: UltravioletColors.onError,
        errorContainer: UltravioletColors.errorContainer,
        onErrorContainer: UltravioletColors.onErrorContainer,
        surface: UltravioletColors.surface,
        onSurface: UltravioletColors.onSurface,
        surfaceContainerHighest: UltravioletColors.surfaceVariant,
        onSurfaceVariant: UltravioletColors.onSurfaceVariant,
        outline: UltravioletColors.outline,
        shadow: UltravioletColors.shadow,
        scrim: UltravioletColors.scrim,
      ),

      // Modern text theme with better hierarchy
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: UltravioletColors.onSurface,
          fontSize: 40,
          letterSpacing: -1.0,
        ),
        displayMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: UltravioletColors.onSurface,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displaySmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: UltravioletColors.onSurface,
          fontSize: 28,
        ),
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: UltravioletColors.onSurface,
          fontSize: 28,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: UltravioletColors.onSurface,
          fontSize: 24,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w600,
          color: UltravioletColors.onSurface,
          fontSize: 20,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: UltravioletColors.onSurface,
          fontSize: 18,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: UltravioletColors.onSurface,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          fontWeight: FontWeight.w500,
          color: UltravioletColors.onSurfaceVariant,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(
          color: UltravioletColors.onSurface,
          fontSize: 16,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: UltravioletColors.onSurface,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          color: UltravioletColors.onSurfaceVariant,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: UltravioletColors.onSurface,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w500,
          color: UltravioletColors.onSurfaceVariant,
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          fontWeight: FontWeight.w500,
          color: UltravioletColors.onSurfaceVariant,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),

      // Modern elevated button with gradient feel
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UltravioletColors.primary,
          foregroundColor: UltravioletColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: UltravioletColors.primary,
          side: BorderSide(
            color: UltravioletColors.primary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UltravioletColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),

      // Modern card theme with glass effect
      cardTheme: CardThemeData(
        color: UltravioletColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: UltravioletColors.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // Modern input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: UltravioletColors.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: UltravioletColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: UltravioletColors.error,
            width: 1,
          ),
        ),
        labelStyle: const TextStyle(color: UltravioletColors.onSurfaceVariant),
        hintStyle: TextStyle(
          color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        prefixIconColor: UltravioletColors.onSurfaceVariant,
        suffixIconColor: UltravioletColors.onSurfaceVariant,
      ),

      // Modern app bar - clean and minimal
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: UltravioletColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: UltravioletColors.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // Modern navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: UltravioletColors.surface,
        indicatorColor: UltravioletColors.primary.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 70,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: UltravioletColors.primary,
              size: 24,
            );
          }
          return IconThemeData(
            color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.7),
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: UltravioletColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
      ),

      // Bottom navigation bar theme (fallback)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: UltravioletColors.surface,
        selectedItemColor: UltravioletColors.primary,
        unselectedItemColor: UltravioletColors.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: UltravioletColors.accent,
        foregroundColor: UltravioletColors.onPrimary,
        elevation: 6,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: UltravioletColors.divider,
        thickness: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: UltravioletColors.onSurface,
        size: 24,
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        iconColor: UltravioletColors.onSurface,
        textColor: UltravioletColors.onSurface,
        tileColor: UltravioletColors.cardBackground,
      ),
    );
  }

  // Dynamic theme functionality removed due to compatibility issues
  // static Future<ThemeData> get dynamicLightTheme async { ... }
  // static Future<ThemeData> get dynamicDarkTheme async { ... }
}

/// Alias for backward compatibility
class AppTheme {
  static ThemeData get darkTheme => OdysseyTheme.darkTheme;
  static ThemeData get lightTheme => OdysseyTheme.lightTheme;
}

/// Helper para obter cores adaptativas baseadas no tema atual
class AdaptiveColors {
  final bool isDark;

  AdaptiveColors(BuildContext context)
    : isDark = Theme.of(context).brightness == Brightness.dark;

  Color get background =>
      isDark ? UltravioletColors.background : OdysseyColors.background;
  Color get surface =>
      isDark ? UltravioletColors.surface : OdysseyColors.surface;
  Color get cardBackground =>
      isDark ? UltravioletColors.cardBackground : OdysseyColors.surface;
  Color get primary =>
      isDark ? UltravioletColors.primary : OdysseyColors.primary;
  Color get secondary =>
      isDark ? UltravioletColors.secondary : OdysseyColors.secondary;
  Color get tertiary =>
      isDark ? UltravioletColors.tertiary : OdysseyColors.tertiary;
  Color get error => isDark ? UltravioletColors.error : OdysseyColors.error;
  Color get onSurface =>
      isDark ? UltravioletColors.onSurface : OdysseyColors.onSurface;
  Color get onSurfaceVariant => isDark
      ? UltravioletColors.onSurfaceVariant
      : OdysseyColors.onSurfaceVariant;
  Color get outline =>
      isDark ? UltravioletColors.outline : OdysseyColors.outline;
  Color get surfaceVariant =>
      isDark ? UltravioletColors.surfaceVariant : OdysseyColors.surfaceVariant;
  Color get primaryContainer => isDark
      ? UltravioletColors.primaryContainer
      : OdysseyColors.primaryContainer;
  Color get secondaryContainer => isDark
      ? UltravioletColors.secondaryContainer
      : OdysseyColors.secondaryContainer;
  Color get accentGreen =>
      isDark ? UltravioletColors.accentGreen : const Color(0xFF10B981);
  Color get accentBlue =>
      isDark ? UltravioletColors.accentBlue : const Color(0xFF3B82F6);
  Color get accentPink =>
      isDark ? UltravioletColors.accentPink : const Color(0xFFEC4899);

  List<Color> get accentGradient => isDark
      ? UltravioletColors.accentGradient
      : [OdysseyColors.primary, OdysseyColors.secondary];

  List<Color> get primaryGradient => isDark
      ? UltravioletColors.primaryGradient
      : [OdysseyColors.primary, OdysseyColors.primaryContainer];
}
