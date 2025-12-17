# 🧠 SISTEMA DE INTELIGÊNCIA HÍBRIDO - ODYSSEY

**Status:** ✅ Implementado e funcional (Fase 1 + Turbo + ML completos)  
**Objetivo:** Sistema de ML local que aprende padrões do usuário e gera insights personalizados  
**Abordagem:** Estatísticas → ML On-Device → IA (futuro)

---

## ✅ FUNCIONALIDADES IMPLEMENTADAS

### Fase 1 - Estatísticas e Regras (COMPLETO)
- [x] Detecção de padrões temporais (dia da semana, hora do dia)
- [x] Detecção de padrões comportamentais (atividades, volatilidade)
- [x] Correlação de Pearson entre variáveis
- [x] Correlação de Spearman (não-linear)
- [x] Previsão de quebra de streaks
- [x] Previsão de humor (tendências)
- [x] Sistema de recomendações contextuais
- [x] Integração com dados reais (MoodRecords, Habits, Tasks, TimeTracking)
- [x] UI completa com tela de Descobertas
- [x] Widgets reutilizáveis para home

### Fase Turbo - Análises Avançadas (COMPLETO)
- [x] **Detecção de Anomalias** (Z-Score, IQR) - Identifica dias atípicos
- [x] **Análise de Volatilidade** - Coeficiente de variação do humor
- [x] **Previsão EMA** - Média Móvel Exponencial + Sazonalidade
- [x] **Clustering de Dias** - K-Means simplificado (dias produtivos, difíceis, etc)
- [x] **Health Score** - Score unificado 0-100 com 4 dimensões
- [x] **Sistema de Scoring** - Priorização inteligente de insights
- [x] **Widget Health Score** - Gauge animado + cards de dimensão

### Fase Home Integration (COMPLETO)
- [x] **Health Score na Home** - Widget compacto com navegação
- [x] **Tela dedicada Health Score** - Detalhes de cada dimensão
- [x] **Provider Health Score** - Conectado aos dados reais

### Fase Notificações Inteligentes (COMPLETO)
- [x] **SmartNotificationService** - Gera notificações baseadas em análise
- [x] **Tipos de notificação**: streak_risk, mood_drop, anomaly, achievement, weekly_report
- [x] **Agendamento automático** - Integrado com ModernNotificationService

### Fase ML (PREPARADO)
- [x] **Feature Engineering** - 14 features extraídas dos dados
- [x] **Script de treinamento** - ml_model_trainer.py
- [x] **Modelo fallback** - Quando TFLite não disponível
- [x] **Código Dart gerado** - mood_prediction_model.dart
- [x] **Analisador Léxico PT-BR** - lexicon_analyzer.dart (sem ML)

### Fase Analytics Dashboard (COMPLETO)
- [x] **Dashboard Interativo** - intelligence_dashboard_screen.dart
- [x] **4 Tabs**: Visão Geral, Humor, Padrões, Correlações
- [x] **Seletor de Período** - 7d, 30d, 90d
- [x] **Gráficos Interativos** - fl_chart (LineChart, BarChart, PieChart)
- [x] **Análise de Volatilidade** - Visualização do CV
- [x] **Impacto de Atividades** - Gráfico de barras

### Scripts Python de Desenvolvimento (16 scripts)
```
scripts/
├── intelligence_simulator.py   # Simula dados e testa algoritmos base
├── intelligence_validator.py   # Valida algoritmos específicos
├── turbo_intelligence.py       # Análises avançadas (anomalias, clustering, etc)
├── generate_test_data.py       # Gera datasets de teste + testes Dart
├── health_score_analyzer.py    # Calcula e exibe Health Score
├── ml_model_trainer.py         # Treina modelo de ML para previsão
└── tflite_models_info.py       # 🆕 Info sobre modelos TFLite + gera LexiconAnalyzer
```

---

## 📋 ARQUITETURA

```
lib/src/features/intelligence/
├── data/
│   ├── user_insights_repository.dart      # CRUD de insights (Hive)
│   ├── intelligence_data_adapter.dart     # Converte dados do app → engines
│   └── intelligence_config.dart           # Configurações do sistema
│
├── domain/
│   ├── models/
│   │   ├── insight.dart                   # Modelo de insight (TypeId: 27)
│   │   ├── user_pattern.dart              # Padrão detectado (TypeId: 28)
│   │   ├── prediction.dart                # Previsão (TypeId: 29)
│   │   └── correlation.dart               # Correlação detectada
│   │
│   └── engines/
│       ├── pattern_engine.dart            # Padrões temporais/comportamentais
│       ├── correlation_engine.dart        # Correlações (Pearson, Spearman)
│       ├── recommendation_engine.dart     # Recomendações contextuais
│       ├── prediction_engine.dart         # Predições (streaks, mood)
│       ├── advanced_analysis_engine.dart  # Anomalias, EMA, Clustering
│       └── health_score_engine.dart       # Health Score unificado
│
├── providers/
│   └── health_score_provider.dart         # 🆕 Provider do Health Score
│
├── services/
│   ├── intelligence_service.dart          # Orquestrador principal
│   ├── smart_notification_service.dart    # Notificações inteligentes
│   ├── mood_prediction_model.dart         # Modelo ML (TFLite ready)
│   └── lexicon_analyzer.dart              # 🆕 Análise léxica PT-BR
│
└── presentation/
    ├── intelligence_screen.dart           # Tela "Descobertas"
    ├── health_score_screen.dart           # Tela dedicada Health Score
    ├── intelligence_dashboard_screen.dart # 🆕 Dashboard Analytics
    └── widgets/
        ├── insight_card.dart              # Card de insight individual
        ├── pattern_chart.dart             # Visualização de padrões
        ├── correlation_widget.dart        # Mostra correlações
        ├── prediction_indicator.dart      # Indicador de previsões
        ├── intelligence_summary_widget.dart # Resumo para home
        └── health_score_widget.dart       # Gauge + cards Health Score
```
        └── prediction_indicator.dart      # Indicador de previsões
```

---

## 🎯 MODELOS DE DADOS (Hive)

### **Insight** (TypeId: 27)
```dart
@HiveType(typeId: 27)
class Insight {
  @HiveField(0) String id;
  @HiveField(1) String title;              // "Padrão de Humor Detectado"
  @HiveField(2) String description;        // Texto explicativo
  @HiveField(3) InsightType type;          // pattern, correlation, recommendation, warning
  @HiveField(4) InsightPriority priority;  // low, medium, high, urgent
  @HiveField(5) double confidence;         // 0.0-1.0
  @HiveField(6) DateTime generatedAt;
  @HiveField(7) DateTime validUntil;       // Cache expiration
  @HiveField(8) Map<String, dynamic> metadata; // Dados extras (gráficos, valores)
  @HiveField(9) bool isRead;               // Usuário já viu?
  @HiveField(10) int? userRating;          // 1-5 (feedback)
}

enum InsightType { pattern, correlation, recommendation, prediction, warning, celebration }
enum InsightPriority { low, medium, high, urgent }
```

### **UserPattern** (TypeId: 28)
```dart
@HiveType(typeId: 28)
class UserPattern {
  @HiveField(0) String id;
  @HiveField(1) PatternType type;          // temporal, behavioral, correlation
  @HiveField(2) String description;        // "Humor melhor às manhãs"
  @HiveField(3) double strength;           // 0.0-1.0 (força do padrão)
  @HiveField(4) Map<String, dynamic> data; // Dados do padrão (ex: {"dayOfWeek": 1, "avgMood": 4.2})
  @HiveField(5) DateTime firstDetected;
  @HiveField(6) DateTime lastConfirmed;
  @HiveField(7) int occurrences;           // Quantas vezes confirmado
}

enum PatternType { temporal, behavioral, correlation, cyclical }
```

### **Prediction** (TypeId: 29)
```dart
@HiveType(typeId: 29)
class Prediction {
  @HiveField(0) String id;
  @HiveField(1) PredictionType type;       // streak, mood, completion
  @HiveField(2) String targetId;           // ID do hábito/tarefa
  @HiveField(3) double probability;        // 0.0-1.0
  @HiveField(4) DateTime predictedFor;     // Quando ocorre
  @HiveField(5) String reasoning;          // Por que essa previsão
  @HiveField(6) Map<String, dynamic> features; // Features usadas
  @HiveField(7) DateTime generatedAt;
}

enum PredictionType { streakBreak, streakSuccess, moodDrop, moodImprovement, taskCompletion }
```

### **Correlation** (TypeId: 30)
```dart
@HiveType(typeId: 30)
class Correlation {
  @HiveField(0) String id;
  @HiveField(1) String variable1;          // Ex: "exercise"
  @HiveField(2) String variable2;          // Ex: "mood_score"
  @HiveField(3) double coefficient;        // -1.0 a 1.0 (Pearson)
  @HiveField(4) double pValue;             // Significância estatística
  @HiveField(5) int sampleSize;            // N de observações
  @HiveField(6) CorrelationStrength strength; // weak, moderate, strong
  @HiveField(7) DateTime calculatedAt;
}

enum CorrelationStrength { none, weak, moderate, strong, veryStrong }
```

---

## ⚙️ ENGINES (NÚCLEO DO SISTEMA)

### **1. PatternEngine**
**Responsabilidade:** Detectar padrões nos dados do usuário

**Métodos principais:**
```dart
class PatternEngine {
  // Padrões temporais
  Future<List<UserPattern>> detectTemporalPatterns();
  Map<int, double> moodByDayOfWeek();          // Humor por dia da semana
  Map<int, double> moodByHourOfDay();          // Humor por hora
  List<double> moodTrend(int days);            // Tendência (subindo/caindo)
  
  // Padrões comportamentais
  Map<String, double> activityCompletionRates(); // Taxa de conclusão por atividade
  Map<int, int> taskCreationPatterns();         // Quando cria mais tarefas
  List<int> mostProductiveHours();              // Horários mais produtivos
  
  // Padrões cíclicos
  bool detectWeeklyCycle();                     // Ciclo semanal detectado?
  bool detectMonthlyCycle();                    // Ciclo mensal?
  
  // Streaks
  Map<String, int> habitStreakPatterns();       // Padrões de streaks por hábito
}
```

**Algoritmos:**
- Média móvel (moving average)
- Desvio padrão por grupo
- Detecção de tendências (regressão linear)
- Análise de frequências (FFT simplificado)

---

### **2. CorrelationEngine**
**Responsabilidade:** Calcular correlações entre variáveis

**Métodos principais:**
```dart
class CorrelationEngine {
  // Correlações mood
  Future<Correlation> moodVsActivity(String activityName);
  Future<Correlation> moodVsHabit(String habitId);
  Future<Correlation> moodVsTimeOfDay();
  Future<Correlation> moodVsTasksCompleted();
  
  // Correlações produtividade
  Future<Correlation> tasksCompletedVsTimeTracked();
  Future<Correlation> habitsVsMoodImprovement();
  
  // Método genérico
  double calculatePearsonCorrelation(List<double> x, List<double> y);
  double calculateSpearmanCorrelation(List<int> ranks1, List<int> ranks2);
  
  // Validação estatística
  double calculatePValue(double r, int n);
  CorrelationStrength classifyStrength(double r);
}
```

**Algoritmos:**
- Correlação de Pearson (linear)
- Correlação de Spearman (não-linear)
- Teste t para significância
- Correção de Bonferroni (múltiplas comparações)

---

### **3. RecommendationEngine**
**Responsabilidade:** Gerar recomendações contextuais inteligentes

**Métodos principais:**
```dart
class RecommendationEngine {
  // Recomendações de atividades
  Future<List<Activity>> recommendActivitiesForMood(int currentMoodScore);
  Future<List<Activity>> recommendBasedOnTimeOfDay();
  Future<List<Activity>> recommendBasedOnHistory();
  
  // Recomendações de timing
  TimeOfDay bestTimeForActivity(String activityName);
  TimeOfDay bestTimeForHabit(String habitId);
  
  // Recomendações de hábitos/tarefas
  List<Suggestion> reRankSuggestions(List<Suggestion> suggestions);
  
  // Score de recomendação
  double calculateRecommendationScore({
    required String itemId,
    required Map<String, dynamic> context, // mood atual, hora, dia da semana
    required Map<String, double> userHistory,
  });
}
```

**Fatores considerados:**
- Humor atual vs histórico
- Hora do dia vs performance histórica
- Dia da semana vs padrões
- Última vez que fez a atividade
- Taxa de sucesso histórica
- Correlações conhecidas

---

### **4. PredictionEngine**
**Responsabilidade:** Fazer previsões sobre comportamento futuro

**Métodos principais:**
```dart
class PredictionEngine {
  // Previsão de streaks
  Future<Prediction> predictStreakBreak(String habitId);
  double calculateStreakSurvivalProbability(String habitId, int daysAhead);
  
  // Previsão de humor
  Future<Prediction> predictMoodForTomorrow();
  List<double> predictMoodTrend(int daysAhead);
  
  // Previsão de conclusão
  Future<Prediction> predictTaskCompletion(String taskId);
  double estimateCompletionProbability(String taskId);
  
  // Features para predição
  Map<String, double> extractFeaturesForPrediction({
    required String targetId,
    required PredictionType type,
  });
}
```

**Algoritmos (Fase 1 - Sem ML):**
- Regressão linear
- Média ponderada por recência
- Survival analysis simplificado
- Heurísticas baseadas em regras

**Algoritmos (Fase 2 - Com ML):**
- LSTM para séries temporais
- Random Forest para classificação
- Gradient Boosting para previsões numéricas

---

### **5. MLModelLoader** (Fase 2)
**Responsabilidade:** Carregar e executar modelos TensorFlow Lite

```dart
class MLModelLoader {
  Future<void> loadModel(String modelPath);
  List<double> predict(List<double> input);
  Future<void> updateModel(Map<String, dynamic> newData);
}
```

**Modelos planejados:**
- `mood_predictor.tflite` - Predição de humor (LSTM)
- `streak_classifier.tflite` - Classificador de risco de streak (RF)
- `activity_recommender.tflite` - Recomendador colaborativo (MF)

---

## 🔧 INTELLIGENCE SERVICE (ORQUESTRADOR)

```dart
class IntelligenceService {
  final PatternEngine _patternEngine;
  final CorrelationEngine _correlationEngine;
  final RecommendationEngine _recommendationEngine;
  final PredictionEngine _predictionEngine;
  final UserInsightsRepository _repository;
  
  // Método principal - roda análise completa
  Future<AnalysisResult> runFullAnalysis({bool forceRefresh = false});
  
  // Gerar insights
  Future<List<Insight>> generateInsights();
  
  // Obter recomendações
  Future<List<Recommendation>> getRecommendations();
  
  // Obter previsões
  Future<List<Prediction>> getPredictions();
  
  // Insight do dia
  Future<Insight?> getDailyInsight();
  
  // Feedback do usuário
  Future<void> rateInsight(String insightId, int rating);
  
  // Limpeza de cache
  Future<void> cleanExpiredInsights();
}

class AnalysisResult {
  final List<UserPattern> patterns;
  final List<Correlation> correlations;
  final List<Insight> insights;
  final List<Prediction> predictions;
  final DateTime analyzedAt;
  final Duration processingTime;
}
```

---

## 📊 EXEMPLOS DE INSIGHTS GERADOS

### **Padrão Temporal**
```json
{
  "id": "pattern_001",
  "title": "🌅 Você é uma pessoa da manhã",
  "description": "Seu humor é 32% melhor entre 7h-11h comparado ao resto do dia",
  "type": "pattern",
  "priority": "medium",
  "confidence": 0.87,
  "metadata": {
    "morningMood": 4.2,
    "afternoonMood": 3.5,
    "eveningMood": 3.1,
    "sampleSize": 45
  }
}
```

### **Correlação**
```json
{
  "id": "corr_001",
  "title": "🏃 Exercício = Bem-estar",
  "description": "Exercício físico aumenta seu humor em média 1.4 pontos",
  "type": "correlation",
  "priority": "high",
  "confidence": 0.92,
  "metadata": {
    "correlation": 0.78,
    "withExercise": 4.3,
    "withoutExercise": 2.9,
    "difference": "+48%"
  }
}
```

### **Previsão**
```json
{
  "id": "pred_001",
  "title": "⚠️ Streak em Risco",
  "description": "Seu streak de 'Meditação' tem 35% de chance de quebrar amanhã",
  "type": "warning",
  "priority": "urgent",
  "confidence": 0.65,
  "metadata": {
    "habitName": "Meditação",
    "currentStreak": 12,
    "probability": 0.35,
    "reason": "Baseado em padrão: você pula às quartas-feiras"
  }
}
```

### **Recomendação**
```json
{
  "id": "rec_001",
  "title": "💡 Melhor Momento para Tarefas",
  "description": "Você completa 84% das tarefas criadas entre 9h-11h",
  "type": "recommendation",
  "priority": "medium",
  "confidence": 0.79,
  "metadata": {
    "action": "schedule_tasks_morning",
    "bestTime": "09:00-11:00",
    "completionRate": 0.84,
    "currentPendingTasks": 5
  }
}
```

---

## 🎨 UI - TELA "DESCOBERTAS"

### **Layout:**
```
┌─────────────────────────────────────┐
│  🧠 Descobertas                     │
├─────────────────────────────────────┤
│                                     │
│  📊 Insight do Dia                  │
│  ┌─────────────────────────────┐   │
│  │ 🌅 Você é uma pessoa da     │   │
│  │    manhã                    │   │
│  │ Seu humor é 32% melhor...   │   │
│  │ [Ver detalhes]              │   │
│  └─────────────────────────────┘   │
│                                     │
│  🔍 Padrões Detectados (3)          │
│  ┌─────────────────────────────┐   │
│  │ • Humor melhor às terças    │   │
│  │ • Produtividade pico: 10h   │   │
│  │ • Exercício → +1.4 mood     │   │
│  └─────────────────────────────┘   │
│                                     │
│  💡 Recomendações (2)                │
│  ┌─────────────────────────────┐   │
│  │ → Agende tarefas às 9h      │   │
│  │ → Faça exercício hoje       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ⚡ Previsões (1)                   │
│  ┌─────────────────────────────┐   │
│  │ ⚠️ Streak 'Leitura' em risco│   │
│  └─────────────────────────────┘   │
│                                     │
│  📈 Suas Estatísticas               │
│  • 45 dias analisados               │
│  • 12 padrões descobertos           │
│  • 8 correlações fortes             │
│                                     │
└─────────────────────────────────────┘
```

### **Widgets:**
- `InsightCard` - Card expansível com detalhes
- `PatternChart` - Gráfico de linha/barra para padrões
- `CorrelationWidget` - Visualização de correlação (dois eixos)
- `PredictionIndicator` - Progress bar com probabilidade

---

## 🚀 PLANO DE IMPLEMENTAÇÃO

### **FASE 1: FUNDAÇÃO (Estatísticas + Regras)**
**Tempo estimado:** 1 semana

#### Sprint 1.1: Setup (1 dia)
- [ ] Criar estrutura de pastas
- [ ] Criar models (Insight, UserPattern, Correlation, Prediction)
- [ ] Registrar adapters Hive (TypeIds 27-30)
- [ ] Criar repository base
- [ ] Criar intelligence_service.dart skeleton

#### Sprint 1.2: Pattern Engine (2 dias)
- [ ] Implementar `moodByDayOfWeek()`
- [ ] Implementar `moodByHourOfDay()`
- [ ] Implementar `moodTrend()`
- [ ] Implementar `activityCompletionRates()`
- [ ] Implementar `detectTemporalPatterns()`
- [ ] Testar com dados mockados
- [ ] Testar com dados reais

#### Sprint 1.3: Correlation Engine (2 dias)
- [ ] Implementar correlação de Pearson
- [ ] Implementar `moodVsActivity()`
- [ ] Implementar `moodVsHabit()`
- [ ] Implementar `moodVsTimeOfDay()`
- [ ] Calcular p-values
- [ ] Classificar força das correlações
- [ ] Validar com dados reais

#### Sprint 1.4: Insight Generator (1 dia)
- [ ] Criar templates de insights
- [ ] Implementar `generateInsights()` em IntelligenceService
- [ ] Gerar insights de padrões
- [ ] Gerar insights de correlações
- [ ] Sistema de priorização
- [ ] Sistema de cache (validUntil)

#### Sprint 1.5: UI Básica (1 dia)
- [ ] Criar IntelligenceScreen
- [ ] Criar InsightCard widget
- [ ] Adicionar rota no GoRouter
- [ ] Adicionar botão na home
- [ ] Testar fluxo completo

---

### **FASE 2: ML ON-DEVICE (TensorFlow Lite)**
**Tempo estimado:** 1-2 semanas

#### Sprint 2.1: Setup ML (2 dias)
- [ ] Adicionar dependências TFLite
- [ ] Criar MLModelLoader
- [ ] Preparar dataset de treino
- [ ] Treinar modelo de predição de humor (Python)
- [ ] Converter para .tflite
- [ ] Integrar no app

#### Sprint 2.2: Prediction Engine (2 dias)
- [ ] Implementar `predictStreakBreak()`
- [ ] Implementar `predictMoodForTomorrow()`
- [ ] Implementar `predictTaskCompletion()`
- [ ] Feature engineering
- [ ] Validação cruzada

#### Sprint 2.3: Recommendation Engine ML (2 dias)
- [ ] Treinar modelo de recomendação
- [ ] Implementar `recommendActivitiesForMood()` com ML
- [ ] A/B test com sistema baseado em regras
- [ ] Métricas de performance

#### Sprint 2.4: UI Avançada (1 dia)
- [ ] Adicionar seção de previsões
- [ ] PatternChart interativo
- [ ] Gráficos de correlação
- [ ] Feedback (👍👎) em insights

---

### **FASE 3: IA INTEGRADA (Futuro)**
**Tempo estimado:** TBD

- [ ] Pesquisar LLM local (llama.cpp, Mistral)
- [ ] Ou integrar API privada (Groq/Mistral)
- [ ] Gerar insights em linguagem natural fluente
- [ ] Sistema de "coaching" sutil
- [ ] Respostas a perguntas do usuário

---

## 📐 ALGORITMOS PRINCIPAIS

### **1. Correlação de Pearson**
```dart
double calculatePearsonCorrelation(List<double> x, List<double> y) {
  final n = x.length;
  final sumX = x.reduce((a, b) => a + b);
  final sumY = y.reduce((a, b) => a + b);
  final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
  final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
  final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);
  
  final numerator = n * sumXY - sumX * sumY;
  final denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));
  
  return denominator == 0 ? 0 : numerator / denominator;
}
```

### **2. Média Móvel**
```dart
List<double> movingAverage(List<double> data, int window) {
  final result = <double>[];
  for (int i = window - 1; i < data.length; i++) {
    final sum = data.sublist(i - window + 1, i + 1).reduce((a, b) => a + b);
    result.add(sum / window);
  }
  return result;
}
```

### **3. Regressão Linear Simples**
```dart
(double slope, double intercept) linearRegression(List<double> x, List<double> y) {
  final n = x.length;
  final sumX = x.reduce((a, b) => a + b);
  final sumY = y.reduce((a, b) => a + b);
  final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
  final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
  
  final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  final intercept = (sumY - slope * sumX) / n;
  
  return (slope, intercept);
}
```

### **4. Detecção de Tendência**
```dart
TrendDirection detectTrend(List<double> data) {
  final x = List.generate(data.length, (i) => i.toDouble());
  final (slope, _) = linearRegression(x, data);
  
  if (slope > 0.1) return TrendDirection.rising;
  if (slope < -0.1) return TrendDirection.falling;
  return TrendDirection.stable;
}
```

---

## ⚙️ CONFIGURAÇÕES

### **intelligence_config.dart**
```dart
class IntelligenceConfig {
  // Análise
  static const int minDataPointsForPattern = 7;       // Mínimo 7 dias de dados
  static const int minDataPointsForCorrelation = 14;  // Mínimo 14 dias
  static const double minCorrelationThreshold = 0.3;  // r > 0.3 é considerado
  static const double minConfidenceThreshold = 0.6;   // 60% confiança mínima
  
  // Cache
  static const Duration insightValidity = Duration(days: 1);
  static const Duration patternValidity = Duration(days: 7);
  static const Duration predictionValidity = Duration(hours: 12);
  
  // Performance
  static const int maxInsightsGenerated = 10;         // Máx 10 insights por análise
  static const int maxPatternsStored = 50;            // Máx 50 padrões em cache
  static const Duration analysisTimeout = Duration(seconds: 5); // Timeout
  
  // UI
  static const int insightsPerPage = 5;
  static const bool showLowConfidenceInsights = false;
}
```

---

## 🧪 TESTES

### **Dados Mockados para Testes**
```dart
// test/intelligence/mock_data.dart
List<MoodRecord> generateMockMoodData() {
  // 30 dias de dados
  // Padrão: humor melhor às terças/quartas
  // Correlação: exercício → +1.5 mood
}

List<Habit> generateMockHabits() {
  // Hábitos com padrões de streak
}
```

### **Testes Unitários**
```dart
test('PatternEngine detecta padrão semanal', () {
  final records = generateMockMoodData();
  final patterns = patternEngine.detectTemporalPatterns(records);
  expect(patterns, isNotEmpty);
  expect(patterns.first.type, PatternType.temporal);
});

test('CorrelationEngine calcula Pearson corretamente', () {
  final x = [1.0, 2.0, 3.0, 4.0, 5.0];
  final y = [2.0, 4.0, 6.0, 8.0, 10.0];
  final r = correlationEngine.calculatePearsonCorrelation(x, y);
  expect(r, closeTo(1.0, 0.01)); // Correlação perfeita
});

test('IntelligenceService gera insights válidos', () async {
  final insights = await intelligenceService.generateInsights();
  expect(insights, isNotEmpty);
  expect(insights.every((i) => i.confidence >= 0.6), isTrue);
});
```

---

## 📊 MÉTRICAS DE SUCESSO

### **Qualidade dos Insights**
- [ ] 80%+ de insights com confiança > 0.7
- [ ] 90%+ de correlações com p-value < 0.05
- [ ] Feedback positivo (👍) em 70%+ dos insights

### **Performance**
- [ ] Análise completa < 2 segundos
- [ ] Geração de insights < 500ms
- [ ] Zero impacto no scroll/navegação

### **Impacto no Usuário**
- [ ] +20% engajamento (mais registros de mood)
- [ ] +15% retenção (usuários voltam mais)
- [ ] Feedback qualitativo positivo

---

## 🔒 PRIVACIDADE

**Garantias:**
- ✅ 100% local - nenhum dado sai do dispositivo
- ✅ Zero rastreamento externo
- ✅ Usuário pode desabilitar sistema nas configurações
- ✅ Usuário pode deletar todos os insights

**Settings:**
```dart
// Adicionar em SettingsScreen
- [ ] Habilitar/Desabilitar sistema de inteligência
- [ ] Limpar cache de insights
- [ ] Ver estatísticas de análise
- [ ] Exportar insights (JSON)
```

---

## 📦 DEPENDÊNCIAS

### **Fase 1 (Estatísticas):**
```yaml
# Nenhuma dependência adicional! 🎉
# Usar apenas dart:math
```

### **Fase 2 (ML):**
```yaml
dependencies:
  tflite_flutter: ^0.10.0
  tflite_flutter_helper: ^0.3.1
```

---

## 🎯 CHECKLIST DE IMPLEMENTAÇÃO

### **Preparação**
- [ ] Ler este documento completo
- [ ] Entender arquitetura de cada engine
- [ ] Preparar ambiente de testes com dados mockados

### **Fase 1 - Semana 1**
- [ ] Dia 1: Models + Repository + Service skeleton
- [ ] Dia 2-3: PatternEngine completo
- [ ] Dia 4-5: CorrelationEngine completo
- [ ] Dia 6: Insight Generator + Cache
- [ ] Dia 7: UI básica + Testes end-to-end

### **Validação Fase 1**
- [ ] Sistema gera pelo menos 5 insights válidos
- [ ] Insights fazem sentido com dados reais
- [ ] Performance < 2s para análise completa
- [ ] UI mostra insights corretamente

### **Fase 2 - Semanas 2-3**
- [ ] Setup TFLite + treinar modelos
- [ ] PredictionEngine com ML
- [ ] RecommendationEngine com ML
- [ ] UI avançada + feedback system

---

## 📝 NOTAS FINAIS

### **Quando rodar análise?**
**Recomendação:** 1x por dia às 3h da manhã (background)
- Usuário acorda com insights frescos
- Não impacta performance durante uso

**Alternativa:** Ao abrir app (se último análise > 12h)

### **Como lidar com dados insuficientes?**
```dart
if (moodRecords.length < IntelligenceConfig.minDataPointsForPattern) {
  return Insight(
    title: "Continue registrando!",
    description: "Precisamos de pelo menos 7 dias de dados para gerar insights.",
    type: InsightType.warning,
    priority: InsightPriority.low,
  );
}
```

### **Como evitar insights repetitivos?**
- Cache de padrões detectados
- Não gerar insight do mesmo padrão por 7 dias
- Priorizar insights novos

### **Como melhorar com feedback do usuário?**
```dart
// Quando usuário dá 👎
if (userRating <= 2) {
  // Reduzir peso desse tipo de insight
  // Aprender o que usuário NÃO gosta
}
```

---

## 🚀 COMANDO PARA COMEÇAR

```bash
# 1. Criar estrutura
mkdir -p lib/src/features/intelligence/{data,domain/{models,engines},services,presentation/widgets}

# 2. Criar arquivos base
touch lib/src/features/intelligence/domain/models/{insight,user_pattern,prediction,correlation}.dart
touch lib/src/features/intelligence/domain/engines/{pattern_engine,correlation_engine,recommendation_engine,prediction_engine}.dart
touch lib/src/features/intelligence/services/intelligence_service.dart
touch lib/src/features/intelligence/data/user_insights_repository.dart

# 3. Começar por: insight.dart (model base)
```

---

**PRONTO PARA IMPLEMENTAR! 🎯**

Este documento é seu guia completo. Siga a ordem dos sprints e você terá um sistema de inteligência funcionando em 1 semana (Fase 1).

Dúvidas? Volte a este documento. Tudo está explicado.

**Boa sorte! 🚀**
