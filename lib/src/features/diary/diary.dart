// lib/src/features/diary/diary.dart
// Barrel file for diary feature exports

// Data
export 'data/models/diary_entry.dart';
export 'data/repositories/diary_repository.dart';
export 'data/synced_diary_repository.dart';

// Domain
export 'domain/entities/diary_entry_entity.dart';
export 'domain/entities/diary_preferences.dart';
export 'domain/entities/diary_statistics.dart';
export 'domain/entities/diary_template.dart';
export 'domain/repositories/i_diary_repository.dart';

// Services
export 'services/diary_ai_service.dart';
export 'services/diary_export_service.dart';
export 'services/diary_gamification_service.dart';
export 'services/diary_reminder_service.dart';

// Presentation - Controllers
export 'presentation/controllers/diary_controller.dart';
export 'presentation/controllers/diary_editor_controller.dart';
export 'presentation/controllers/diary_providers.dart';
export 'presentation/controllers/diary_state.dart';

// Presentation - Pages
export 'presentation/pages/diary_editor_page.dart';
export 'presentation/pages/diary_home_page.dart';
export 'presentation/pages/diary_insights_page.dart';
export 'presentation/pages/diary_page.dart';

// Presentation - Widgets
export 'presentation/widgets/diary_empty_state.dart';
export 'presentation/widgets/diary_entry_card.dart';
export 'presentation/widgets/diary_entry_header.dart';
export 'presentation/widgets/diary_feeling_picker.dart';
export 'presentation/widgets/diary_filter_chips.dart';
export 'presentation/widgets/diary_insights_widget.dart';
export 'presentation/widgets/diary_quill_editor.dart';
export 'presentation/widgets/diary_search_bar.dart';
export 'presentation/widgets/diary_stats_header.dart';
export 'presentation/widgets/diary_theme_selector.dart';
export 'presentation/widgets/diary_view_mode_selector.dart';
export 'presentation/widgets/feeling_selector_widget.dart';
export 'presentation/widgets/on_this_day_widget.dart';
export 'presentation/widgets/sentiment_analysis_widget.dart';
export 'presentation/widgets/writing_prompt_widget.dart';
