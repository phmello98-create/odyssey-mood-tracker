import 'package:flutter/animation.dart';
import 'package:motor/motor.dart';

/// Presets de Motion para uso consistente no app
class AppMotion {
  // ==========================================
  // SPRINGS PRINCIPAIS
  // ==========================================
  
  /// Spring suave para transições gerais
  static const smooth = CupertinoMotion.smooth();
  
  /// Spring bouncy para interações divertidas
  static const bouncy = CupertinoMotion.bouncy();
  
  /// Spring snappy para respostas rápidas
  static const snappy = CupertinoMotion.snappy();
  
  /// Spring interativo para gestos do usuário
  static const interactive = CupertinoMotion.interactive();
  
  // ==========================================
  // MATERIAL DESIGN 3 SPRINGS
  // ==========================================
  
  /// Material spatial para posição/tamanho
  static const materialSpatial = MaterialSpringMotion.standardSpatialDefault();
  
  /// Material expressive para animações chamativas
  static const materialExpressive = MaterialSpringMotion.expressiveSpatialDefault();
  
  /// Material effects para opacidade/cor
  static const materialEffects = MaterialSpringMotion.standardEffectsDefault();
  
  // ==========================================
  // CUSTOMIZADOS PARA O APP
  // ==========================================
  
  /// Para cards e itens de lista
  static const card = CupertinoMotion(
    duration: Duration(milliseconds: 400),
    bounce: 0.15,
  );
  
  /// Para botões e cliques
  static const button = CupertinoMotion(
    duration: Duration(milliseconds: 200),
    bounce: 0.1,
  );
  
  /// Para modais e sheets
  static const modal = CupertinoMotion(
    duration: Duration(milliseconds: 350),
    bounce: 0.05,
  );
  
  /// Para checkboxes e toggles
  static const toggle = CupertinoMotion(
    duration: Duration(milliseconds: 250),
    bounce: 0.25,
  );
  
  /// Para progresso e carregamento
  static const progress = CupertinoMotion(
    duration: Duration(milliseconds: 800),
    bounce: 0.0,
  );
  
  /// Para número/contadores
  static const counter = CupertinoMotion(
    duration: Duration(milliseconds: 600),
    bounce: 0.0,
  );
  
  /// Para celebrações (level up, conquistas)
  static const celebration = CupertinoMotion(
    duration: Duration(milliseconds: 500),
    bounce: 0.4,
  );
  
  /// Para entrada em cascata de listas
  static const stagger = CupertinoMotion(
    duration: Duration(milliseconds: 300),
    bounce: 0.2,
  );
  
  /// Para hero transitions
  static const hero = CupertinoMotion(
    duration: Duration(milliseconds: 400),
    bounce: 0.1,
  );
  
  // ==========================================
  // DURAÇÕES BASEADAS EM CURVES
  // ==========================================
  
  /// Linear rápido
  static Motion linearFast = const Motion.linear(Duration(milliseconds: 200));
  
  /// Linear médio
  static Motion linearMedium = const Motion.linear(Duration(milliseconds: 400));
  
  /// Ease in out
  static Motion easeInOut = const Motion.curved(
    Duration(milliseconds: 300),
    Curves.easeInOut,
  );
  
  /// Ease out back (bounce no final)
  static Motion easeOutBack = const Motion.curved(
    Duration(milliseconds: 400),
    Curves.easeOutBack,
  );
}
