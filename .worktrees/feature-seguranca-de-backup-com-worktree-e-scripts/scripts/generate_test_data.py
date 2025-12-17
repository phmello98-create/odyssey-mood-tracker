#!/usr/bin/env python3
"""
🧪 GERADOR DE DADOS DE TESTE E BENCHMARK

Gera datasets sintéticos para testar o sistema de inteligência:
- Diferentes perfis de usuário
- Diferentes tamanhos de dados
- Edge cases

Também gera código Dart para testes unitários.

Uso:
  python scripts/generate_test_data.py [--profile casual|dedicated|struggling]
  python scripts/generate_test_data.py --generate-dart-tests
"""

import argparse
import json
import random
from datetime import datetime, timedelta
from typing import List, Dict
from dataclasses import dataclass, asdict


@dataclass
class TestMoodRecord:
    date: str  # ISO format
    score: float
    activities: List[str]
    note: str = ""


@dataclass
class TestHabit:
    id: str
    name: str
    completions: List[str]  # Dates in ISO format
    current_streak: int


@dataclass
class TestTask:
    id: str
    title: str
    completed: bool
    created_at: str
    completed_at: str = None


# ============ PERFIS DE USUÁRIO ============

class UserProfile:
    """Perfil base de usuário."""
    
    def __init__(self, name: str, base_mood: float, variance: float, activity_rate: float):
        self.name = name
        self.base_mood = base_mood
        self.variance = variance
        self.activity_rate = activity_rate


PROFILES = {
    'casual': UserProfile(
        name='Casual',
        base_mood=3.2,
        variance=0.5,
        activity_rate=0.3,
    ),
    'dedicated': UserProfile(
        name='Dedicado',
        base_mood=3.8,
        variance=0.3,
        activity_rate=0.6,
    ),
    'struggling': UserProfile(
        name='Em dificuldade',
        base_mood=2.5,
        variance=0.8,
        activity_rate=0.2,
    ),
    'volatile': UserProfile(
        name='Volátil',
        base_mood=3.0,
        variance=1.2,
        activity_rate=0.4,
    ),
    'improving': UserProfile(
        name='Melhorando',
        base_mood=2.8,  # Começa baixo
        variance=0.4,
        activity_rate=0.5,
    ),
}

ACTIVITIES = [
    ('exercicio', 'Exercício', 0.4),  # Melhora humor
    ('meditacao', 'Meditação', 0.3),
    ('leitura', 'Leitura', 0.2),
    ('trabalho', 'Trabalho', 0.0),  # Neutro
    ('socializar', 'Socializar', 0.3),
    ('natureza', 'Natureza', 0.35),
    ('musica', 'Música', 0.15),
    ('jogos', 'Jogos', 0.1),
    ('alcool', 'Álcool', -0.3),  # Piora humor
    ('dormir_mal', 'Dormiu mal', -0.5),
]


# ============ GERADOR DE DADOS ============

class DataGenerator:
    """Gera dados de teste realistas."""
    
    def __init__(self, profile: UserProfile, seed: int = 42):
        self.profile = profile
        random.seed(seed)
    
    def generate_mood_records(
        self,
        days: int = 30,
        records_per_day: int = 1,
    ) -> List[TestMoodRecord]:
        """Gera registros de humor."""
        records = []
        now = datetime.now()
        
        for i in range(days):
            date = now - timedelta(days=days - 1 - i)
            
            for _ in range(records_per_day):
                # Base com sazonalidade semanal
                base = self.profile.base_mood
                weekday = date.weekday()
                
                # Ajuste semanal
                if weekday == 0:  # Segunda
                    base += 0.2
                elif weekday == 2:  # Quarta
                    base -= 0.1
                elif weekday >= 5:  # Fim de semana
                    base += 0.15
                
                # Tendência para perfil "improving"
                if self.profile.name == 'Melhorando':
                    base += i * 0.02
                
                # Atividades
                day_activities = []
                for act_id, act_name, effect in ACTIVITIES:
                    if random.random() < self.profile.activity_rate:
                        day_activities.append(act_id)
                        base += effect
                
                # Variância
                noise = random.gauss(0, self.profile.variance)
                score = max(1, min(5, base + noise))
                
                hour = random.randint(8, 22)
                record_date = date.replace(hour=hour, minute=random.randint(0, 59))
                
                records.append(TestMoodRecord(
                    date=record_date.isoformat(),
                    score=round(score, 2),
                    activities=day_activities,
                ))
        
        return records
    
    def generate_habits(
        self,
        num_habits: int = 4,
        days: int = 30,
    ) -> List[TestHabit]:
        """Gera dados de hábitos."""
        habit_templates = [
            ('meditacao', 'Meditação', 0.6),
            ('exercicio', 'Exercício', 0.4),
            ('leitura', 'Leitura', 0.5),
            ('agua', 'Beber 2L água', 0.7),
            ('sono', 'Dormir cedo', 0.4),
            ('gratidao', 'Gratidão', 0.5),
        ]
        
        now = datetime.now()
        habits = []
        
        for i in range(min(num_habits, len(habit_templates))):
            habit_id, name, base_rate = habit_templates[i]
            
            completions = []
            streak = 0
            
            for d in range(days):
                date = now - timedelta(days=days - 1 - d)
                weekday = date.weekday()
                
                # Taxa varia por dia da semana
                rate = base_rate * self.profile.activity_rate * 1.5
                if weekday >= 5:  # Fim de semana diferente
                    rate *= 0.8
                
                # Streaks tendem a continuar
                if streak > 0:
                    rate += 0.1
                
                if random.random() < rate:
                    completions.append(date.strftime('%Y-%m-%d'))
                    streak += 1
                else:
                    streak = 0
            
            # Calcula streak atual
            current_streak = 0
            for d in range(days - 1, -1, -1):
                date = now - timedelta(days=days - 1 - d)
                if date.strftime('%Y-%m-%d') in completions:
                    current_streak += 1
                else:
                    break
            
            habits.append(TestHabit(
                id=habit_id,
                name=name,
                completions=completions,
                current_streak=current_streak,
            ))
        
        return habits
    
    def generate_tasks(
        self,
        days: int = 30,
        tasks_per_day: int = 3,
    ) -> List[TestTask]:
        """Gera dados de tarefas."""
        tasks = []
        now = datetime.now()
        
        task_templates = [
            'Revisar emails',
            'Reunião de equipe',
            'Estudar Flutter',
            'Fazer compras',
            'Pagar contas',
            'Limpar casa',
            'Responder mensagens',
            'Organizar arquivos',
            'Preparar apresentação',
            'Fazer exercícios',
        ]
        
        for d in range(days):
            date = now - timedelta(days=days - 1 - d)
            
            num_tasks = random.randint(1, tasks_per_day + 2)
            
            for t in range(num_tasks):
                title = random.choice(task_templates)
                created_hour = random.randint(7, 18)
                created_at = date.replace(hour=created_hour)
                
                # Tarefas criadas de manhã têm mais chance de serem completadas
                completion_rate = 0.7 if created_hour < 12 else 0.5
                completion_rate *= self.profile.activity_rate * 1.5
                
                completed = random.random() < completion_rate
                completed_at = None
                if completed:
                    completed_at = created_at + timedelta(hours=random.randint(1, 8))
                
                tasks.append(TestTask(
                    id=f'task_{d}_{t}',
                    title=title,
                    completed=completed,
                    created_at=created_at.isoformat(),
                    completed_at=completed_at.isoformat() if completed_at else None,
                ))
        
        return tasks


# ============ GERADOR DE TESTES DART ============

def generate_dart_tests() -> str:
    """Gera código Dart para testes unitários."""
    
    dart_code = '''
// AUTO-GENERATED TEST DATA
// Gerado por scripts/generate_test_data.py

import 'package:flutter_test/flutter_test.dart';
import 'package:odyssey/src/features/intelligence/domain/engines/pattern_engine.dart';
import 'package:odyssey/src/features/intelligence/domain/engines/correlation_engine.dart';
import 'package:odyssey/src/features/intelligence/domain/engines/advanced_analysis_engine.dart';

void main() {
  group('PatternEngine', () {
    late PatternEngine engine;
    
    setUp(() {
      engine = PatternEngine();
    });
    
    test('detecta padrão semanal com dados suficientes', () {
      // Dados com padrão claro: segundas-feiras melhor
      final moodData = List.generate(28, (i) {
        final date = DateTime.now().subtract(Duration(days: 27 - i));
        final isMonday = date.weekday == 1;
        return MoodDataPoint(
          date: date,
          score: isMonday ? 4.5 : 3.0,
          activities: [],
        );
      });
      
      final patterns = engine.detectTemporalPatterns(
        moodData: moodData,
        activityData: [],
      );
      
      expect(patterns, isNotEmpty);
      expect(
        patterns.any((p) => p.description.contains('segunda')),
        isTrue,
      );
    });
    
    test('detecta tendência de melhora', () {
      // Humor aumentando ao longo do tempo
      final moodData = List.generate(14, (i) {
        return MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 13 - i)),
          score: 2.0 + (i * 0.2),
          activities: [],
        );
      });
      
      final patterns = engine.detectTemporalPatterns(
        moodData: moodData,
        activityData: [],
      );
      
      expect(
        patterns.any((p) => p.description.contains('melhorando')),
        isTrue,
      );
    });
    
    test('retorna vazio com dados insuficientes', () {
      final moodData = List.generate(3, (i) {
        return MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 2 - i)),
          score: 3.0,
          activities: [],
        );
      });
      
      final patterns = engine.detectTemporalPatterns(
        moodData: moodData,
        activityData: [],
      );
      
      expect(patterns, isEmpty);
    });
  });
  
  group('CorrelationEngine', () {
    late CorrelationEngine engine;
    
    setUp(() {
      engine = CorrelationEngine();
    });
    
    test('calcula correlação de Pearson corretamente', () {
      // Correlação perfeita positiva
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [2.0, 4.0, 6.0, 8.0, 10.0];
      
      final r = engine.calculatePearsonCorrelation(x, y);
      
      expect(r, closeTo(1.0, 0.001));
    });
    
    test('calcula correlação negativa', () {
      final x = [1.0, 2.0, 3.0, 4.0, 5.0];
      final y = [10.0, 8.0, 6.0, 4.0, 2.0];
      
      final r = engine.calculatePearsonCorrelation(x, y);
      
      expect(r, closeTo(-1.0, 0.001));
    });
    
    test('retorna 0 para dados insuficientes', () {
      final x = [1.0, 2.0];
      final y = [3.0, 4.0];
      
      final r = engine.calculatePearsonCorrelation(x, y);
      
      expect(r, equals(0));
    });
  });
  
  group('AdvancedAnalysisEngine', () {
    late AdvancedAnalysisEngine engine;
    
    setUp(() {
      engine = AdvancedAnalysisEngine();
    });
    
    test('detecta anomalias com Z-Score', () {
      // Dados normais + outliers
      final moodData = [
        ...List.generate(20, (i) => MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 25 - i)),
          score: 3.0 + (i % 2) * 0.2,
          activities: [],
        )),
        // Outliers
        MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 3)),
          score: 5.0,
          activities: ['exercicio'],
        ),
        MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 1)),
          score: 1.0,
          activities: [],
        ),
      ];
      
      final anomalies = engine.detectAnomalies(
        moodData: moodData,
        sensitivity: 1.5,
      );
      
      expect(anomalies.length, greaterThanOrEqualTo(1));
    });
    
    test('calcula EMA corretamente', () {
      final values = [1.0, 2.0, 3.0, 4.0, 5.0];
      final ema = engine.exponentialMovingAverage(values, alpha: 0.5);
      
      expect(ema.length, equals(values.length));
      expect(ema[0], equals(1.0));  // Primeiro valor igual
      expect(ema.last, greaterThan(ema.first));  // Tendência
    });
    
    test('detecta volatilidade alta', () {
      // Dados muito variáveis
      final moodData = List.generate(20, (i) {
        return MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 19 - i)),
          score: i % 2 == 0 ? 1.0 : 5.0,  // Alternando extremos
          activities: [],
        );
      });
      
      final volatility = engine.detectVolatility(moodData);
      
      expect(volatility.status, equals(VolatilityStatus.high));
    });
    
    test('detecta volatilidade baixa', () {
      // Dados estáveis
      final moodData = List.generate(20, (i) {
        return MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 19 - i)),
          score: 3.0,  // Sempre igual
          activities: [],
        );
      });
      
      final volatility = engine.detectVolatility(moodData);
      
      expect(volatility.status, equals(VolatilityStatus.low));
    });
    
    test('gera previsões para próximos dias', () {
      final moodData = List.generate(30, (i) {
        return MoodDataPoint(
          date: DateTime.now().subtract(Duration(days: 29 - i)),
          score: 3.0 + (i * 0.05),
          activities: [],
        );
      });
      
      final predictions = engine.predictNextDays(
        moodData: moodData,
        daysAhead: 5,
      );
      
      expect(predictions.length, equals(5));
      expect(predictions[0].confidence, greaterThan(predictions[4].confidence));
    });
    
    test('score de insight prioriza novidade e acionabilidade', () {
      final score1 = engine.scoreInsight(
        confidence: 0.8,
        novelty: 0.9,
        actionability: 0.9,
        relevance: 0.8,
      );
      
      final score2 = engine.scoreInsight(
        confidence: 0.8,
        novelty: 0.3,
        actionability: 0.3,
        relevance: 0.8,
      );
      
      expect(score1, greaterThan(score2));
    });
  });
}
'''
    return dart_code


# ============ MAIN ============

def main():
    parser = argparse.ArgumentParser(description='Gerador de dados de teste')
    parser.add_argument('--profile', choices=PROFILES.keys(), default='dedicated',
                        help='Perfil de usuário')
    parser.add_argument('--days', type=int, default=30, help='Número de dias')
    parser.add_argument('--output', type=str, help='Arquivo de saída JSON')
    parser.add_argument('--generate-dart-tests', action='store_true',
                        help='Gera código Dart de testes')
    parser.add_argument('--seed', type=int, default=42, help='Seed aleatória')
    args = parser.parse_args()
    
    if args.generate_dart_tests:
        print("📝 Gerando testes Dart...")
        dart_code = generate_dart_tests()
        
        output_path = 'test/features/intelligence/intelligence_test.dart'
        with open(output_path, 'w') as f:
            f.write(dart_code)
        
        print(f"✅ Testes gerados em: {output_path}")
        return
    
    profile = PROFILES[args.profile]
    generator = DataGenerator(profile, seed=args.seed)
    
    print(f"🧪 Gerando dados para perfil: {profile.name}")
    print(f"   Dias: {args.days}")
    
    mood_records = generator.generate_mood_records(days=args.days)
    habits = generator.generate_habits(days=args.days)
    tasks = generator.generate_tasks(days=args.days)
    
    data = {
        'profile': profile.name,
        'config': {
            'base_mood': profile.base_mood,
            'variance': profile.variance,
            'activity_rate': profile.activity_rate,
        },
        'mood_records': [asdict(r) for r in mood_records],
        'habits': [asdict(h) for h in habits],
        'tasks': [asdict(t) for t in tasks],
        'stats': {
            'total_mood_records': len(mood_records),
            'avg_mood': sum(r.score for r in mood_records) / len(mood_records),
            'total_habits': len(habits),
            'total_tasks': len(tasks),
            'completed_tasks': sum(1 for t in tasks if t.completed),
        }
    }
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(data, f, indent=2)
        print(f"✅ Dados salvos em: {args.output}")
    else:
        print("\n📊 Estatísticas:")
        print(f"   Registros de humor: {data['stats']['total_mood_records']}")
        print(f"   Humor médio: {data['stats']['avg_mood']:.2f}")
        print(f"   Hábitos: {data['stats']['total_habits']}")
        print(f"   Tarefas: {data['stats']['total_tasks']} ({data['stats']['completed_tasks']} completas)")
        
        print("\n📋 Amostra de dados (JSON):")
        sample = {
            'mood_records': data['mood_records'][:3],
            'habits': data['habits'][:2],
            'tasks': data['tasks'][:2],
        }
        print(json.dumps(sample, indent=2))


if __name__ == '__main__':
    main()
