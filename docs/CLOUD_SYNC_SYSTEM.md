# Cloud Sync System - Documentação

## Visão Geral

Sistema completo de sincronização de dados entre dispositivos com suporte offline e sync bidirecional.

---

## Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLOUD SYNC SYSTEM                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────────┐   │
│  │   Hive      │◀──▶│   Synced     │◀──▶│  OfflineSyncQueue   │   │
│  │   (Local)   │    │  Repository  │    │    (Fila Offline)   │   │
│  └─────────────┘    └──────────────┘    └──────────┬──────────┘   │
│                                                     │              │
│                     ┌───────────────────────────────┤              │
│                     │                               │              │
│           ┌─────────▼─────────┐         ┌───────────▼───────────┐ │
│           │  RealtimeSync     │         │     SyncService       │ │
│           │   (Cloud→Local)   │         │    (Local→Cloud)      │ │
│           └─────────┬─────────┘         └───────────┬───────────┘ │
│                     │                               │              │
│                     └───────────────┬───────────────┘              │
│                                     │                              │
│                          ┌──────────▼──────────┐                  │
│                          │     Firestore       │                  │
│                          │      (Cloud)        │                  │
│                          └─────────────────────┘                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 1. Firebase Storage (CloudStorageService)

**Arquivo:** `lib/src/features/auth/services/cloud_storage_service.dart`

### Funcionalidades

- Upload de fotos de perfil (máx 5MB)
- Upload de capas de livros (máx 2MB)
- Download e cache local de imagens
- Gerenciamento de storage do usuário

### Uso

```dart
final cloudStorage = ref.read(cloudStorageServiceProvider);

// Upload foto de perfil
final result = await cloudStorage?.uploadProfilePhoto(imageFile);
if (result?.success == true) {
  final downloadUrl = result!.downloadUrl;
  // Salvar URL no perfil do usuário
}

// Upload capa de livro
final coverResult = await cloudStorage?.uploadBookCover(bookId, imageFile);

// Baixar para cache local
final cachedFile = await cloudStorage?.downloadProfilePhoto(downloadUrl);
```

### Provider

```dart
final cloudStorageServiceProvider = Provider<CloudStorageService?>
```

---

## 2. Resolução de Conflitos (Timestamp-based)

**Arquivo:** `lib/src/features/auth/services/offline_sync_queue.dart`

### Estratégias Disponíveis

```dart
enum ConflictResolutionStrategy {
  lastWriteWins,    // Última escrita ganha (padrão)
  serverWins,       // Servidor sempre ganha
  clientWins,       // Cliente sempre ganha
  merge,            // Merge inteligente de campos
}
```

### Como Funciona

1. Cada documento tem campos `_localModifiedAt` e `_syncedAt`
2. Ao sincronizar, compara timestamps local vs servidor
3. Aplica estratégia configurada para resolver conflito
4. Para `merge`: combina campos de ambos, listas fazem union

### Campos de Metadata

Todos os documentos sincronizados agora incluem:

```dart
{
  // ... dados do documento
  '_localModifiedAt': '2024-01-15T10:30:00.000Z',  // Quando foi modificado localmente
  '_syncedAt': FieldValue.serverTimestamp(),        // Timestamp do servidor
}
```

---

## 3. Fila de Sincronização Offline (OfflineSyncQueue)

**Arquivo:** `lib/src/features/auth/services/offline_sync_queue.dart`

### Funcionalidades

- Enfileira operações quando offline
- Sincroniza automaticamente quando volta online
- Retry com backoff exponencial
- Persistência da fila (sobrevive restart do app)
- Monitoramento de conectividade em tempo real

### Uso

```dart
final queue = ref.read(offlineSyncQueueProvider);

// Enfileirar uma operação
await queue?.enqueue(
  collection: 'moods',
  documentId: 'mood_123',
  type: SyncOperationType.update,
  data: moodData,
);

// Processar fila manualmente (normalmente automático)
final result = await queue?.processQueue();

// Verificar status
print('Pendentes: ${queue?.pendingCount}');
print('Online: ${queue?.isOnline}');
print('Sincronizando: ${queue?.isSyncing}');
```

### Providers

```dart
// Fila principal
final offlineSyncQueueProvider = Provider<OfflineSyncQueue?>

// Status da fila (stream)
final offlineSyncStatusProvider = StreamProvider<SyncQueueStatus>

// Conectividade (stream)
final isOnlineProvider = StreamProvider<bool>

// Quantidade pendente
final pendingSyncCountProvider = Provider<int>
```

### Status da Fila

```dart
class SyncQueueStatus {
  final int pendingCount;    // Operações pendentes
  final bool isSyncing;      // Se está sincronizando
  final bool isOnline;       // Se tem internet
  
  bool get hasPending;       // Se há pendentes
  bool get canSync;          // Se pode sincronizar
}
```

---

## 4. UI - Indicador de Sincronização

**Arquivo:** `lib/src/features/auth/presentation/widgets/sync_indicator.dart`

### Status Visuais

| Status | Ícone | Cor | Descrição |
|--------|-------|-----|-----------|
| disabled | cloud_off | cinza | Usuário guest ou sync desativado |
| offline | wifi_off | cinza | Sem conexão com internet |
| idle | cloud_done | primary | Tudo sincronizado |
| pending | cloud_upload | laranja | Operações aguardando sync |
| syncing | spinner | primary | Sincronizando |
| success | cloud_done | verde | Sync concluída |
| error | cloud_off | vermelho | Erro na sync |

### Uso

```dart
// Na AppBar
AppBar(
  actions: [
    SyncIndicator(showLabel: true),
  ],
)

// Compacto
SyncIndicator(compact: true, size: 16)
```

---

## 5. Dependências Adicionadas

```yaml
# pubspec.yaml
dependencies:
  firebase_storage: ^12.3.7
  connectivity_plus: ^6.1.1
```

---

## 6. Fluxo de Sincronização

```
┌─────────────┐     ┌──────────────┐     ┌────────────┐
│   Usuário   │────▶│ Hive (Local) │────▶│ SyncQueue  │
│  Edita Dado │     │    Box       │     │  (Fila)    │
└─────────────┘     └──────────────┘     └─────┬──────┘
                                               │
                    ┌──────────────────────────┤
                    │                          │
              ┌─────▼─────┐             ┌──────▼──────┐
              │  OFFLINE  │             │   ONLINE    │
              │  (Espera) │             │   (Sync)    │
              └─────┬─────┘             └──────┬──────┘
                    │                          │
                    │   Volta Online           │
                    └─────────────┬────────────┘
                                  │
                           ┌──────▼──────┐
                           │  Firestore  │
                           │   (Cloud)   │
                           └─────────────┘
```

---

## 7. Resolução de Conflitos - Detalhe

```
┌─────────────────┐     ┌─────────────────┐
│  Dados Locais   │     │ Dados Servidor  │
│ modified: 10:30 │     │ modified: 10:25 │
└────────┬────────┘     └────────┬────────┘
         │                       │
         └───────────┬───────────┘
                     │
              ┌──────▼──────┐
              │  Comparar   │
              │ Timestamps  │
              └──────┬──────┘
                     │
         ┌───────────┴───────────┐
         │                       │
    ┌────▼────┐            ┌─────▼─────┐
    │ Local   │            │ Servidor  │
    │ Mais    │            │ Mais      │
    │ Recente │            │ Recente   │
    └────┬────┘            └─────┬─────┘
         │                       │
         ▼                       ▼
   Usar Local              Manter Servidor
```

---

## 8. Configuração

### Inicializar no main.dart

A fila é inicializada automaticamente pelo provider quando o usuário faz login.

### Storage Rules (Firebase)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 9. Boas Práticas

1. **Sempre use os providers** - Não instancie serviços diretamente
2. **Verifique null** - Serviços retornam null para guests
3. **Não bloqueie a UI** - Use os streams para feedback visual
4. **Trate erros** - Sempre verifique `result.success` antes de usar dados

---

## 10. Sync Bidirecional (RealtimeSyncService)

**Arquivo:** `lib/src/features/auth/services/realtime_sync_service.dart`

### Funcionalidades

- Escuta mudanças no Firestore em tempo real
- Aplica automaticamente mudanças do servidor no Hive local
- Suporta pausar/resumir sync (útil durante edição)
- Configuração por categoria (moods, tasks, habits, etc.)

### Uso

```dart
// O serviço é iniciado automaticamente pelo provider
final realtimeSync = ref.watch(realtimeSyncServiceProvider);

// Pausar durante edição local para evitar conflitos
realtimeSync?.pauseSync();
// ... fazer edição ...
realtimeSync?.resumeSync();

// Stream de eventos de mudança
ref.listen(realtimeSyncEventsProvider, (_, event) {
  if (event.hasValue) {
    print('Mudança recebida: ${event.value!.collection}');
  }
});
```

### Configuração

```dart
// Atualizar configuração de sync
final service = ref.read(realtimeSyncServiceProvider);
service?.updateConfig(SyncConfig(
  moods: true,
  tasks: true,
  habits: false, // Desabilitar sync de hábitos
  // ...
));
```

---

## 11. Tela de Configurações de Sync

**Arquivo:** `lib/src/features/auth/presentation/screens/sync_settings_screen.dart`

### Funcionalidades

- Visualizar status de conexão e última sync
- Ver uso de storage na nuvem
- Habilitar/desabilitar sync por categoria
- Forçar upload ou download de todos os dados
- Limpar dados da nuvem

### Uso

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SyncSettingsScreen()),
);
```

---

## 12. Repositórios Sincronizados

Todos os repositórios principais agora usam o `SyncedRepositoryMixin` para enfileirar operações automaticamente:

| Repositório | Provider |
|-------------|----------|
| SyncedMoodRepository | `syncedMoodRepositoryProvider` |
| SyncedHabitRepository | `syncedHabitRepositoryProvider` |
| SyncedTaskRepository | `syncedTaskRepositoryProvider` |
| SyncedNotesRepository | `syncedNotesRepositoryProvider` |
| SyncedBookRepository | `syncedBookRepositoryProvider` |
| SyncedTimeTrackingRepository | `syncedTimeTrackingRepositoryProvider` |
| SyncedGamificationRepository | `syncedGamificationRepositoryProvider` |

### Migrar para Repositórios Sincronizados

```dart
// ANTES (sem sync)
final repo = ref.read(moodRecordRepositoryProvider);
await repo.createMoodRecord(record);

// DEPOIS (com sync automático)
final syncedRepo = ref.read(syncedMoodRepositoryProvider);
await syncedRepo.createMoodRecord(record);
// A operação é automaticamente enfileirada para sync!
```

---

## 13. Widgets de UI

### SyncIndicator

Mostra status de sync na AppBar:

```dart
AppBar(actions: [SyncIndicator(showLabel: true)])
```

### MigrationProgressWidget

Mostra progresso detalhado da migração:

```dart
if (migrationState.isInProgress)
  MigrationProgressWidget()
```

### MigrationStatusBadge

Badge compacto para mostrar status:

```dart
Row(children: [Text('Dados'), MigrationStatusBadge()])
```

### SyncLoadingOverlay

Overlay de loading para operações de sync:

```dart
Stack(children: [
  MyScreen(),
  if (isSyncing) SyncLoadingOverlay(message: 'Sincronizando...'),
])
```

---

## 14. Status Implementados ✅

- [x] Firebase Storage para imagens
- [x] Fila de sync offline
- [x] Resolução de conflitos baseada em timestamps
- [x] Sync bidirecional (cloud → local)
- [x] Tela de configurações de sync
- [x] Widgets de progresso de migração
- [x] Integração automática nos repositórios

---

## 15. Próximos Passos (Sugestões)

- [ ] Implementar dead letter queue para operações que falharam muitas vezes
- [ ] Adicionar notificações push quando há conflitos
- [ ] Implementar merge inteligente para campos específicos
- [ ] Adicionar histórico de versões para rollback
