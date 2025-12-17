/// Sistema de Inteligência do Odyssey
///
/// Este módulo implementa um sistema híbrido de análise que:
/// - Detecta padrões de comportamento do usuário
/// - Calcula correlações entre variáveis (humor, atividades, tempo)
/// - Gera previsões sobre streaks e humor
/// - Fornece recomendações personalizadas
///
/// Arquitetura:
/// - PatternEngine: Detecta padrões temporais e comportamentais
/// - CorrelationEngine: Calcula correlações estatísticas
/// - RecommendationEngine: Gera recomendações contextuais
/// - PredictionEngine: Faz previsões baseadas em histórico
/// - IntelligenceService: Orquestra todos os engines
library intelligence;

// Models
export 'domain/models/insight.dart';
export 'domain/models/user_pattern.dart';
export 'domain/models/prediction.dart';
export 'domain/models/correlation.dart';

// Engines
export 'domain/engines/pattern_engine.dart';
export 'domain/engines/correlation_engine.dart';
export 'domain/engines/recommendation_engine.dart';
export 'domain/engines/prediction_engine.dart';
export 'domain/engines/advanced_analysis_engine.dart';
export 'domain/engines/health_score_engine.dart';

// Services
export 'services/intelligence_service.dart';

// Config
export 'data/intelligence_config.dart';

// Widgets
export 'presentation/widgets/insight_card.dart';
export 'presentation/widgets/pattern_chart.dart';
export 'presentation/widgets/trends_chart.dart';
export 'presentation/widgets/correlation_widget.dart';
export 'presentation/widgets/prediction_indicator.dart';
export 'presentation/widgets/recommendation_card.dart';
export 'presentation/widgets/intelligence_dashboard.dart';
export 'presentation/widgets/mood_analysis_widget.dart';
export 'presentation/widgets/streak_prediction_widget.dart';
export 'presentation/widgets/activity_analysis_widget.dart';
export 'presentation/widgets/intelligence_summary_widget.dart';
export 'presentation/widgets/health_score_widget.dart';

// Data
export 'data/intelligence_data_adapter.dart';
export 'data/user_insights_repository.dart';

// Providers
export 'providers/health_score_provider.dart';

// Presentation
export 'presentation/intelligence_screen.dart';
export 'presentation/insight_detail_screen.dart';
export 'presentation/health_score_screen.dart';
export 'presentation/intelligence_dashboard_screen.dart';
