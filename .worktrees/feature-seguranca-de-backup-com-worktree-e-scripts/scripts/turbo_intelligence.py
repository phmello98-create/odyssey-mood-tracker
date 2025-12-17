#!/usr/bin/env python3
"""
🚀 TURBO INTELLIGENCE ENGINE

Implementa algoritmos avançados para turbinar o sistema de inteligência:

1. DETECÇÃO DE ANOMALIAS (Z-Score, IQR)
   - Detecta dias atípicos de humor
   - Identifica outliers que merecem investigação

2. ANÁLISE DE SEQUÊNCIAS (N-grams de comportamento)
   - Detecta sequências de atividades que levam a bom/mau humor
   - Ex: "Exercício → Meditação → Bom humor"

3. CLUSTERING DE DIAS (K-Means simplificado)
   - Agrupa dias similares
   - Identifica "tipos de dia" (produtivo, relaxante, difícil)

4. PREVISÃO AVANÇADA (Média Móvel Exponencial + Sazonalidade)
   - EMA para tendências de curto prazo
   - Detecção de ciclos semanais/mensais

5. SISTEMA DE SCORING DE INSIGHTS
   - Priorização inteligente de insights
   - Evita insights repetitivos

6. ANÁLISE DE CAUSALIDADE (Granger-like simplificado)
   - Tenta inferir se A causa B (não só correlação)

Uso:
  python scripts/turbo_intelligence.py
"""

import math
import random
from datetime import datetime, timedelta
from typing import List, Dict, Tuple, Optional, Set
from dataclasses import dataclass, field
from collections import Counter, defaultdict
from enum import Enum
import json


# ============ MODELOS DE DADOS ============

@dataclass
class MoodRecord:
    date: datetime
    score: float  # 1-5
    activities: List[str] = field(default_factory=list)
    note: str = ""


@dataclass
class DayProfile:
    date: datetime
    avg_mood: float
    tasks_completed: int
    habits_completed: int
    activities: List[str]
    focus_minutes: int
    cluster: Optional[str] = None


@dataclass
class Anomaly:
    date: datetime
    score: float
    expected_score: float
    z_score: float
    direction: str  # 'high' or 'low'
    possible_causes: List[str]


@dataclass
class BehaviorSequence:
    sequence: Tuple[str, ...]
    outcome: str  # 'positive', 'negative', 'neutral'
    frequency: int
    avg_mood_after: float
    confidence: float


class DayType(Enum):
    PRODUCTIVE = "productive"
    RELAXED = "relaxed"
    DIFFICULT = "difficult"
    BALANCED = "balanced"
    ENERGETIC = "energetic"


# ============ 1. DETECÇÃO DE ANOMALIAS ============

class AnomalyDetector:
    """Detecta dias atípicos usando Z-Score e IQR."""
    
    def __init__(self, sensitivity: float = 2.0):
        self.sensitivity = sensitivity  # Z-score threshold
    
    def detect_zscore_anomalies(
        self,
        mood_data: List[MoodRecord]
    ) -> List[Anomaly]:
        """Detecta anomalias usando Z-Score."""
        if len(mood_data) < 7:
            return []
        
        scores = [m.score for m in mood_data]
        mean = sum(scores) / len(scores)
        std = math.sqrt(sum((s - mean) ** 2 for s in scores) / len(scores))
        
        if std == 0:
            return []
        
        anomalies = []
        for record in mood_data:
            z = (record.score - mean) / std
            
            if abs(z) >= self.sensitivity:
                anomalies.append(Anomaly(
                    date=record.date,
                    score=record.score,
                    expected_score=mean,
                    z_score=z,
                    direction='high' if z > 0 else 'low',
                    possible_causes=record.activities if record.activities else ['unknown']
                ))
        
        return anomalies
    
    def detect_iqr_anomalies(
        self,
        mood_data: List[MoodRecord]
    ) -> List[Anomaly]:
        """Detecta anomalias usando IQR (mais robusto a outliers)."""
        if len(mood_data) < 7:
            return []
        
        scores = sorted([m.score for m in mood_data])
        n = len(scores)
        
        q1 = scores[n // 4]
        q3 = scores[3 * n // 4]
        iqr = q3 - q1
        
        lower_bound = q1 - 1.5 * iqr
        upper_bound = q3 + 1.5 * iqr
        
        anomalies = []
        mean = sum(scores) / n
        std = math.sqrt(sum((s - mean) ** 2 for s in scores) / n) or 1
        
        for record in mood_data:
            if record.score < lower_bound or record.score > upper_bound:
                z = (record.score - mean) / std
                anomalies.append(Anomaly(
                    date=record.date,
                    score=record.score,
                    expected_score=mean,
                    z_score=z,
                    direction='high' if record.score > upper_bound else 'low',
                    possible_causes=record.activities if record.activities else ['unknown']
                ))
        
        return anomalies
    
    def analyze_anomaly_causes(
        self,
        anomalies: List[Anomaly],
        all_records: List[MoodRecord]
    ) -> Dict[str, Dict]:
        """Analisa causas comuns de anomalias."""
        # Atividades associadas a anomalias positivas
        positive_activities = Counter()
        negative_activities = Counter()
        
        for anomaly in anomalies:
            for cause in anomaly.possible_causes:
                if anomaly.direction == 'high':
                    positive_activities[cause] += 1
                else:
                    negative_activities[cause] += 1
        
        # Frequência base de cada atividade
        activity_freq = Counter()
        for record in all_records:
            for act in record.activities:
                activity_freq[act] += 1
        
        # Calcula lift (quanto mais comum em anomalias vs base)
        positive_lift = {}
        negative_lift = {}
        total_records = len(all_records)
        total_positive = sum(1 for a in anomalies if a.direction == 'high')
        total_negative = sum(1 for a in anomalies if a.direction == 'low')
        
        for act, freq in activity_freq.items():
            base_rate = freq / total_records
            
            if total_positive > 0 and act in positive_activities:
                anomaly_rate = positive_activities[act] / total_positive
                positive_lift[act] = anomaly_rate / base_rate if base_rate > 0 else 0
            
            if total_negative > 0 and act in negative_activities:
                anomaly_rate = negative_activities[act] / total_negative
                negative_lift[act] = anomaly_rate / base_rate if base_rate > 0 else 0
        
        return {
            'positive_factors': dict(sorted(positive_lift.items(), key=lambda x: -x[1])[:5]),
            'negative_factors': dict(sorted(negative_lift.items(), key=lambda x: -x[1])[:5]),
        }


# ============ 2. ANÁLISE DE SEQUÊNCIAS ============

class SequenceAnalyzer:
    """Analisa sequências de comportamento (N-grams)."""
    
    def __init__(self, n: int = 3):
        self.n = n  # Tamanho do n-gram
    
    def extract_activity_sequences(
        self,
        mood_data: List[MoodRecord],
        window_hours: int = 48
    ) -> List[BehaviorSequence]:
        """Extrai sequências de atividades e seus resultados."""
        # Ordena por data
        sorted_data = sorted(mood_data, key=lambda x: x.date)
        
        sequences: Dict[Tuple, List[float]] = defaultdict(list)
        
        for i in range(len(sorted_data) - self.n):
            window = sorted_data[i:i + self.n + 1]
            
            # Verifica se está dentro da janela de tempo
            if (window[-1].date - window[0].date).total_seconds() > window_hours * 3600:
                continue
            
            # Extrai sequência de atividades principais
            seq_activities = []
            for record in window[:-1]:
                if record.activities:
                    seq_activities.append(record.activities[0])  # Primeira atividade
                else:
                    seq_activities.append('none')
            
            seq_tuple = tuple(seq_activities)
            outcome_score = window[-1].score
            sequences[seq_tuple].append(outcome_score)
        
        # Converte para BehaviorSequence
        result = []
        for seq, scores in sequences.items():
            if len(scores) < 2:  # Precisa de pelo menos 2 ocorrências
                continue
            
            avg_score = sum(scores) / len(scores)
            outcome = 'positive' if avg_score >= 4 else ('negative' if avg_score <= 2 else 'neutral')
            
            result.append(BehaviorSequence(
                sequence=seq,
                outcome=outcome,
                frequency=len(scores),
                avg_mood_after=avg_score,
                confidence=min(len(scores) / 10, 1.0)  # Mais ocorrências = mais confiança
            ))
        
        # Ordena por impacto
        result.sort(key=lambda x: abs(x.avg_mood_after - 3) * x.confidence, reverse=True)
        return result[:20]  # Top 20
    
    def find_best_sequences(
        self,
        sequences: List[BehaviorSequence],
        min_confidence: float = 0.3
    ) -> Dict[str, List[BehaviorSequence]]:
        """Encontra as melhores e piores sequências."""
        filtered = [s for s in sequences if s.confidence >= min_confidence]
        
        best = [s for s in filtered if s.outcome == 'positive']
        worst = [s for s in filtered if s.outcome == 'negative']
        
        return {
            'best_sequences': sorted(best, key=lambda x: -x.avg_mood_after)[:5],
            'worst_sequences': sorted(worst, key=lambda x: x.avg_mood_after)[:5],
        }


# ============ 3. CLUSTERING DE DIAS ============

class DayClusterer:
    """Agrupa dias similares usando K-Means simplificado."""
    
    def __init__(self, n_clusters: int = 4):
        self.n_clusters = n_clusters
        self.centroids: List[List[float]] = []
    
    def _extract_features(self, day: DayProfile) -> List[float]:
        """Extrai features numéricas de um dia."""
        return [
            day.avg_mood / 5,  # Normalizado 0-1
            min(day.tasks_completed / 5, 1),  # Até 5 tarefas = 1
            min(day.habits_completed / 4, 1),  # Até 4 hábitos = 1
            min(day.focus_minutes / 120, 1),  # Até 2h = 1
            len(day.activities) / 5,  # Número de atividades
        ]
    
    def _distance(self, a: List[float], b: List[float]) -> float:
        """Distância euclidiana."""
        return math.sqrt(sum((x - y) ** 2 for x, y in zip(a, b)))
    
    def fit(self, days: List[DayProfile], max_iterations: int = 50) -> None:
        """Treina o clustering."""
        if len(days) < self.n_clusters:
            return
        
        features = [self._extract_features(d) for d in days]
        
        # Inicializa centroids aleatoriamente
        random.seed(42)
        indices = random.sample(range(len(features)), self.n_clusters)
        self.centroids = [features[i].copy() for i in indices]
        
        for _ in range(max_iterations):
            # Assign clusters
            clusters: Dict[int, List[List[float]]] = defaultdict(list)
            for f in features:
                distances = [self._distance(f, c) for c in self.centroids]
                cluster_idx = distances.index(min(distances))
                clusters[cluster_idx].append(f)
            
            # Update centroids
            new_centroids = []
            for i in range(self.n_clusters):
                if clusters[i]:
                    centroid = [
                        sum(f[j] for f in clusters[i]) / len(clusters[i])
                        for j in range(len(features[0]))
                    ]
                    new_centroids.append(centroid)
                else:
                    new_centroids.append(self.centroids[i])
            
            # Check convergence
            if new_centroids == self.centroids:
                break
            self.centroids = new_centroids
    
    def predict(self, day: DayProfile) -> str:
        """Prediz o tipo de dia."""
        if not self.centroids:
            return DayType.BALANCED.value
        
        features = self._extract_features(day)
        distances = [self._distance(features, c) for c in self.centroids]
        cluster_idx = distances.index(min(distances))
        
        # Interpreta o cluster baseado no centroid
        centroid = self.centroids[cluster_idx]
        mood, tasks, habits, focus, activities = centroid
        
        if mood >= 0.7 and (tasks >= 0.6 or habits >= 0.6):
            return DayType.PRODUCTIVE.value
        elif mood >= 0.7 and focus < 0.3:
            return DayType.RELAXED.value
        elif mood <= 0.4:
            return DayType.DIFFICULT.value
        elif focus >= 0.7:
            return DayType.ENERGETIC.value
        else:
            return DayType.BALANCED.value
    
    def get_cluster_profiles(self) -> List[Dict]:
        """Retorna perfil de cada cluster."""
        profiles = []
        for i, centroid in enumerate(self.centroids):
            mood, tasks, habits, focus, activities = centroid
            
            profiles.append({
                'cluster': i,
                'avg_mood': mood * 5,
                'avg_tasks': tasks * 5,
                'avg_habits': habits * 4,
                'avg_focus_hours': focus * 2,
                'avg_activities': activities * 5,
                'type': self._interpret_centroid(centroid)
            })
        
        return profiles
    
    def _interpret_centroid(self, centroid: List[float]) -> str:
        mood, tasks, habits, focus, activities = centroid
        
        if mood >= 0.7 and (tasks >= 0.6 or habits >= 0.6):
            return "Dia Produtivo 🚀"
        elif mood >= 0.7 and focus < 0.3:
            return "Dia Relaxante 🌴"
        elif mood <= 0.4:
            return "Dia Difícil 😔"
        elif focus >= 0.7:
            return "Dia Energético ⚡"
        else:
            return "Dia Equilibrado ⚖️"


# ============ 4. PREVISÃO AVANÇADA ============

class AdvancedPredictor:
    """Previsões avançadas com EMA e sazonalidade."""
    
    def __init__(self, alpha: float = 0.3):
        self.alpha = alpha  # Fator de suavização EMA
    
    def exponential_moving_average(
        self,
        values: List[float],
        alpha: Optional[float] = None
    ) -> List[float]:
        """Calcula EMA (Exponential Moving Average)."""
        if not values:
            return []
        
        a = alpha or self.alpha
        ema = [values[0]]
        
        for i in range(1, len(values)):
            ema.append(a * values[i] + (1 - a) * ema[-1])
        
        return ema
    
    def detect_weekly_seasonality(
        self,
        mood_data: List[MoodRecord]
    ) -> Dict[int, float]:
        """Detecta padrão semanal (sazonalidade)."""
        by_weekday: Dict[int, List[float]] = defaultdict(list)
        
        for record in mood_data:
            by_weekday[record.date.weekday()].append(record.score)
        
        # Média por dia da semana
        avg_by_day = {
            day: sum(scores) / len(scores)
            for day, scores in by_weekday.items()
            if scores
        }
        
        # Calcula desvio da média geral
        overall_avg = sum(m.score for m in mood_data) / len(mood_data)
        seasonality = {
            day: avg - overall_avg
            for day, avg in avg_by_day.items()
        }
        
        return seasonality
    
    def predict_next_days(
        self,
        mood_data: List[MoodRecord],
        days_ahead: int = 7
    ) -> List[Dict]:
        """Prediz humor para os próximos dias."""
        if len(mood_data) < 14:
            return []
        
        sorted_data = sorted(mood_data, key=lambda x: x.date)
        scores = [m.score for m in sorted_data]
        
        # Calcula EMA
        ema = self.exponential_moving_average(scores)
        current_ema = ema[-1]
        
        # Calcula tendência (slope dos últimos 7 dias)
        recent = scores[-7:]
        x = list(range(len(recent)))
        slope = self._linear_slope(x, recent)
        
        # Detecta sazonalidade
        seasonality = self.detect_weekly_seasonality(sorted_data)
        
        # Gera previsões
        predictions = []
        last_date = sorted_data[-1].date
        
        for i in range(1, days_ahead + 1):
            pred_date = last_date + timedelta(days=i)
            weekday = pred_date.weekday()
            
            # Base: EMA + tendência + sazonalidade
            base_pred = current_ema + (slope * i)
            seasonal_adj = seasonality.get(weekday, 0)
            final_pred = base_pred + seasonal_adj
            
            # Clamp entre 1-5
            final_pred = max(1, min(5, final_pred))
            
            # Confiança diminui com distância
            confidence = max(0.3, 1 - (i * 0.1))
            
            predictions.append({
                'date': pred_date.strftime('%Y-%m-%d'),
                'weekday': ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][weekday],
                'predicted_score': round(final_pred, 2),
                'confidence': round(confidence, 2),
                'components': {
                    'ema': round(current_ema, 2),
                    'trend': round(slope * i, 2),
                    'seasonality': round(seasonal_adj, 2),
                }
            })
        
        return predictions
    
    def _linear_slope(self, x: List[float], y: List[float]) -> float:
        """Calcula slope de regressão linear."""
        n = len(x)
        if n == 0:
            return 0
        
        sum_x = sum(x)
        sum_y = sum(y)
        sum_xy = sum(x[i] * y[i] for i in range(n))
        sum_x2 = sum(xi ** 2 for xi in x)
        
        denom = n * sum_x2 - sum_x ** 2
        if denom == 0:
            return 0
        
        return (n * sum_xy - sum_x * sum_y) / denom


# ============ 5. SISTEMA DE SCORING ============

class InsightScorer:
    """Pontua e prioriza insights para evitar repetição."""
    
    def __init__(self):
        self.shown_insights: Set[str] = set()
        self.insight_cooldown: Dict[str, datetime] = {}
    
    def score_insight(
        self,
        insight_type: str,
        confidence: float,
        novelty: float,  # 0-1: quanto é novo
        actionability: float,  # 0-1: quanto é acionável
        relevance: float,  # 0-1: relevância temporal
    ) -> float:
        """Calcula score de um insight."""
        # Pesos
        weights = {
            'confidence': 0.25,
            'novelty': 0.30,
            'actionability': 0.25,
            'relevance': 0.20,
        }
        
        # Penalidade se já mostrado recentemente
        cooldown_penalty = 0
        if insight_type in self.insight_cooldown:
            hours_since = (datetime.now() - self.insight_cooldown[insight_type]).total_seconds() / 3600
            if hours_since < 24:
                cooldown_penalty = 0.5 * (1 - hours_since / 24)
        
        base_score = (
            weights['confidence'] * confidence +
            weights['novelty'] * novelty +
            weights['actionability'] * actionability +
            weights['relevance'] * relevance
        )
        
        return max(0, base_score - cooldown_penalty)
    
    def rank_insights(
        self,
        insights: List[Dict]
    ) -> List[Dict]:
        """Rankeia insights por score."""
        for insight in insights:
            insight['final_score'] = self.score_insight(
                insight_type=insight.get('type', 'unknown'),
                confidence=insight.get('confidence', 0.5),
                novelty=insight.get('novelty', 0.5),
                actionability=insight.get('actionability', 0.5),
                relevance=insight.get('relevance', 0.5),
            )
        
        return sorted(insights, key=lambda x: -x['final_score'])
    
    def mark_shown(self, insight_type: str) -> None:
        """Marca insight como mostrado."""
        self.shown_insights.add(insight_type)
        self.insight_cooldown[insight_type] = datetime.now()


# ============ 6. CAUSALIDADE SIMPLIFICADA ============

class CausalityAnalyzer:
    """Tenta inferir causalidade (não só correlação)."""
    
    def granger_like_test(
        self,
        cause_series: List[float],
        effect_series: List[float],
        lag: int = 1
    ) -> Dict:
        """
        Teste simplificado tipo Granger.
        Verifica se valores passados de X ajudam a prever Y.
        """
        if len(cause_series) != len(effect_series) or len(cause_series) < lag + 5:
            return {'significant': False, 'reason': 'insufficient_data'}
        
        n = len(effect_series)
        
        # Modelo 1: Y previsto só por Y passado
        y_prev = effect_series[:-lag]
        y_actual = effect_series[lag:]
        
        error_baseline = sum((y_actual[i] - y_prev[i]) ** 2 for i in range(len(y_actual)))
        
        # Modelo 2: Y previsto por Y passado + X passado
        x_prev = cause_series[:-lag]
        
        # Regressão simples: y = a*y_prev + b*x_prev
        # Simplificação: usamos média ponderada
        alpha = 0.5
        y_pred_enhanced = [
            alpha * y_prev[i] + (1-alpha) * x_prev[i]
            for i in range(len(y_actual))
        ]
        
        error_enhanced = sum((y_actual[i] - y_pred_enhanced[i]) ** 2 for i in range(len(y_actual)))
        
        # F-like statistic simplificada
        improvement = (error_baseline - error_enhanced) / error_baseline if error_baseline > 0 else 0
        
        return {
            'significant': improvement > 0.1,
            'improvement': round(improvement * 100, 1),
            'interpretation': f"Adicionar {lag} dia(s) de lag melhora previsão em {improvement*100:.1f}%"
        }
    
    def analyze_activity_causality(
        self,
        mood_data: List[MoodRecord],
        activity: str,
        lag_days: int = 1
    ) -> Dict:
        """Analisa se atividade causa melhora no humor (com lag)."""
        sorted_data = sorted(mood_data, key=lambda x: x.date)
        
        # Cria séries
        activity_series = []
        mood_series = []
        
        for record in sorted_data:
            activity_series.append(1.0 if activity in record.activities else 0.0)
            mood_series.append(record.score)
        
        return self.granger_like_test(activity_series, mood_series, lag=lag_days)


# ============ GERADOR DE DADOS DE TESTE ============

def generate_realistic_data(days: int = 60, seed: int = 42) -> Tuple[List[MoodRecord], List[DayProfile]]:
    """Gera dados realistas para testes."""
    random.seed(seed)
    
    activities = ['exercicio', 'meditacao', 'leitura', 'trabalho', 'socializar', 'natureza']
    
    mood_records = []
    day_profiles = []
    now = datetime.now()
    
    # Padrões embutidos:
    # - Segunda é melhor
    # - Exercício melhora humor no dia seguinte
    # - Ciclo semanal
    
    prev_had_exercise = False
    
    for i in range(days):
        date = now - timedelta(days=days - 1 - i)
        weekday = date.weekday()
        
        # Base mood com sazonalidade semanal
        base = 3.0
        base += 0.3 if weekday == 0 else 0  # Segunda melhor
        base -= 0.2 if weekday == 2 else 0  # Quarta pior
        base += 0.2 if weekday >= 5 else 0  # Fim de semana melhor
        
        # Efeito de exercício do dia anterior
        if prev_had_exercise:
            base += 0.4
        
        # Tendência de melhora ao longo do tempo
        base += i * 0.005
        
        # Atividades do dia
        day_activities = []
        did_exercise = random.random() < 0.35
        if did_exercise:
            day_activities.append('exercicio')
            base += 0.3  # Efeito imediato também
        
        for act in activities[1:]:
            if random.random() < 0.25:
                day_activities.append(act)
        
        # Ruído
        noise = random.gauss(0, 0.4)
        score = max(1, min(5, base + noise))
        
        mood_records.append(MoodRecord(
            date=date,
            score=round(score, 2),
            activities=day_activities,
        ))
        
        # Day profile
        tasks = random.randint(0, 6)
        habits = random.randint(0, 4)
        focus = random.randint(0, 180)
        
        day_profiles.append(DayProfile(
            date=date,
            avg_mood=score,
            tasks_completed=tasks,
            habits_completed=habits,
            activities=day_activities,
            focus_minutes=focus,
        ))
        
        prev_had_exercise = did_exercise
    
    return mood_records, day_profiles


# ============ RELATÓRIO COMPLETO ============

def run_turbo_analysis():
    """Executa análise turbo completa."""
    print("\n" + "=" * 70)
    print("🚀 TURBO INTELLIGENCE ENGINE - ANÁLISE AVANÇADA")
    print("=" * 70)
    
    # Gera dados
    print("\n📊 Gerando dados de teste...")
    mood_data, day_profiles = generate_realistic_data(days=60)
    print(f"   ✓ {len(mood_data)} registros de humor gerados")
    
    # 1. Detecção de Anomalias
    print("\n🔍 1. DETECÇÃO DE ANOMALIAS")
    print("-" * 50)
    detector = AnomalyDetector(sensitivity=1.5)
    anomalies = detector.detect_zscore_anomalies(mood_data)
    print(f"   Anomalias detectadas: {len(anomalies)}")
    for a in anomalies[:3]:
        print(f"   • {a.date.strftime('%d/%m')} - Score: {a.score:.1f} (Z={a.z_score:.2f}, {a.direction})")
    
    causes = detector.analyze_anomaly_causes(anomalies, mood_data)
    if causes['positive_factors']:
        print(f"   Fatores positivos: {list(causes['positive_factors'].keys())[:3]}")
    if causes['negative_factors']:
        print(f"   Fatores negativos: {list(causes['negative_factors'].keys())[:3]}")
    
    # 2. Análise de Sequências
    print("\n🔗 2. ANÁLISE DE SEQUÊNCIAS")
    print("-" * 50)
    seq_analyzer = SequenceAnalyzer(n=2)
    sequences = seq_analyzer.extract_activity_sequences(mood_data)
    best_worst = seq_analyzer.find_best_sequences(sequences)
    
    print("   Melhores sequências:")
    for s in best_worst['best_sequences'][:2]:
        print(f"   • {' → '.join(s.sequence)} → Humor {s.avg_mood_after:.1f}")
    
    print("   Piores sequências:")
    for s in best_worst['worst_sequences'][:2]:
        print(f"   • {' → '.join(s.sequence)} → Humor {s.avg_mood_after:.1f}")
    
    # 3. Clustering de Dias
    print("\n📁 3. CLUSTERING DE DIAS")
    print("-" * 50)
    clusterer = DayClusterer(n_clusters=4)
    clusterer.fit(day_profiles)
    
    profiles = clusterer.get_cluster_profiles()
    for p in profiles:
        print(f"   Cluster {p['cluster']}: {p['type']} (Humor médio: {p['avg_mood']:.1f})")
    
    # 4. Previsão Avançada
    print("\n🔮 4. PREVISÃO AVANÇADA (próximos 5 dias)")
    print("-" * 50)
    predictor = AdvancedPredictor(alpha=0.3)
    predictions = predictor.predict_next_days(mood_data, days_ahead=5)
    
    for p in predictions:
        conf_bar = "█" * int(p['confidence'] * 10)
        print(f"   {p['weekday']} {p['date']}: {p['predicted_score']:.1f} ({conf_bar})")
    
    # 5. Análise de Causalidade
    print("\n⚡ 5. ANÁLISE DE CAUSALIDADE")
    print("-" * 50)
    causality = CausalityAnalyzer()
    
    exercise_causality = causality.analyze_activity_causality(mood_data, 'exercicio', lag_days=1)
    print(f"   Exercício → Humor (lag 1 dia):")
    print(f"   {exercise_causality['interpretation']}")
    print(f"   Significativo: {'✓' if exercise_causality['significant'] else '✗'}")
    
    # 6. Scoring de Insights
    print("\n⭐ 6. RANKING DE INSIGHTS")
    print("-" * 50)
    scorer = InsightScorer()
    
    sample_insights = [
        {'type': 'pattern', 'title': 'Segunda é seu melhor dia', 'confidence': 0.8, 'novelty': 0.9, 'actionability': 0.3, 'relevance': 0.7},
        {'type': 'correlation', 'title': 'Exercício melhora humor', 'confidence': 0.9, 'novelty': 0.5, 'actionability': 0.9, 'relevance': 0.8},
        {'type': 'prediction', 'title': 'Streak em risco amanhã', 'confidence': 0.6, 'novelty': 1.0, 'actionability': 1.0, 'relevance': 1.0},
        {'type': 'anomaly', 'title': 'Dia atípico detectado', 'confidence': 0.7, 'novelty': 0.8, 'actionability': 0.4, 'relevance': 0.5},
    ]
    
    ranked = scorer.rank_insights(sample_insights)
    for i, insight in enumerate(ranked, 1):
        print(f"   {i}. [{insight['final_score']:.2f}] {insight['title']}")
    
    print("\n" + "=" * 70)
    print("✅ Análise turbo concluída!")
    print("=" * 70 + "\n")
    
    return {
        'anomalies': len(anomalies),
        'sequences': len(sequences),
        'predictions': predictions,
        'causality': exercise_causality,
    }


if __name__ == "__main__":
    run_turbo_analysis()
