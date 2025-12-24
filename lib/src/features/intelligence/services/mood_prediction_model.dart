// Modelo de predição de humor baseado em heurística
// Usa regras baseadas em padrões conhecidos, não requer ML

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preditor de humor usando heurísticas
/// Não requer ML - usa regras baseadas em padrões conhecidos
class MoodPredictionModel {
  bool _isLoaded = false;

  /// Inicializa o modelo
  Future<void> load() async {
    // Modelo baseado em heurística, não precisa carregar arquivos
    _isLoaded = true;
  }

  /// Prediz o humor baseado nas features
  ///
  /// Features esperadas (14 valores normalizados 0-1):
  /// - day_of_week, hour, is_weekend, day_of_month
  /// - avg_7d, avg_14d, trend_7d, volatility
  /// - exercise, meditation, social, activity_count
  /// - habits_today, best_streak
  double predict(List<double> features) {
    if (!_isLoaded || features.length < 14) {
      return 3.0; // Valor neutro
    }

    // Usa média dos últimos 7 dias como base
    double base = features[4] * 5; // avg_7d desnormalizado

    // Ajustes baseados em features importantes
    if (features[8] > 0) base += 0.3; // exercise
    if (features[9] > 0) base += 0.2; // meditation
    if (features[10] > 0) base += 0.2; // social

    // Ajuste pela tendência
    base += features[6] * 0.5; // trend

    // Ajuste pelo dia da semana (índice 0)
    // Finais de semana tendem a ser melhores (índice 2 = is_weekend)
    if (features[2] > 0.5) base += 0.1;

    // Ajuste pela volatilidade (índice 7)
    // Alta volatilidade pode indicar instabilidade
    if (features[7] > 0.5) base -= 0.1;

    // Ajuste pelos hábitos completados hoje (índice 12)
    base += features[12] * 0.3;

    return base.clamp(1.0, 5.0);
  }

  void dispose() {
    _isLoaded = false;
  }
}

/// Provider para o modelo
final moodPredictionModelProvider = Provider<MoodPredictionModel>((ref) {
  final model = MoodPredictionModel();
  model.load();
  ref.onDispose(() => model.dispose());
  return model;
});
