import 'package:flutter/material.dart';

/// Preferências visuais para entradas do diário
/// Inspirado no StoryPad para personalização rica
class DiaryPreferences {
  final String fontFamily;
  final double fontSize;
  final double lineHeight;
  final String? backgroundColorHex;
  final String? textColorHex;
  final bool enableRichText;
  final bool showHeader;
  final String? headerGradientStart;
  final String? headerGradientEnd;
  final double padding;

  const DiaryPreferences({
    this.fontFamily = 'Roboto',
    this.fontSize = 16.0,
    this.lineHeight = 1.5,
    this.backgroundColorHex,
    this.textColorHex,
    this.enableRichText = true,
    this.showHeader = true,
    this.headerGradientStart,
    this.headerGradientEnd,
    this.padding = 16.0,
  });

  DiaryPreferences copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    String? backgroundColorHex,
    String? textColorHex,
    bool? enableRichText,
    bool? showHeader,
    String? headerGradientStart,
    String? headerGradientEnd,
    double? padding,
  }) {
    return DiaryPreferences(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      textColorHex: textColorHex ?? this.textColorHex,
      enableRichText: enableRichText ?? this.enableRichText,
      showHeader: showHeader ?? this.showHeader,
      headerGradientStart: headerGradientStart ?? this.headerGradientStart,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'lineHeight': lineHeight,
    'backgroundColorHex': backgroundColorHex,
    'textColorHex': textColorHex,
    'enableRichText': enableRichText,
    'showHeader': showHeader,
    'headerGradientStart': headerGradientStart,
    'headerGradientEnd': headerGradientEnd,
    'padding': padding,
  };

  factory DiaryPreferences.fromJson(Map<String, dynamic> json) {
    return DiaryPreferences(
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.5,
      backgroundColorHex: json['backgroundColorHex'] as String?,
      textColorHex: json['textColorHex'] as String?,
      enableRichText: json['enableRichText'] as bool? ?? true,
      showHeader: json['showHeader'] as bool? ?? true,
      headerGradientStart: json['headerGradientStart'] as String?,
      headerGradientEnd: json['headerGradientEnd'] as String?,
      padding: (json['padding'] as num?)?.toDouble() ?? 16.0,
    );
  }

  // Getters de cores
  Color? get backgroundColor =>
      backgroundColorHex != null ? _hexToColor(backgroundColorHex!) : null;

  Color? get textColor =>
      textColorHex != null ? _hexToColor(textColorHex!) : null;

  Color? get gradientStartColor =>
      headerGradientStart != null ? _hexToColor(headerGradientStart!) : null;

  Color? get gradientEndColor =>
      headerGradientEnd != null ? _hexToColor(headerGradientEnd!) : null;

  Gradient? get headerGradient {
    if (gradientStartColor == null || gradientEndColor == null) return null;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [gradientStartColor!, gradientEndColor!],
    );
  }

  TextStyle toTextStyle() {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      height: lineHeight,
      color: textColor,
    );
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

/// Fontes disponíveis no app
enum DiaryFont {
  roboto('Roboto', 'Roboto'),
  openSans('Open Sans', 'OpenSans'),
  lato('Lato', 'Lato'),
  montserrat('Montserrat', 'Montserrat'),
  playfairDisplay('Playfair Display', 'PlayfairDisplay'),
  merriweather('Merriweather', 'Merriweather');

  const DiaryFont(this.displayName, this.fontFamily);
  final String displayName;
  final String fontFamily;
}

/// Temas pré-definidos para entradas
class DiaryTheme {
  final String name;
  final DiaryPreferences preferences;
  final IconData icon;

  const DiaryTheme({
    required this.name,
    required this.preferences,
    required this.icon,
  });

  static const List<DiaryTheme> presets = [
    DiaryTheme(
      name: 'Padrão',
      icon: Icons.edit,
      preferences: DiaryPreferences(),
    ),
    DiaryTheme(
      name: 'Noturno',
      icon: Icons.nightlight_round,
      preferences: DiaryPreferences(
        backgroundColorHex: '#1A1A2E',
        textColorHex: '#E0E0E0',
        headerGradientStart: '#16213E',
        headerGradientEnd: '#0F3460',
      ),
    ),
    DiaryTheme(
      name: 'Sereno',
      icon: Icons.spa,
      preferences: DiaryPreferences(
        fontFamily: 'Merriweather',
        fontSize: 17.0,
        lineHeight: 1.8,
        backgroundColorHex: '#F5F5DC',
        textColorHex: '#2C2C2C',
        headerGradientStart: '#A8DADC',
        headerGradientEnd: '#457B9D',
      ),
    ),
    DiaryTheme(
      name: 'Romântico',
      icon: Icons.favorite,
      preferences: DiaryPreferences(
        fontSize: 18.0,
        backgroundColorHex: '#FFF0F5',
        textColorHex: '#4A4A4A',
        headerGradientStart: '#FFB6C1',
        headerGradientEnd: '#FF69B4',
      ),
    ),
    DiaryTheme(
      name: 'Vintage',
      icon: Icons.auto_stories,
      preferences: DiaryPreferences(
        fontSize: 17.0,
        lineHeight: 1.7,
        backgroundColorHex: '#FFF8E7',
        textColorHex: '#3E2723',
        headerGradientStart: '#D7CCC8',
        headerGradientEnd: '#A1887F',
      ),
    ),
    DiaryTheme(
      name: 'Moderno',
      icon: Icons.wb_sunny,
      preferences: DiaryPreferences(
        fontFamily: 'Montserrat',
        fontSize: 16.0,
        backgroundColorHex: '#FFFFFF',
        textColorHex: '#212121',
        headerGradientStart: '#667EEA',
        headerGradientEnd: '#764BA2',
      ),
    ),
  ];
}
