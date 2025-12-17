#!/usr/bin/env python3
"""
Validador Avançado do Sistema de Inteligência

Testa algoritmos específicos:
- Cálculo de probabilidade de sucesso de hábitos
- Detecção de volatilidade de humor
- Correlação de Spearman
- Análise de padrões de atividade

Uso:
  python scripts/intelligence_validator.py
"""

import random
import math
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
from dataclasses import dataclass


# ============ ALGORITMOS A VALIDAR ============

def calculate_habit_success_probability(
    last_30_days: List[bool],
    day_of_week: int,
    current_streak: int
) -> float:
    """
    Calcula probabilidade de sucesso de um hábito.
    
    Fatores considerados:
    - Taxa geral de conclusão (20%)
    - Taxa no dia da semana (30%)
    - Taxa recente - últimos 7 dias (40%)
    - Bonus de streak (até 20%)
    - Base de 10%
    """
    # Fator 1: Taxa geral
    overall_rate = sum(last_30_days) / len(last_30_days) if last_30_days else 0.5
    
    # Fator 2: Taxa no dia da semana específico
    now = datetime.now()
    day_rates = []
    for i, completed in enumerate(last_30_days):
        date = now - timedelta(days=29 - i)
        if date.weekday() == day_of_week:
            day_rates.append(completed)
    
    day_rate = (sum(day_rates) / len(day_rates)) if day_rates else overall_rate
    
    # Fator 3: Momentum do streak
    streak_bonus = min(current_streak * 0.02, 0.2)
    
    # Fator 4: Recência
    recent_7 = last_30_days[-7:] if len(last_30_days) >= 7 else last_30_days
    recent_rate = sum(recent_7) / len(recent_7) if recent_7 else overall_rate
    
    # Combinação
    probability = (
        (overall_rate * 0.2) +
        (day_rate * 0.3) +
        (recent_rate * 0.4) +
        streak_bonus +
        0.1  # Base
    )
    
    return min(max(probability, 0.0), 1.0)


def calculate_spearman_correlation(x: List[float], y: List[float]) -> float:
    """Calcula correlação de Spearman (baseada em ranks)."""
    if len(x) != len(y) or len(x) < 3:
        return 0.0
    
    # Converte para ranks
    def to_ranks(values: List[float]) -> List[float]:
        indexed = list(enumerate(values))
        indexed.sort(key=lambda pair: pair[1])
        ranks = [0.0] * len(values)
        for rank, (orig_idx, _) in enumerate(indexed, 1):
            ranks[orig_idx] = float(rank)
        return ranks
    
    ranks_x = to_ranks(x)
    ranks_y = to_ranks(y)
    
    # Calcula Pearson nos ranks
    n = len(x)
    sum_x = sum(ranks_x)
    sum_y = sum(ranks_y)
    sum_xy = sum(ranks_x[i] * ranks_y[i] for i in range(n))
    sum_x2 = sum(r ** 2 for r in ranks_x)
    sum_y2 = sum(r ** 2 for r in ranks_y)
    
    numerator = n * sum_xy - sum_x * sum_y
    denominator = math.sqrt((n * sum_x2 - sum_x ** 2) * (n * sum_y2 - sum_y ** 2))
    
    return numerator / denominator if denominator != 0 else 0.0


def detect_mood_volatility(scores: List[float]) -> Dict:
    """
    Detecta se o humor é volátil ou estável.
    Usa coeficiente de variação (CV = stdDev / mean).
    """
    if len(scores) < 7:
        return {'status': 'insufficient_data'}
    
    mean = sum(scores) / len(scores)
    variance = sum((s - mean) ** 2 for s in scores) / len(scores)
    std_dev = math.sqrt(variance)
    cv = std_dev / mean if mean > 0 else 0
    
    if cv > 0.25:
        return {
            'status': 'high_volatility',
            'cv': round(cv, 3),
            'std_dev': round(std_dev, 3),
            'mean': round(mean, 2),
            'description': 'Humor muito variável - oscilações frequentes'
        }
    elif cv < 0.1:
        return {
            'status': 'low_volatility',
            'cv': round(cv, 3),
            'std_dev': round(std_dev, 3),
            'mean': round(mean, 2),
            'description': 'Humor estável - poucas variações'
        }
    else:
        return {
            'status': 'normal_volatility',
            'cv': round(cv, 3),
            'std_dev': round(std_dev, 3),
            'mean': round(mean, 2),
            'description': 'Humor com variações normais'
        }


def detect_activity_patterns(
    mood_data: List[Dict],  # [{score, activities: []}]
    activity_names: Dict[str, str]
) -> List[Dict]:
    """Detecta atividades correlacionadas com bom/mau humor."""
    patterns = []
    
    for act_id, act_name in activity_names.items():
        scores_with = []
        scores_without = []
        
        for record in mood_data:
            if act_id in record['activities']:
                scores_with.append(record['score'])
            else:
                scores_without.append(record['score'])
        
        if len(scores_with) < 3 or len(scores_without) < 3:
            continue
        
        avg_with = sum(scores_with) / len(scores_with)
        avg_without = sum(scores_without) / len(scores_without)
        difference = avg_with - avg_without
        
        if abs(difference) > 0.4:
            patterns.append({
                'activity_id': act_id,
                'activity_name': act_name,
                'avg_with': round(avg_with, 2),
                'avg_without': round(avg_without, 2),
                'difference': round(difference, 2),
                'percent_diff': round(abs(difference / avg_without * 100), 1),
                'direction': 'positive' if difference > 0 else 'negative',
                'samples_with': len(scores_with),
                'samples_without': len(scores_without),
            })
    
    # Ordena por diferença absoluta
    patterns.sort(key=lambda p: abs(p['difference']), reverse=True)
    return patterns[:5]


# ============ TESTES ============

def test_habit_probability():
    """Testa cálculo de probabilidade de hábitos."""
    print("\n📊 TESTE: Probabilidade de Sucesso de Hábitos")
    print("-" * 50)
    
    test_cases = [
        {
            'name': 'Hábito consistente',
            'last_30': [True] * 28 + [False, True],
            'streak': 1,
            'expected': 'alta (>0.8)'
        },
        {
            'name': 'Hábito inconsistente',
            'last_30': [random.choice([True, False]) for _ in range(30)],
            'streak': 0,
            'expected': 'média (~0.5)'
        },
        {
            'name': 'Hábito abandonado',
            'last_30': [True] * 10 + [False] * 20,
            'streak': 0,
            'expected': 'baixa (<0.4)'
        },
        {
            'name': 'Streak longo',
            'last_30': [False] * 15 + [True] * 15,
            'streak': 15,
            'expected': 'alta (>0.8)'
        },
    ]
    
    for case in test_cases:
        prob = calculate_habit_success_probability(
            case['last_30'],
            day_of_week=datetime.now().weekday(),
            current_streak=case['streak']
        )
        print(f"   • {case['name']}: {prob:.2f} (esperado: {case['expected']})")


def test_spearman_correlation():
    """Testa correlação de Spearman."""
    print("\n🔗 TESTE: Correlação de Spearman")
    print("-" * 50)
    
    # Correlação perfeita positiva
    x1 = [1, 2, 3, 4, 5]
    y1 = [2, 4, 6, 8, 10]
    r1 = calculate_spearman_correlation(x1, y1)
    print(f"   • Correlação perfeita positiva: {r1:.3f} (esperado: 1.0)")
    
    # Correlação perfeita negativa
    x2 = [1, 2, 3, 4, 5]
    y2 = [10, 8, 6, 4, 2]
    r2 = calculate_spearman_correlation(x2, y2)
    print(f"   • Correlação perfeita negativa: {r2:.3f} (esperado: -1.0)")
    
    # Correlação não-linear (Spearman deve ser maior que Pearson)
    x3 = [1, 2, 3, 4, 5]
    y3 = [1, 4, 9, 16, 25]  # Quadrática
    r3 = calculate_spearman_correlation(x3, y3)
    print(f"   • Correlação não-linear (y=x²): {r3:.3f} (esperado: 1.0 - Spearman captura)")
    
    # Sem correlação
    random.seed(42)
    x4 = [random.random() for _ in range(20)]
    y4 = [random.random() for _ in range(20)]
    r4 = calculate_spearman_correlation(x4, y4)
    print(f"   • Dados aleatórios: {r4:.3f} (esperado: ~0)")


def test_volatility_detection():
    """Testa detecção de volatilidade."""
    print("\n📈 TESTE: Detecção de Volatilidade de Humor")
    print("-" * 50)
    
    # Humor estável
    stable = [3.0] * 30
    result_stable = detect_mood_volatility(stable)
    print(f"   • Humor constante: {result_stable['status']} (CV={result_stable.get('cv', 'N/A')})")
    
    # Humor muito variável
    volatile = [1, 5, 2, 5, 1, 4, 2, 5, 1, 4, 2, 5, 1, 4]
    result_volatile = detect_mood_volatility(volatile)
    print(f"   • Humor oscilante: {result_volatile['status']} (CV={result_volatile.get('cv', 'N/A')})")
    
    # Humor normal
    normal = [3.0 + random.gauss(0, 0.3) for _ in range(30)]
    result_normal = detect_mood_volatility(normal)
    print(f"   • Humor normal: {result_normal['status']} (CV={result_normal.get('cv', 'N/A')})")


def test_activity_patterns():
    """Testa detecção de padrões de atividade."""
    print("\n🎯 TESTE: Padrões de Atividade")
    print("-" * 50)
    
    random.seed(42)
    
    # Simula dados onde exercício melhora humor
    mood_data = []
    for _ in range(50):
        did_exercise = random.random() < 0.4
        base_score = 3.0
        if did_exercise:
            base_score += 0.8  # Exercício aumenta humor
        
        activities = ['exercicio'] if did_exercise else []
        if random.random() < 0.3:
            activities.append('leitura')
        
        mood_data.append({
            'score': base_score + random.gauss(0, 0.3),
            'activities': activities
        })
    
    activity_names = {
        'exercicio': 'Exercício Físico',
        'leitura': 'Leitura',
    }
    
    patterns = detect_activity_patterns(mood_data, activity_names)
    
    for p in patterns:
        direction = "↑" if p['direction'] == 'positive' else "↓"
        print(f"   • {p['activity_name']} {direction} {p['percent_diff']}%")
        print(f"     Com: {p['avg_with']:.2f}, Sem: {p['avg_without']:.2f}")


def run_all_tests():
    """Executa todos os testes."""
    print("\n" + "=" * 60)
    print("🧪 VALIDAÇÃO DOS ALGORITMOS DE INTELIGÊNCIA")
    print("=" * 60)
    
    test_habit_probability()
    test_spearman_correlation()
    test_volatility_detection()
    test_activity_patterns()
    
    print("\n" + "=" * 60)
    print("✅ Todos os testes concluídos!")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    run_all_tests()
