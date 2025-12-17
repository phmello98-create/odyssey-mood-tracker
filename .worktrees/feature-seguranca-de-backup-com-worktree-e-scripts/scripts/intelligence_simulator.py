#!/usr/bin/env python3
"""
Simulador e Validador do Sistema de Inteligência do Odyssey

Este script simula dados de usuário e testa os algoritmos de:
- Detecção de padrões (temporais, comportamentais)
- Cálculo de correlações (Pearson)
- Previsão de streaks e humor
- Recomendações

Uso:
  python scripts/intelligence_simulator.py [--days 30] [--seed 42]
"""

import argparse
import random
import math
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple
from enum import Enum
import json


class PatternType(Enum):
    TEMPORAL = "temporal"
    BEHAVIORAL = "behavioral"
    CYCLICAL = "cyclical"


class CorrelationStrength(Enum):
    NONE = "none"
    WEAK = "weak"
    MODERATE = "moderate"
    STRONG = "strong"
    VERY_STRONG = "very_strong"


@dataclass
class MoodDataPoint:
    date: datetime
    score: float
    activities: List[str] = field(default_factory=list)


@dataclass
class DailyDataPoint:
    date: datetime
    avg_mood: float
    tasks_completed: int
    habits_completed: int
    activities_done: List[str] = field(default_factory=list)


@dataclass
class UserPattern:
    id: str
    pattern_type: PatternType
    description: str
    strength: float
    data: Dict


@dataclass
class Correlation:
    variable1: str
    variable2: str
    coefficient: float
    p_value: float
    sample_size: int
    strength: CorrelationStrength


# ============ ALGORITMOS DE ANÁLISE ============

def calculate_pearson_correlation(x: List[float], y: List[float]) -> float:
    """Calcula correlação de Pearson entre duas listas."""
    if len(x) != len(y) or len(x) < 3:
        return 0.0
    
    n = len(x)
    sum_x = sum(x)
    sum_y = sum(y)
    sum_xy = sum(x[i] * y[i] for i in range(n))
    sum_x2 = sum(v ** 2 for v in x)
    sum_y2 = sum(v ** 2 for v in y)
    
    numerator = n * sum_xy - sum_x * sum_y
    denominator = math.sqrt((n * sum_x2 - sum_x ** 2) * (n * sum_y2 - sum_y ** 2))
    
    if denominator == 0:
        return 0.0
    
    return numerator / denominator


def calculate_p_value(r: float, n: int) -> float:
    """Calcula p-value aproximado para correlação de Pearson."""
    if n <= 2 or abs(r) >= 1.0:
        return 1.0 if n <= 2 else 0.0
    
    t = r * math.sqrt((n - 2) / (1 - r ** 2))
    
    # Aproximação simplificada
    if abs(t) > 3.5:
        return 0.001
    if abs(t) > 2.5:
        return 0.01
    if abs(t) > 2.0:
        return 0.05
    if abs(t) > 1.5:
        return 0.10
    return 0.20


def classify_correlation_strength(r: float) -> CorrelationStrength:
    """Classifica força da correlação baseada no coeficiente."""
    abs_r = abs(r)
    if abs_r < 0.1:
        return CorrelationStrength.NONE
    if abs_r < 0.3:
        return CorrelationStrength.WEAK
    if abs_r < 0.5:
        return CorrelationStrength.MODERATE
    if abs_r < 0.7:
        return CorrelationStrength.STRONG
    return CorrelationStrength.VERY_STRONG


def linear_regression(x: List[float], y: List[float]) -> Tuple[float, float]:
    """Regressão linear simples. Retorna (slope, intercept)."""
    n = len(x)
    if n == 0:
        return 0.0, 0.0
    
    sum_x = sum(x)
    sum_y = sum(y)
    sum_xy = sum(x[i] * y[i] for i in range(n))
    sum_x2 = sum(v ** 2 for v in x)
    
    denominator = n * sum_x2 - sum_x ** 2
    if denominator == 0:
        return 0.0, sum_y / n if n > 0 else 0.0
    
    slope = (n * sum_xy - sum_x * sum_y) / denominator
    intercept = (sum_y - slope * sum_x) / n
    
    return slope, intercept


def calculate_std_dev(values: List[float], mean: float) -> float:
    """Calcula desvio padrão."""
    if not values:
        return 0.0
    variance = sum((v - mean) ** 2 for v in values) / len(values)
    return math.sqrt(variance)


def moving_average(data: List[float], window: int) -> List[float]:
    """Calcula média móvel."""
    result = []
    for i in range(window - 1, len(data)):
        window_data = data[i - window + 1:i + 1]
        result.append(sum(window_data) / len(window_data))
    return result


# ============ GERADOR DE DADOS SIMULADOS ============

class DataSimulator:
    """Simula dados de usuário com padrões realistas."""
    
    def __init__(self, seed: int = 42):
        random.seed(seed)
        self.activities = [
            "exercicio", "meditacao", "leitura", "trabalho",
            "socializar", "jogos", "natureza", "musica"
        ]
        
    def generate_mood_data(self, days: int = 30) -> List[MoodDataPoint]:
        """
        Gera dados de humor simulados com padrões:
        - Humor melhor às segundas-feiras
        - Humor melhor pela manhã
        - Tendência de melhora ao longo do tempo
        - Correlação positiva com exercício
        """
        data = []
        now = datetime.now()
        
        for i in range(days):
            date = now - timedelta(days=days - 1 - i)
            
            # Base mood (3.0 de média)
            base_mood = 3.0
            
            # Padrão semanal (segunda-feira é melhor)
            weekday_bonus = 0.3 if date.weekday() == 0 else -0.1 * (date.weekday() / 6)
            
            # Padrão horário (manhã é melhor)
            hour = random.randint(6, 22)
            hour_bonus = 0.2 if 6 <= hour <= 11 else -0.1 if hour >= 20 else 0
            
            # Tendência de melhora (slope positivo)
            trend_bonus = 0.01 * i
            
            # Atividades do dia
            day_activities = []
            did_exercise = random.random() < 0.4  # 40% chance de exercício
            if did_exercise:
                day_activities.append("exercicio")
                base_mood += 0.5  # Exercício melhora humor
            
            # Adiciona outras atividades aleatórias
            for act in self.activities[1:]:  # Exclui exercício (já tratado)
                if random.random() < 0.3:
                    day_activities.append(act)
            
            # Ruído aleatório
            noise = random.gauss(0, 0.3)
            
            # Score final (1-5)
            score = base_mood + weekday_bonus + hour_bonus + trend_bonus + noise
            score = max(1.0, min(5.0, score))
            
            data.append(MoodDataPoint(
                date=date.replace(hour=hour),
                score=round(score, 2),
                activities=day_activities
            ))
        
        return data
    
    def generate_habit_data(self, days: int = 30) -> Dict[str, List[bool]]:
        """
        Gera dados de hábitos simulados com padrões:
        - Alguns hábitos têm taxa de conclusão maior em certos dias
        - Padrões de streak realistas
        """
        habits = {
            "meditacao": [],
            "exercicio": [],
            "leitura": [],
            "agua": []
        }
        
        # Padrões de cada hábito
        habit_patterns = {
            "meditacao": {"base_rate": 0.6, "weekday_boost": [1, 2, 3, 4, 5]},  # Melhor em dias úteis
            "exercicio": {"base_rate": 0.4, "weekday_boost": [1, 3, 5]},  # Segunda, Quarta, Sexta
            "leitura": {"base_rate": 0.5, "weekday_boost": [0, 6]},  # Fins de semana
            "agua": {"base_rate": 0.7, "weekday_boost": []},  # Sem padrão específico
        }
        
        now = datetime.now()
        
        for habit_name, pattern in habit_patterns.items():
            for i in range(days):
                date = now - timedelta(days=days - 1 - i)
                weekday = date.weekday()
                
                rate = pattern["base_rate"]
                if weekday in pattern["weekday_boost"]:
                    rate += 0.2
                
                # Streaks tendem a continuar
                if habits[habit_name] and habits[habit_name][-1]:
                    rate += 0.1  # Mais provável de continuar
                
                completed = random.random() < rate
                habits[habit_name].append(completed)
        
        return habits
    
    def generate_task_data(self, days: int = 30) -> List[Dict]:
        """Gera dados de tarefas simulados."""
        tasks = []
        now = datetime.now()
        
        for i in range(days):
            date = now - timedelta(days=days - 1 - i)
            
            # 2-5 tarefas por dia
            num_tasks = random.randint(2, 5)
            
            for j in range(num_tasks):
                # Tarefas criadas pela manhã têm mais chance de ser completadas
                created_hour = random.randint(7, 20)
                completion_rate = 0.8 if created_hour < 12 else 0.5
                
                completed = random.random() < completion_rate
                
                tasks.append({
                    "id": f"task_{i}_{j}",
                    "created_at": date.replace(hour=created_hour),
                    "completed": completed,
                    "completed_at": date.replace(hour=created_hour + 2) if completed else None
                })
        
        return tasks


# ============ ANALISADOR DE PADRÕES ============

class PatternAnalyzer:
    """Detecta padrões nos dados do usuário."""
    
    def detect_day_of_week_pattern(self, mood_data: List[MoodDataPoint]) -> Optional[UserPattern]:
        """Detecta padrão de dia da semana."""
        if len(mood_data) < 7:
            return None
        
        # Agrupa por dia da semana
        by_day: Dict[int, List[float]] = {}
        for point in mood_data:
            day = point.date.weekday()
            if day not in by_day:
                by_day[day] = []
            by_day[day].append(point.score)
        
        if len(by_day) < 5:
            return None
        
        # Calcula média por dia
        avg_by_day = {day: sum(scores) / len(scores) for day, scores in by_day.items()}
        overall_avg = sum(avg_by_day.values()) / len(avg_by_day)
        std_dev = calculate_std_dev(list(avg_by_day.values()), overall_avg)
        
        # Encontra melhor dia
        best_day = max(avg_by_day.items(), key=lambda x: x[1])
        
        # Verifica se é significativo
        if (best_day[1] - overall_avg) > std_dev * 0.5:
            day_names = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]
            improvement = int((best_day[1] - overall_avg) / overall_avg * 100)
            
            return UserPattern(
                id=f"pattern_day_{datetime.now().timestamp()}",
                pattern_type=PatternType.TEMPORAL,
                description=f"Seu humor é {improvement}% melhor às {day_names[best_day[0]]}s",
                strength=min((best_day[1] - overall_avg) / std_dev, 1.0),
                data={"best_day": best_day[0], "avg_by_day": avg_by_day}
            )
        
        return None
    
    def detect_mood_trend(self, mood_data: List[MoodDataPoint]) -> Optional[UserPattern]:
        """Detecta tendência de humor (subindo/caindo)."""
        if len(mood_data) < 7:
            return None
        
        # Ordena por data
        sorted_data = sorted(mood_data, key=lambda x: x.date)
        
        # Pega últimos 14 dias
        recent = sorted_data[-14:] if len(sorted_data) > 14 else sorted_data
        
        # Regressão linear
        x = list(range(len(recent)))
        y = [p.score for p in recent]
        slope, _ = linear_regression([float(i) for i in x], y)
        
        if slope > 0.05:
            return UserPattern(
                id=f"pattern_trend_{datetime.now().timestamp()}",
                pattern_type=PatternType.CYCLICAL,
                description="Seu humor está melhorando nas últimas 2 semanas",
                strength=min(slope * 10, 1.0),
                data={"trend": "rising", "slope": slope}
            )
        elif slope < -0.05:
            return UserPattern(
                id=f"pattern_trend_{datetime.now().timestamp()}",
                pattern_type=PatternType.CYCLICAL,
                description="Seu humor está em queda nas últimas 2 semanas",
                strength=min(abs(slope) * 10, 1.0),
                data={"trend": "falling", "slope": slope}
            )
        
        return None


# ============ ANALISADOR DE CORRELAÇÕES ============

class CorrelationAnalyzer:
    """Calcula correlações entre variáveis."""
    
    def calculate_mood_vs_activity(
        self,
        mood_data: List[MoodDataPoint],
        activity_name: str
    ) -> Optional[Correlation]:
        """Calcula correlação entre humor e uma atividade específica."""
        if len(mood_data) < 14:
            return None
        
        # Prepara dados
        mood_scores = []
        activity_done = []
        
        for point in mood_data:
            mood_scores.append(point.score)
            activity_done.append(1.0 if activity_name in point.activities else 0.0)
        
        r = calculate_pearson_correlation(mood_scores, activity_done)
        
        if abs(r) < 0.3:  # Threshold mínimo
            return None
        
        p_value = calculate_p_value(r, len(mood_data))
        strength = classify_correlation_strength(r)
        
        return Correlation(
            variable1=f"activity_{activity_name}",
            variable2="mood_score",
            coefficient=round(r, 3),
            p_value=round(p_value, 3),
            sample_size=len(mood_data),
            strength=strength
        )


# ============ PREDITOR ============

class Predictor:
    """Faz previsões sobre comportamento futuro."""
    
    def predict_streak_break(
        self,
        habit_name: str,
        last_30_days: List[bool],
        current_streak: int
    ) -> Optional[Dict]:
        """Prediz risco de quebra de streak."""
        if current_streak < 3:
            return None
        
        # Calcula taxa por dia da semana
        now = datetime.now()
        tomorrow = now + timedelta(days=1)
        tomorrow_weekday = tomorrow.weekday()
        
        # Agrupa completions por dia da semana
        by_weekday: Dict[int, List[bool]] = {}
        for i, completed in enumerate(last_30_days):
            date = now - timedelta(days=29 - i)
            weekday = date.weekday()
            if weekday not in by_weekday:
                by_weekday[weekday] = []
            by_weekday[weekday].append(completed)
        
        # Taxa de amanhã
        if tomorrow_weekday in by_weekday:
            completions = by_weekday[tomorrow_weekday]
            tomorrow_rate = sum(completions) / len(completions)
        else:
            tomorrow_rate = 0.5
        
        fail_probability = 1 - tomorrow_rate
        
        if fail_probability < 0.3:
            return None
        
        return {
            "habit": habit_name,
            "probability": round(fail_probability, 2),
            "current_streak": current_streak,
            "tomorrow_rate": round(tomorrow_rate, 2),
            "reasoning": f"Você costuma pular às {['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][tomorrow_weekday]}s"
        }
    
    def predict_mood_tomorrow(
        self,
        mood_data: List[MoodDataPoint],
        patterns: List[UserPattern]
    ) -> Optional[Dict]:
        """Prediz humor para amanhã."""
        if len(mood_data) < 7:
            return None
        
        # Média dos últimos 7 dias
        sorted_data = sorted(mood_data, key=lambda x: x.date)
        recent = sorted_data[-7:]
        avg_recent = sum(p.score for p in recent) / len(recent)
        
        # Tendência
        x = list(range(len(sorted_data)))
        y = [p.score for p in sorted_data]
        slope, _ = linear_regression([float(i) for i in x], y)
        
        predicted_score = avg_recent + slope
        
        if slope > 0.1:
            return {
                "type": "improvement",
                "predicted_score": round(predicted_score, 2),
                "probability": min(0.5 + slope, 0.9),
                "reasoning": "Seu humor está em tendência de alta"
            }
        elif slope < -0.1:
            return {
                "type": "drop",
                "predicted_score": round(predicted_score, 2),
                "probability": min(0.5 + abs(slope), 0.9),
                "reasoning": "Seu humor está em tendência de queda"
            }
        
        return None


# ============ RELATÓRIO ============

def generate_report(
    mood_data: List[MoodDataPoint],
    habits: Dict[str, List[bool]],
    patterns: List[UserPattern],
    correlations: List[Correlation],
    predictions: List[Dict]
):
    """Gera relatório de análise."""
    print("\n" + "=" * 60)
    print("📊 RELATÓRIO DO SISTEMA DE INTELIGÊNCIA")
    print("=" * 60)
    
    # Estatísticas básicas
    print(f"\n📈 ESTATÍSTICAS GERAIS")
    print(f"   • Dias analisados: {len(mood_data)}")
    print(f"   • Média de humor: {sum(p.score for p in mood_data) / len(mood_data):.2f}")
    print(f"   • Padrões detectados: {len(patterns)}")
    print(f"   • Correlações significativas: {len(correlations)}")
    print(f"   • Previsões ativas: {len(predictions)}")
    
    # Padrões
    if patterns:
        print(f"\n🔍 PADRÕES DETECTADOS")
        for p in patterns:
            print(f"   • [{p.pattern_type.value}] {p.description}")
            print(f"     Força: {p.strength:.2f}")
    
    # Correlações
    if correlations:
        print(f"\n🔗 CORRELAÇÕES SIGNIFICATIVAS")
        for c in correlations:
            direction = "↑" if c.coefficient > 0 else "↓"
            print(f"   • {c.variable1} {direction} {c.variable2}")
            print(f"     r={c.coefficient:.3f}, p={c.p_value:.3f} ({c.strength.value})")
    
    # Previsões
    if predictions:
        print(f"\n🔮 PREVISÕES")
        for pred in predictions:
            if "habit" in pred:
                print(f"   ⚠️ Streak de '{pred['habit']}' em risco ({pred['probability']*100:.0f}%)")
                print(f"     {pred['reasoning']}")
            elif "type" in pred:
                emoji = "📈" if pred["type"] == "improvement" else "📉"
                print(f"   {emoji} Humor amanhã: {pred['predicted_score']:.1f}")
                print(f"     {pred['reasoning']}")
    
    print("\n" + "=" * 60)
    print("✅ Análise concluída com sucesso!")
    print("=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(description="Simulador do Sistema de Inteligência")
    parser.add_argument("--days", type=int, default=30, help="Número de dias a simular")
    parser.add_argument("--seed", type=int, default=42, help="Seed para reprodutibilidade")
    parser.add_argument("--json", action="store_true", help="Saída em JSON")
    args = parser.parse_args()
    
    print(f"🧠 Iniciando simulação com {args.days} dias (seed={args.seed})...")
    
    # Gera dados simulados
    simulator = DataSimulator(seed=args.seed)
    mood_data = simulator.generate_mood_data(days=args.days)
    habits = simulator.generate_habit_data(days=args.days)
    tasks = simulator.generate_task_data(days=args.days)
    
    print(f"✓ Dados gerados: {len(mood_data)} registros de humor")
    
    # Análise de padrões
    pattern_analyzer = PatternAnalyzer()
    patterns = []
    
    day_pattern = pattern_analyzer.detect_day_of_week_pattern(mood_data)
    if day_pattern:
        patterns.append(day_pattern)
    
    trend_pattern = pattern_analyzer.detect_mood_trend(mood_data)
    if trend_pattern:
        patterns.append(trend_pattern)
    
    print(f"✓ Padrões detectados: {len(patterns)}")
    
    # Análise de correlações
    correlation_analyzer = CorrelationAnalyzer()
    correlations = []
    
    for activity in simulator.activities:
        corr = correlation_analyzer.calculate_mood_vs_activity(mood_data, activity)
        if corr:
            correlations.append(corr)
    
    print(f"✓ Correlações calculadas: {len(correlations)}")
    
    # Previsões
    predictor = Predictor()
    predictions = []
    
    for habit_name, completions in habits.items():
        current_streak = 0
        for completed in reversed(completions):
            if completed:
                current_streak += 1
            else:
                break
        
        pred = predictor.predict_streak_break(habit_name, completions, current_streak)
        if pred:
            predictions.append(pred)
    
    mood_pred = predictor.predict_mood_tomorrow(mood_data, patterns)
    if mood_pred:
        predictions.append(mood_pred)
    
    print(f"✓ Previsões geradas: {len(predictions)}")
    
    # Relatório
    if args.json:
        output = {
            "days_analyzed": args.days,
            "mood_records": len(mood_data),
            "avg_mood": round(sum(p.score for p in mood_data) / len(mood_data), 2),
            "patterns": [
                {"type": p.pattern_type.value, "description": p.description, "strength": p.strength}
                for p in patterns
            ],
            "correlations": [
                {"var1": c.variable1, "var2": c.variable2, "r": c.coefficient, "strength": c.strength.value}
                for c in correlations
            ],
            "predictions": predictions
        }
        print(json.dumps(output, indent=2))
    else:
        generate_report(mood_data, habits, patterns, correlations, predictions)


if __name__ == "__main__":
    main()
