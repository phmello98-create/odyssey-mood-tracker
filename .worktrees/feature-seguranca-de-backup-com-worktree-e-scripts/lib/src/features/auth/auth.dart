/// Auth feature exports
/// 
/// Importar este arquivo para ter acesso a todo o sistema de autenticação.
library auth;

// Domain - Models
export 'domain/models/odyssey_user.dart';
export 'domain/models/auth_result.dart';
export 'domain/models/account_type.dart';

// Domain - Repositories
export 'domain/repositories/auth_repository.dart';
export 'domain/repositories/user_repository.dart';

// Data - Repositories
export 'data/repositories/firebase_auth_repository.dart';
export 'data/repositories/user_firestore_repository.dart';

// Data - Adapters
export 'data/adapters/user_hive_adapter.dart';

// Services
export 'services/sync_service.dart';
export 'services/migration_service.dart';
export 'services/cloud_storage_service.dart';
export 'services/offline_sync_queue.dart';
export 'services/realtime_sync_service.dart' hide SyncConfig;
export 'services/synced_repository_mixin.dart';

// Presentation - Providers
export 'presentation/providers/auth_providers.dart';
export 'presentation/providers/sync_providers.dart';
export 'presentation/providers/migration_providers.dart';
export 'presentation/providers/user_providers.dart';

// Presentation - Screens
export 'presentation/login_screen.dart';
export 'presentation/signup_screen.dart';
export 'presentation/forgot_password_screen.dart';
export 'presentation/screens/account_migration_screen.dart';
export 'presentation/screens/sync_settings_screen.dart';

// Presentation - Widgets
export 'presentation/widgets/auth_gate.dart';
export 'presentation/widgets/sync_indicator.dart';
export 'presentation/widgets/sync_button.dart';
export 'presentation/widgets/migration_progress_widget.dart';
