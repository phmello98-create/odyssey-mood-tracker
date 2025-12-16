/// Sistema completo de Onboarding Interativo e Feature Discovery
/// 
/// Este módulo inclui:
/// - Onboarding inicial com animações (primeira vez que abre o app)
/// - Sistema de Coach Marks (tooltips guiados)
/// - Feature Discovery Feed (dicas e truques)
/// - Dicas contextuais (inline tips)
/// - Tours guiados por seção
/// - FirstSteps Checklist (primeiros passos gamificados)
/// - ShowcaseView para tutoriais interativos
library onboarding;

// Domain Models
export 'domain/models/onboarding_models.dart';
export 'domain/models/onboarding_content.dart';
export 'domain/models/first_steps_content.dart';

// Data Layer
export 'data/onboarding_repository.dart';

// Presentation - Providers
export 'presentation/onboarding_providers.dart';

// Presentation - Screens
export 'presentation/screens/interactive_onboarding_screen.dart';
export 'presentation/screens/feature_discovery_screen.dart';
export 'presentation/screens/onboarding_settings_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/coach_mark_overlay.dart';
export 'presentation/widgets/contextual_tip_widgets.dart';
export 'presentation/widgets/onboarding_wrapper.dart';
export 'presentation/widgets/first_steps_checklist.dart';
export 'presentation/widgets/first_time_detector.dart';
export 'presentation/widgets/smart_tip_trigger.dart';

// Services - ShowcaseView
export 'services/showcase_service.dart';
