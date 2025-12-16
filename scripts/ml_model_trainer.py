#!/usr/bin/env python3
"""
🤖 ML MODEL TRAINER - Preparação para TFLite

Este script prepara e treina um modelo de ML para previsão de humor
que pode ser convertido para TFLite e usado no app Flutter.

Funcionalidades:
1. Preparação de dados (feature engineering)
2. Treinamento de modelo (Random Forest / Gradient Boosting)
3. Exportação para formato compatível com TFLite
4. Geração de código Dart para carregar o modelo

Uso:
  python scripts/ml_model_trainer.py --train
  python scripts/ml_model_trainer.py --export
  python scripts/ml_model_trainer.py --generate-dart
"""

import argparse
import json
import math
import random
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
from dataclasses import dataclass
import pickle
import os

# Tenta importar bibliotecas de ML (opcionais)
try:
    import numpy as np
    HAS_NUMPY = True
except ImportError:
    HAS_NUMPY = False
    print("⚠️ NumPy não instalado. Usando implementação pura Python.")

try:
    from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
    from sklearn.model_selection import train_test_split
    from sklearn.metrics import mean_squared_error, r2_score
    HAS_SKLEARN = True
except ImportError:
    HAS_SKLEARN = False
    print("⚠️ Scikit-learn não instalado. Usando modelo simplificado.")


# ============ FEATURE ENGINEERING ============

@dataclass
class MoodFeatures:
    """Features extraídas para predição de humor."""
    # Temporais
    day_of_week: int  # 0-6
    hour_of_day: int  # 0-23
    is_weekend: int   # 0 ou 1
    day_of_month: int # 1-31
    
    # Históricas
    avg_mood_7d: float     # Média últimos 7 dias
    avg_mood_14d: float    # Média últimos 14 dias
    mood_trend_7d: float   # Tendência (slope)
    mood_volatility: float # Desvio padrão
    
    # Atividades (últimas 24h)
    had_exercise: int     # 0 ou 1
    had_meditation: int   # 0 ou 1
    had_social: int       # 0 ou 1
    activity_count: int   # Número de atividades
    
    # Hábitos
    habits_completed_today: int
    current_best_streak: int
    
    # Target (para treinamento)
    target_mood: float = 0.0

    def to_list(self) -> List[float]:
        """Converte para lista de features."""
        return [
            self.day_of_week / 6,  # Normalizado 0-1
            self.hour_of_day / 23,
            self.is_weekend,
            self.day_of_month / 31,
            self.avg_mood_7d / 5,
            self.avg_mood_14d / 5,
            self.mood_trend_7d,  # Já normalizado
            self.mood_volatility,
            self.had_exercise,
            self.had_meditation,
            self.had_social,
            min(self.activity_count / 5, 1),
            min(self.habits_completed_today / 5, 1),
            min(self.current_best_streak / 30, 1),
        ]


class FeatureExtractor:
    """Extrai features dos dados brutos."""
    
    def extract_features(
        self,
        mood_records: List[Dict],
        habits: List[Dict],
        target_date: datetime,
    ) -> MoodFeatures:
        """Extrai features para uma data específica."""
        
        # Filtra registros anteriores à data alvo
        past_records = [
            r for r in mood_records
            if datetime.fromisoformat(r['date']) < target_date
        ]
        
        if not past_records:
            return self._empty_features(target_date)
        
        # Ordena por data
        past_records.sort(key=lambda x: x['date'])
        
        # Features temporais
        day_of_week = target_date.weekday()
        hour = target_date.hour
        is_weekend = 1 if day_of_week >= 5 else 0
        day_of_month = target_date.day
        
        # Médias históricas
        recent_7d = self._get_recent_scores(past_records, target_date, 7)
        recent_14d = self._get_recent_scores(past_records, target_date, 14)
        
        avg_7d = sum(recent_7d) / len(recent_7d) if recent_7d else 3.0
        avg_14d = sum(recent_14d) / len(recent_14d) if recent_14d else 3.0
        
        # Tendência
        trend_7d = self._calculate_trend(recent_7d) if len(recent_7d) >= 3 else 0
        
        # Volatilidade
        volatility = self._calculate_volatility(recent_7d) if recent_7d else 0.5
        
        # Atividades recentes (últimas 24h)
        recent_activities = self._get_recent_activities(past_records, target_date, 1)
        had_exercise = 1 if 'exercicio' in recent_activities else 0
        had_meditation = 1 if 'meditacao' in recent_activities else 0
        had_social = 1 if 'socializar' in recent_activities else 0
        activity_count = len(recent_activities)
        
        # Hábitos
        habits_today = sum(
            1 for h in habits
            if target_date.strftime('%Y-%m-%d') in h.get('completions', [])
        )
        best_streak = max((h.get('current_streak', 0) for h in habits), default=0)
        
        return MoodFeatures(
            day_of_week=day_of_week,
            hour_of_day=hour,
            is_weekend=is_weekend,
            day_of_month=day_of_month,
            avg_mood_7d=avg_7d,
            avg_mood_14d=avg_14d,
            mood_trend_7d=trend_7d,
            mood_volatility=volatility,
            had_exercise=had_exercise,
            had_meditation=had_meditation,
            had_social=had_social,
            activity_count=activity_count,
            habits_completed_today=habits_today,
            current_best_streak=best_streak,
        )
    
    def _empty_features(self, date: datetime) -> MoodFeatures:
        return MoodFeatures(
            day_of_week=date.weekday(),
            hour_of_day=date.hour,
            is_weekend=1 if date.weekday() >= 5 else 0,
            day_of_month=date.day,
            avg_mood_7d=3.0,
            avg_mood_14d=3.0,
            mood_trend_7d=0,
            mood_volatility=0.5,
            had_exercise=0,
            had_meditation=0,
            had_social=0,
            activity_count=0,
            habits_completed_today=0,
            current_best_streak=0,
        )
    
    def _get_recent_scores(
        self,
        records: List[Dict],
        before_date: datetime,
        days: int,
    ) -> List[float]:
        cutoff = before_date - timedelta(days=days)
        return [
            r['score']
            for r in records
            if cutoff <= datetime.fromisoformat(r['date']) < before_date
        ]
    
    def _get_recent_activities(
        self,
        records: List[Dict],
        before_date: datetime,
        days: int,
    ) -> set:
        cutoff = before_date - timedelta(days=days)
        activities = set()
        for r in records:
            if cutoff <= datetime.fromisoformat(r['date']) < before_date:
                activities.update(r.get('activities', []))
        return activities
    
    def _calculate_trend(self, scores: List[float]) -> float:
        if len(scores) < 2:
            return 0
        
        n = len(scores)
        x = list(range(n))
        
        sum_x = sum(x)
        sum_y = sum(scores)
        sum_xy = sum(x[i] * scores[i] for i in range(n))
        sum_x2 = sum(xi ** 2 for xi in x)
        
        denom = n * sum_x2 - sum_x ** 2
        if denom == 0:
            return 0
        
        slope = (n * sum_xy - sum_x * sum_y) / denom
        return max(-1, min(1, slope))  # Normaliza entre -1 e 1
    
    def _calculate_volatility(self, scores: List[float]) -> float:
        if not scores:
            return 0.5
        
        mean = sum(scores) / len(scores)
        variance = sum((s - mean) ** 2 for s in scores) / len(scores)
        std_dev = math.sqrt(variance)
        
        # Normaliza (stddev típico é 0-1.5 para scores 1-5)
        return min(std_dev / 1.5, 1)


# ============ MODELO SIMPLIFICADO (sem sklearn) ============

class SimpleLinearModel:
    """Modelo linear simples para quando sklearn não está disponível."""
    
    def __init__(self):
        self.weights = None
        self.bias = 0
    
    def fit(self, X: List[List[float]], y: List[float], epochs: int = 100, lr: float = 0.01):
        """Treina usando gradiente descendente."""
        n_features = len(X[0])
        self.weights = [0.0] * n_features
        self.bias = sum(y) / len(y)  # Média como bias inicial
        
        for epoch in range(epochs):
            total_error = 0
            for i, features in enumerate(X):
                # Predição
                pred = self._predict_single(features)
                error = y[i] - pred
                total_error += error ** 2
                
                # Atualiza pesos
                for j in range(n_features):
                    self.weights[j] += lr * error * features[j]
                self.bias += lr * error
            
            if epoch % 20 == 0:
                mse = total_error / len(X)
                print(f"  Epoch {epoch}: MSE = {mse:.4f}")
    
    def _predict_single(self, features: List[float]) -> float:
        pred = self.bias
        for i, w in enumerate(self.weights):
            pred += w * features[i]
        return max(1, min(5, pred))  # Clamp entre 1-5
    
    def predict(self, X: List[List[float]]) -> List[float]:
        return [self._predict_single(f) for f in X]
    
    def score(self, X: List[List[float]], y: List[float]) -> float:
        predictions = self.predict(X)
        ss_res = sum((y[i] - predictions[i]) ** 2 for i in range(len(y)))
        ss_tot = sum((yi - sum(y) / len(y)) ** 2 for yi in y)
        return 1 - (ss_res / ss_tot) if ss_tot > 0 else 0


# ============ GERADOR DE DADOS DE TREINO ============

def generate_training_data(days: int = 180, seed: int = 42) -> Tuple[List[Dict], List[Dict]]:
    """Gera dados sintéticos para treinamento."""
    random.seed(seed)
    now = datetime.now()
    
    activities = ['exercicio', 'meditacao', 'leitura', 'trabalho', 'socializar', 'natureza']
    
    mood_records = []
    habits = [
        {'id': 'med', 'name': 'Meditação', 'completions': [], 'current_streak': 0},
        {'id': 'ex', 'name': 'Exercício', 'completions': [], 'current_streak': 0},
        {'id': 'read', 'name': 'Leitura', 'completions': [], 'current_streak': 0},
    ]
    
    prev_mood = 3.0
    prev_exercise = False
    
    for i in range(days):
        date = now - timedelta(days=days - 1 - i)
        weekday = date.weekday()
        
        # Base com padrões realistas
        base = 3.0
        base += 0.2 if weekday == 0 else 0  # Segunda melhor
        base -= 0.15 if weekday == 2 else 0  # Quarta pior
        base += 0.25 if weekday >= 5 else 0  # Fim de semana
        
        # Efeito de exercício do dia anterior
        if prev_exercise:
            base += 0.4
        
        # Tendência de longo prazo
        base += i * 0.003
        
        # Atividades
        day_activities = []
        did_exercise = random.random() < 0.35
        if did_exercise:
            day_activities.append('exercicio')
            base += 0.25
        
        if random.random() < 0.25:
            day_activities.append('meditacao')
            base += 0.15
        
        if random.random() < 0.3:
            day_activities.append('socializar')
            base += 0.2
        
        for act in ['leitura', 'trabalho', 'natureza']:
            if random.random() < 0.2:
                day_activities.append(act)
        
        # Inércia (humor anterior influencia)
        base = base * 0.7 + prev_mood * 0.3
        
        # Ruído
        noise = random.gauss(0, 0.35)
        score = max(1, min(5, base + noise))
        
        mood_records.append({
            'date': date.replace(hour=random.randint(7, 22)).isoformat(),
            'score': round(score, 2),
            'activities': day_activities,
        })
        
        # Atualiza hábitos
        date_str = date.strftime('%Y-%m-%d')
        if did_exercise:
            habits[1]['completions'].append(date_str)
        if 'meditacao' in day_activities:
            habits[0]['completions'].append(date_str)
        if 'leitura' in day_activities:
            habits[2]['completions'].append(date_str)
        
        prev_mood = score
        prev_exercise = did_exercise
    
    return mood_records, habits


# ============ TREINAMENTO ============

def train_model(mood_records: List[Dict], habits: List[Dict]):
    """Treina o modelo de predição de humor."""
    print("\n🧠 Preparando dados para treinamento...")
    
    extractor = FeatureExtractor()
    
    # Prepara dataset
    X = []
    y = []
    
    for i, record in enumerate(mood_records):
        if i < 14:  # Precisa de histórico
            continue
        
        date = datetime.fromisoformat(record['date'])
        features = extractor.extract_features(mood_records[:i], habits, date)
        features.target_mood = record['score']
        
        X.append(features.to_list())
        y.append(record['score'])
    
    print(f"   ✓ {len(X)} amostras preparadas")
    print(f"   ✓ {len(X[0])} features por amostra")
    
    # Split train/test
    split_idx = int(len(X) * 0.8)
    X_train, X_test = X[:split_idx], X[split_idx:]
    y_train, y_test = y[:split_idx], y[split_idx:]
    
    print(f"   ✓ Train: {len(X_train)}, Test: {len(X_test)}")
    
    # Treina modelo
    print("\n📊 Treinando modelo...")
    
    if HAS_SKLEARN:
        model = GradientBoostingRegressor(
            n_estimators=100,
            max_depth=4,
            learning_rate=0.1,
            random_state=42,
        )
        model.fit(X_train, y_train)
        
        # Avalia
        train_pred = model.predict(X_train)
        test_pred = model.predict(X_test)
        
        train_mse = mean_squared_error(y_train, train_pred)
        test_mse = mean_squared_error(y_test, test_pred)
        test_r2 = r2_score(y_test, test_pred)
        
        print(f"   ✓ Train MSE: {train_mse:.4f}")
        print(f"   ✓ Test MSE: {test_mse:.4f}")
        print(f"   ✓ Test R²: {test_r2:.4f}")
        
        # Feature importance
        print("\n📈 Importância das features:")
        feature_names = [
            'day_of_week', 'hour', 'is_weekend', 'day_of_month',
            'avg_7d', 'avg_14d', 'trend_7d', 'volatility',
            'exercise', 'meditation', 'social', 'activity_count',
            'habits_today', 'best_streak'
        ]
        
        importances = list(zip(feature_names, model.feature_importances_))
        importances.sort(key=lambda x: -x[1])
        
        for name, imp in importances[:5]:
            print(f"   • {name}: {imp:.3f}")
        
    else:
        model = SimpleLinearModel()
        model.fit(X_train, y_train, epochs=100)
        
        test_r2 = model.score(X_test, y_test)
        print(f"   ✓ Test R²: {test_r2:.4f}")
    
    return model


def generate_dart_loader():
    """Gera código Dart para carregar modelo TFLite."""
    
    dart_code = '''
// AUTO-GENERATED - ML Model Loader
// Gerado por scripts/ml_model_trainer.py

import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Carrega e executa o modelo TFLite de predição de humor
class MoodPredictionModel {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  /// Carrega o modelo
  Future<void> load() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/mood_predictor.tflite');
      _isLoaded = true;
    } catch (e) {
      print('Erro ao carregar modelo: $e');
      _isLoaded = false;
    }
  }

  /// Prediz o humor baseado nas features
  /// 
  /// Features esperadas (14 valores normalizados 0-1):
  /// - day_of_week, hour, is_weekend, day_of_month
  /// - avg_7d, avg_14d, trend_7d, volatility
  /// - exercise, meditation, social, activity_count
  /// - habits_today, best_streak
  double predict(List<double> features) {
    if (!_isLoaded || _interpreter == null) {
      // Fallback: média ponderada simples
      return _fallbackPredict(features);
    }

    try {
      var input = [features];
      var output = List.filled(1, 0.0).reshape([1, 1]);
      
      _interpreter!.run(input, output);
      
      // Desnormaliza (0-1 -> 1-5)
      double score = output[0][0] * 4 + 1;
      return score.clamp(1.0, 5.0);
    } catch (e) {
      print('Erro na predição: $e');
      return _fallbackPredict(features);
    }
  }

  /// Fallback quando modelo não está disponível
  double _fallbackPredict(List<double> features) {
    // Usa média dos últimos 7 dias como base
    double base = features[4] * 5;  // avg_7d desnormalizado
    
    // Ajustes baseados em features importantes
    if (features[8] > 0) base += 0.3;  // exercise
    if (features[9] > 0) base += 0.2;  // meditation
    if (features[10] > 0) base += 0.2; // social
    
    // Tendência
    base += features[6] * 0.5;  // trend
    
    return base.clamp(1.0, 5.0);
  }

  void dispose() {
    _interpreter?.close();
  }
}

/// Provider para o modelo
final moodPredictionModelProvider = Provider<MoodPredictionModel>((ref) {
  final model = MoodPredictionModel();
  model.load();
  ref.onDispose(() => model.dispose());
  return model;
});
'''
    
    return dart_code


# ============ MAIN ============

def main():
    parser = argparse.ArgumentParser(description='ML Model Trainer')
    parser.add_argument('--train', action='store_true', help='Treina o modelo')
    parser.add_argument('--export', action='store_true', help='Exporta para TFLite')
    parser.add_argument('--generate-dart', action='store_true', help='Gera código Dart')
    parser.add_argument('--days', type=int, default=180, help='Dias de dados')
    args = parser.parse_args()
    
    if args.generate_dart:
        print("📝 Gerando código Dart...")
        dart_code = generate_dart_loader()
        
        output_path = 'lib/src/features/intelligence/services/mood_prediction_model.dart'
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        
        with open(output_path, 'w') as f:
            f.write(dart_code)
        
        print(f"✅ Código gerado em: {output_path}")
        return
    
    if args.train or (not args.export):
        print(f"🔄 Gerando {args.days} dias de dados sintéticos...")
        mood_records, habits = generate_training_data(days=args.days)
        print(f"   ✓ {len(mood_records)} registros de humor")
        
        model = train_model(mood_records, habits)
        
        # Salva modelo
        if HAS_SKLEARN:
            model_path = 'scripts/mood_model.pkl'
            with open(model_path, 'wb') as f:
                pickle.dump(model, f)
            print(f"\n✅ Modelo salvo em: {model_path}")
        
        print("\n" + "=" * 50)
        print("🎉 Treinamento concluído!")
        print("=" * 50)
        
        if args.export:
            print("\n⚠️ Para exportar para TFLite, instale tensorflow:")
            print("   pip install tensorflow")
            print("   E então use: python -c 'import tensorflow as tf; ...'")


if __name__ == '__main__':
    main()
