#!/usr/bin/env python3
"""
🏥 HEALTH SCORE ANALYZER

Calcula um "Health Score" unificado combinando:
- Humor (média, tendência, volatilidade)
- Hábitos (taxa de conclusão, streaks)
- Produtividade (tarefas, foco)
- Consistência (regularidade dos registros)

Gera diagnóstico detalhado e recomendações.

Uso:
  python scripts/health_score_analyzer.py [--json input.json]
  python scripts/health_score_analyzer.py --demo
"""

import argparse
import json
import math
import random
from datetime import datetime, timedelta
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
from enum import Enum


class HealthLevel(Enum):
    EXCELLENT = "excellent"
    GOOD = "good"
    MODERATE = "moderate"
    NEEDS_ATTENTION = "needs_attention"
    CRITICAL = "critical"


@dataclass
class DimensionScore:
    name: str
    score: float  # 0-100
    weight: float
    level: HealthLevel
    factors: Dict[str, float]
    recommendations: List[str]


@dataclass
class HealthReport:
    overall_score: float
    level: HealthLevel
    dimensions: List[DimensionScore]
    top_strengths: List[str]
    top_weaknesses: List[str]
    priority_actions: List[str]
    trend: str  # 'improving', 'stable', 'declining'


class HealthScoreAnalyzer:
    """Analisa e calcula Health Score unificado."""
    
    def __init__(self):
        # Pesos das dimensões
        self.weights = {
            'mood': 0.35,
            'habits': 0.25,
            'productivity': 0.20,
            'consistency': 0.20,
        }
    
    def analyze(
        self,
        mood_records: List[Dict],
        habits: List[Dict],
        tasks: List[Dict],
        days: int = 30,
    ) -> HealthReport:
        """Executa análise completa e retorna relatório."""
        
        # Calcula cada dimensão
        mood_score = self._analyze_mood(mood_records)
        habits_score = self._analyze_habits(habits, days)
        productivity_score = self._analyze_productivity(tasks)
        consistency_score = self._analyze_consistency(mood_records, days)
        
        dimensions = [mood_score, habits_score, productivity_score, consistency_score]
        
        # Calcula score geral
        overall = sum(d.score * d.weight for d in dimensions)
        level = self._score_to_level(overall)
        
        # Identifica pontos fortes e fracos
        sorted_dims = sorted(dimensions, key=lambda d: d.score, reverse=True)
        strengths = [d.name for d in sorted_dims if d.score >= 70][:2]
        weaknesses = [d.name for d in sorted_dims if d.score < 50][:2]
        
        # Gera ações prioritárias
        priority_actions = []
        for dim in sorted_dims:
            if dim.score < 60 and dim.recommendations:
                priority_actions.append(dim.recommendations[0])
        priority_actions = priority_actions[:3]
        
        # Determina tendência
        trend = self._calculate_trend(mood_records)
        
        return HealthReport(
            overall_score=round(overall, 1),
            level=level,
            dimensions=dimensions,
            top_strengths=strengths,
            top_weaknesses=weaknesses,
            priority_actions=priority_actions,
            trend=trend,
        )
    
    def _analyze_mood(self, records: List[Dict]) -> DimensionScore:
        """Analisa dimensão de humor."""
        if not records:
            return self._empty_dimension('Humor', self.weights['mood'])
        
        scores = [r['score'] for r in records]
        
        # Fatores
        avg_mood = sum(scores) / len(scores)
        avg_normalized = (avg_mood - 1) / 4 * 100  # 1-5 -> 0-100
        
        # Volatilidade (penaliza instabilidade)
        std_dev = math.sqrt(sum((s - avg_mood) ** 2 for s in scores) / len(scores))
        cv = std_dev / avg_mood if avg_mood > 0 else 0
        stability_score = max(0, 100 - cv * 200)
        
        # Tendência recente
        if len(scores) >= 7:
            recent = scores[-7:]
            older = scores[:7] if len(scores) >= 14 else scores[:len(scores)//2]
            trend_diff = (sum(recent) / len(recent)) - (sum(older) / len(older))
            trend_score = 50 + trend_diff * 25  # -2 a +2 -> 0 a 100
            trend_score = max(0, min(100, trend_score))
        else:
            trend_score = 50
        
        # Score final ponderado
        final_score = (
            avg_normalized * 0.5 +
            stability_score * 0.25 +
            trend_score * 0.25
        )
        
        # Recomendações
        recommendations = []
        if avg_normalized < 50:
            recommendations.append("Registre atividades que melhoram seu humor (exercício, socializar)")
        if stability_score < 50:
            recommendations.append("Tente manter rotinas consistentes para estabilizar o humor")
        if trend_score < 40:
            recommendations.append("Atenção: seu humor está em tendência de queda")
        
        return DimensionScore(
            name='Humor',
            score=round(final_score, 1),
            weight=self.weights['mood'],
            level=self._score_to_level(final_score),
            factors={
                'média': round(avg_normalized, 1),
                'estabilidade': round(stability_score, 1),
                'tendência': round(trend_score, 1),
            },
            recommendations=recommendations,
        )
    
    def _analyze_habits(self, habits: List[Dict], days: int) -> DimensionScore:
        """Analisa dimensão de hábitos."""
        if not habits:
            return self._empty_dimension('Hábitos', self.weights['habits'])
        
        # Taxa geral de conclusão
        total_possible = len(habits) * days
        total_completed = sum(len(h.get('completions', [])) for h in habits)
        completion_rate = (total_completed / total_possible * 100) if total_possible > 0 else 0
        
        # Streaks ativos
        active_streaks = sum(1 for h in habits if h.get('current_streak', 0) > 0)
        streak_rate = (active_streaks / len(habits) * 100) if habits else 0
        
        # Melhor streak
        best_streak = max((h.get('current_streak', 0) for h in habits), default=0)
        streak_bonus = min(best_streak * 5, 30)  # Até 30 pontos bonus
        
        # Score final
        final_score = min(100, completion_rate * 0.6 + streak_rate * 0.3 + streak_bonus * 0.1)
        
        # Recomendações
        recommendations = []
        if completion_rate < 40:
            recommendations.append("Comece com apenas 1-2 hábitos simples")
        if streak_rate < 30:
            recommendations.append("Foque em manter pelo menos um hábito consistente")
        if active_streaks == 0:
            recommendations.append("Complete um hábito hoje para iniciar um novo streak!")
        
        return DimensionScore(
            name='Hábitos',
            score=round(final_score, 1),
            weight=self.weights['habits'],
            level=self._score_to_level(final_score),
            factors={
                'taxa_conclusão': round(completion_rate, 1),
                'streaks_ativos': round(streak_rate, 1),
                'melhor_streak': best_streak,
            },
            recommendations=recommendations,
        )
    
    def _analyze_productivity(self, tasks: List[Dict]) -> DimensionScore:
        """Analisa dimensão de produtividade."""
        if not tasks:
            return self._empty_dimension('Produtividade', self.weights['productivity'])
        
        completed = [t for t in tasks if t.get('completed')]
        completion_rate = len(completed) / len(tasks) * 100
        
        # Tarefas por dia (produtividade bruta)
        if tasks:
            dates = set()
            for t in tasks:
                try:
                    date_str = t.get('created_at', '')[:10]
                    if date_str:
                        dates.add(date_str)
                except:
                    pass
            
            tasks_per_day = len(completed) / len(dates) if dates else 0
            volume_score = min(tasks_per_day * 20, 100)  # 5 tarefas/dia = 100
        else:
            volume_score = 0
        
        # Score final
        final_score = completion_rate * 0.7 + volume_score * 0.3
        
        # Recomendações
        recommendations = []
        if completion_rate < 50:
            recommendations.append("Divida tarefas grandes em subtarefas menores")
        if volume_score < 40:
            recommendations.append("Tente definir 2-3 tarefas importantes por dia")
        
        return DimensionScore(
            name='Produtividade',
            score=round(final_score, 1),
            weight=self.weights['productivity'],
            level=self._score_to_level(final_score),
            factors={
                'taxa_conclusão': round(completion_rate, 1),
                'volume': round(volume_score, 1),
            },
            recommendations=recommendations,
        )
    
    def _analyze_consistency(self, records: List[Dict], expected_days: int) -> DimensionScore:
        """Analisa consistência de uso do app."""
        if not records:
            return self._empty_dimension('Consistência', self.weights['consistency'])
        
        # Dias com registro
        unique_days = set()
        for r in records:
            try:
                date_str = r.get('date', '')[:10]
                if date_str:
                    unique_days.add(date_str)
            except:
                pass
        
        coverage = len(unique_days) / expected_days * 100 if expected_days > 0 else 0
        
        # Sequência de dias consecutivos (streak de registros)
        if unique_days:
            sorted_days = sorted(unique_days)
            max_streak = 1
            current_streak = 1
            
            for i in range(1, len(sorted_days)):
                try:
                    prev = datetime.strptime(sorted_days[i-1], '%Y-%m-%d')
                    curr = datetime.strptime(sorted_days[i], '%Y-%m-%d')
                    if (curr - prev).days == 1:
                        current_streak += 1
                        max_streak = max(max_streak, current_streak)
                    else:
                        current_streak = 1
                except:
                    pass
            
            streak_score = min(max_streak * 10, 100)  # 10 dias consecutivos = 100
        else:
            streak_score = 0
        
        # Score final
        final_score = coverage * 0.6 + streak_score * 0.4
        
        # Recomendações
        recommendations = []
        if coverage < 50:
            recommendations.append("Tente registrar seu humor pelo menos 1x por dia")
        if streak_score < 30:
            recommendations.append("Configure lembretes para registrar diariamente")
        
        return DimensionScore(
            name='Consistência',
            score=round(final_score, 1),
            weight=self.weights['consistency'],
            level=self._score_to_level(final_score),
            factors={
                'cobertura': round(coverage, 1),
                'regularidade': round(streak_score, 1),
            },
            recommendations=recommendations,
        )
    
    def _empty_dimension(self, name: str, weight: float) -> DimensionScore:
        """Retorna dimensão vazia (sem dados)."""
        return DimensionScore(
            name=name,
            score=0,
            weight=weight,
            level=HealthLevel.NEEDS_ATTENTION,
            factors={},
            recommendations=["Comece a registrar dados para análise"],
        )
    
    def _score_to_level(self, score: float) -> HealthLevel:
        """Converte score para nível."""
        if score >= 80:
            return HealthLevel.EXCELLENT
        elif score >= 60:
            return HealthLevel.GOOD
        elif score >= 40:
            return HealthLevel.MODERATE
        elif score >= 20:
            return HealthLevel.NEEDS_ATTENTION
        else:
            return HealthLevel.CRITICAL
    
    def _calculate_trend(self, records: List[Dict]) -> str:
        """Calcula tendência geral."""
        if len(records) < 14:
            return 'insufficient_data'
        
        scores = [r['score'] for r in records]
        
        # Compara primeira e segunda metade
        mid = len(scores) // 2
        first_half = sum(scores[:mid]) / mid
        second_half = sum(scores[mid:]) / (len(scores) - mid)
        
        diff = second_half - first_half
        
        if diff > 0.3:
            return 'improving'
        elif diff < -0.3:
            return 'declining'
        else:
            return 'stable'


def generate_demo_data() -> Tuple[List[Dict], List[Dict], List[Dict]]:
    """Gera dados demo para teste."""
    random.seed(42)
    now = datetime.now()
    days = 30
    
    # Mood records
    mood_records = []
    for i in range(days):
        date = now - timedelta(days=days - 1 - i)
        base = 3.0 + i * 0.02  # Tendência de melhora
        if date.weekday() >= 5:
            base += 0.3
        score = max(1, min(5, base + random.gauss(0, 0.5)))
        
        mood_records.append({
            'date': date.isoformat(),
            'score': round(score, 2),
            'activities': random.sample(['exercicio', 'meditacao', 'leitura'], k=random.randint(0, 2)),
        })
    
    # Habits
    habits = [
        {'id': 'med', 'name': 'Meditação', 'completions': [f'2025-12-{d:02d}' for d in range(1, 16)], 'current_streak': 5},
        {'id': 'ex', 'name': 'Exercício', 'completions': [f'2025-12-{d:02d}' for d in range(1, 10)], 'current_streak': 0},
        {'id': 'read', 'name': 'Leitura', 'completions': [f'2025-12-{d:02d}' for d in [1, 3, 5, 7, 9, 11, 13]], 'current_streak': 2},
    ]
    
    # Tasks
    tasks = []
    for i in range(50):
        completed = random.random() < 0.6
        tasks.append({
            'id': f'task_{i}',
            'title': f'Tarefa {i}',
            'completed': completed,
            'created_at': (now - timedelta(days=random.randint(0, 29))).isoformat(),
            'completed_at': now.isoformat() if completed else None,
        })
    
    return mood_records, habits, tasks


def print_report(report: HealthReport):
    """Imprime relatório formatado."""
    
    level_emoji = {
        HealthLevel.EXCELLENT: '🌟',
        HealthLevel.GOOD: '✅',
        HealthLevel.MODERATE: '⚠️',
        HealthLevel.NEEDS_ATTENTION: '🔶',
        HealthLevel.CRITICAL: '🚨',
    }
    
    trend_emoji = {
        'improving': '📈',
        'stable': '➡️',
        'declining': '📉',
        'insufficient_data': '❓',
    }
    
    print("\n" + "=" * 60)
    print("🏥 RELATÓRIO DE SAÚDE - ODYSSEY")
    print("=" * 60)
    
    # Score principal
    print(f"\n{'─' * 40}")
    print(f"  HEALTH SCORE: {report.overall_score}/100 {level_emoji.get(report.level, '')}")
    print(f"  Nível: {report.level.value.upper()}")
    print(f"  Tendência: {report.trend} {trend_emoji.get(report.trend, '')}")
    print(f"{'─' * 40}")
    
    # Dimensões
    print("\n📊 DIMENSÕES:")
    for dim in sorted(report.dimensions, key=lambda d: -d.score):
        bar = "█" * int(dim.score / 10) + "░" * (10 - int(dim.score / 10))
        emoji = level_emoji.get(dim.level, '')
        print(f"\n  {dim.name} {emoji}")
        print(f"  [{bar}] {dim.score}/100")
        
        for factor, value in dim.factors.items():
            print(f"    • {factor}: {value}")
    
    # Pontos fortes e fracos
    if report.top_strengths:
        print(f"\n💪 PONTOS FORTES: {', '.join(report.top_strengths)}")
    
    if report.top_weaknesses:
        print(f"🎯 ÁREAS DE FOCO: {', '.join(report.top_weaknesses)}")
    
    # Ações prioritárias
    if report.priority_actions:
        print("\n🚀 AÇÕES PRIORITÁRIAS:")
        for i, action in enumerate(report.priority_actions, 1):
            print(f"  {i}. {action}")
    
    print("\n" + "=" * 60 + "\n")


def main():
    parser = argparse.ArgumentParser(description='Health Score Analyzer')
    parser.add_argument('--json', type=str, help='Arquivo JSON com dados')
    parser.add_argument('--demo', action='store_true', help='Usa dados demo')
    parser.add_argument('--output-json', action='store_true', help='Saída em JSON')
    args = parser.parse_args()
    
    if args.json:
        with open(args.json) as f:
            data = json.load(f)
        mood_records = data.get('mood_records', [])
        habits = data.get('habits', [])
        tasks = data.get('tasks', [])
    else:
        print("🔄 Gerando dados demo...")
        mood_records, habits, tasks = generate_demo_data()
    
    analyzer = HealthScoreAnalyzer()
    report = analyzer.analyze(mood_records, habits, tasks)
    
    if args.output_json:
        output = {
            'overall_score': report.overall_score,
            'level': report.level.value,
            'trend': report.trend,
            'dimensions': [
                {
                    'name': d.name,
                    'score': d.score,
                    'level': d.level.value,
                    'factors': d.factors,
                    'recommendations': d.recommendations,
                }
                for d in report.dimensions
            ],
            'strengths': report.top_strengths,
            'weaknesses': report.top_weaknesses,
            'priority_actions': report.priority_actions,
        }
        print(json.dumps(output, indent=2))
    else:
        print_report(report)


if __name__ == '__main__':
    main()
