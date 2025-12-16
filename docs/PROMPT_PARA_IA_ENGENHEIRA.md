# 🤖 PROMPT PARA IA ENGENHEIRA - REFATORAÇÃO COMPLETA DO DIARY

## 📋 CONTEXTO

Você é uma engenheira Flutter sênior especializada em clean architecture, design patterns e UX moderna. Está trabalhando no app **Odyssey** (baseado em Happio), um app de produtividade e bem-estar com múltiplas features (mood tracking, tasks, habits, notes, time tracker, library).

O app usa:
- **Flutter** com **Riverpod** (state management)
- **Hive** para storage local
- **Firebase** para notificações e analytics
- **GoRouter** para navegação
- Arquitetura **feature-first** com clean architecture
- Pattern de **SyncedRepository** para backup/sync (já implementado em outras features)

## 🎯 SUA MISSÃO

Refatorar COMPLETAMENTE a feature **Diary** que está muito básica (apenas 8 arquivos, sem domain layer, UI genérica, sem sync). Transformá-la na feature "hero" do app seguindo os padrões já estabelecidos nas outras features bem implementadas como `mood_records`, `time_tracker` e `library`.

## 📁 ESTRUTURA ATUAL DO DIARY

```
lib/src/features/diary/
├── data/
│   ├── models/
│   │   ├── diary_entry.dart (usando Freezed + Hive)
│   │   ├── diary_entry.freezed.dart
│   │   └── diary_entry.g.dart
│   └── repositories/
│       └── diary_repository.dart (SEM interface, SEM sync)
├── presentation/
│   ├── controllers/
│   │   └── diary_providers.dart (providers simples)
│   ├── pages/
│   │   ├── diary_page.dart (listagem básica)
│   │   └── diary_editor_page.dart (editor com Quill)
│   └── widgets/
│       └── feeling_selector_widget.dart
```

## 🔥 O QUE FAZER (CHECKLIST COMPLETO)

### FASE 1: ARQUITETURA (PRIORIDADE CRÍTICA)

**1.1 Criar Domain Layer Completo**

```dart
lib/src/features/diary/
├── domain/
│   ├── entities/
│   │   └── diary_entry_entity.dart
│   │       // Entidade pura (sem Hive, sem Freezed, apenas Dart puro)
│   │       // Campos: id, title, content, entryDate, feeling, tags, 
│   │       //         photoUrls, starred, searchableText, wordCount, readingTime
│   │
│   ├── repositories/
│   │   └── i_diary_repository.dart
│   │       // Interface abstrata com todos os métodos
│   │       // Usar Either<Failure, T> para error handling (ou sealed classes)
│   │
│   └── use_cases/
│       ├── get_all_entries_use_case.dart
│       ├── get_entries_paginated_use_case.dart
│       ├── create_entry_use_case.dart
│       ├── update_entry_use_case.dart
│       ├── delete_entry_use_case.dart
│       ├── search_entries_use_case.dart
│       ├── toggle_starred_use_case.dart
│       ├── get_diary_statistics_use_case.dart
│       ├── export_entries_use_case.dart
│       └── get_on_this_day_entries_use_case.dart
```

**1.2 Refatorar Data Layer**

```dart
lib/src/features/diary/
├── data/
│   ├── models/
│   │   └── diary_entry_model.dart
│   │       // Implementar toEntity() e fromEntity()
│   │       // Manter Hive e Freezed
│   │
│   ├── repositories/
│   │   ├── diary_repository_impl.dart
│   │   │   // Implementa i_diary_repository
│   │   │   // Usa data sources
│   │   │
│   │   └── synced_diary_repository.dart
│   │       // SEGUIR O PADRÃO DAS OUTRAS FEATURES!!!
│   │       // Ver: lib/src/features/habits/data/synced_habit_repository.dart
│   │       // Ver: lib/src/features/tasks/data/synced_task_repository.dart
│   │       // Auto-sync com Google Drive/Firebase
│   │       // Conflict resolution
│   │       // Offline-first
│   │
│   └── data_sources/
│       ├── diary_local_data_source.dart
│       │   // Hive operations isoladas
│       │   // Cache management
│       │
│       └── diary_remote_data_source.dart
│           // Firebase/Google Drive operations
│           // Upload photos
```

**1.3 Modernizar Presentation Layer**

```dart
lib/src/features/diary/
├── presentation/
│   ├── controllers/
│   │   ├── diary_controller.dart
│   │   │   // StateNotifier ou AsyncNotifier
│   │   │   // State granular (loading, success, error)
│   │   │   // Pagination logic
│   │   │
│   │   ├── diary_state.dart
│   │   │   // Sealed class ou Freezed
│   │   │   // Estados: initial, loading, loaded, error, empty
│   │   │
│   │   ├── diary_editor_controller.dart
│   │   │   // Auto-save logic
│   │   │   // Image upload handling
│   │   │
│   │   └── diary_statistics_controller.dart
│   │       // Compute stats
│   │
│   ├── pages/
│   │   ├── diary_home_page.dart (NOVO NOME)
│   │   ├── diary_editor_page.dart (REFATORAR)
│   │   ├── diary_insights_page.dart (NOVO)
│   │   ├── diary_calendar_view_page.dart (NOVO)
│   │   └── diary_settings_page.dart (NOVO)
│   │
│   └── widgets/
│       ├── diary_entry_card.dart (extrair de diary_page)
│       ├── diary_timeline_view.dart (NOVO)
│       ├── diary_grid_view.dart (NOVO)
│       ├── diary_search_bar.dart (NOVO)
│       ├── diary_filter_chips.dart (NOVO)
│       ├── diary_stats_header.dart (NOVO)
│       ├── feeling_selector_widget.dart (manter, melhorar)
│       ├── diary_toolbar_floating.dart (NOVO)
│       ├── diary_photo_picker.dart (NOVO)
│       ├── diary_photo_gallery.dart (NOVO)
│       ├── diary_template_selector.dart (NOVO)
│       ├── diary_export_dialog.dart (NOVO)
│       ├── diary_empty_state.dart (NOVO)
│       └── diary_loading_skeleton.dart (NOVO)
```

---

### FASE 2: UI/UX MODERNA (DESIGN INSPIRADO EM DAY ONE/JOURNEY)

**2.1 Diary Home Page (Listagem)**

Requisitos:
- ✨ **Timeline View** com cards elegantes
  - Sombras suaves, elevação Material 3
  - Gradientes baseados no feeling do dia
  - Hero animations para transição
  - Staggered animations na entrada (já tem lib no projeto)
  
- 📊 **Header com Stats**
  - Total de entradas, streak de dias
  - Mini gráfico de feelings da semana
  - Contador de palavras total
  
- 🔍 **Search + Filters**
  - Barra de busca com debounce (300ms)
  - Chips de filtro: tags, feelings, date range
  - Ordenação: recente, antiga, alfabética
  
- 📱 **View Modes**
  - Toggle grid/list/timeline
  - Calendar view (integrar table_calendar)
  
- 🎨 **Polish**
  - Pull-to-refresh customizado
  - Scroll infinito com paginação (20 entries/page)
  - FAB animado para nova entrada
  - Empty state bonito (ilustração + CTA)

**2.2 Diary Editor Page**

Requisitos:
- ✍️ **Editor Otimizado**
  - Quill toolbar FLOATING (aparece na seleção)
  - Minimizar toolbar quando não usa
  - Preview mode toggle
  - Markdown shortcuts (##, **, etc)
  
- 💾 **Auto-save Inteligente**
  - Save a cada 3s (debounced)
  - Indicador sutil "Salvando..." / "Salvo"
  - Conflict resolution se editou em outro device
  
- 📸 **Anexos de Mídia**
  - Image picker multi-select
  - Compressão automática (image_picker)
  - Gallery em grid dentro da entry
  - Lazy loading de thumbnails
  - Full screen viewer (photo_view)
  
- 📝 **Helpers de Escrita**
  - Contador de palavras live
  - Tempo estimado de leitura
  - Sugestões de tags baseadas no conteúdo
  - Templates disponíveis (ícone no header)
  
- 🎯 **UX Details**
  - Date picker customizado (pode editar data da entry)
  - Feeling selector horizontal
  - Tag chips com autocomplete
  - Confirmação antes de descartar (se tem changes)
  - Keyboard shortcuts (Ctrl+B, Ctrl+I, etc)

**2.3 Diary Insights Page (NOVA)**

Requisitos:
- 📊 **Estatísticas Visuais**
  - Gráfico de frequência (fl_chart)
  - Distribuição de feelings (pie chart)
  - Total de palavras escritas
  - Streak de dias consecutivos
  - Média de palavras por entry
  
- 🏷️ **Tags Analysis**
  - Lista de tags mais usadas
  - Gráfico de uso ao longo do tempo
  
- 📅 **On This Day**
  - Entries de anos anteriores neste dia
  - Shuffle de entry aleatória
  
- 🎨 **Design**
  - Cards com stats (estilo analytics_screen do app)
  - Animações ao entrar
  - Share stats as image

**2.4 Templates de Diário (NOVO)**

Implementar 5 templates:
1. **Diário Livre** (padrão, página em branco)
2. **Gratidão** (3 coisas boas do dia)
3. **Reflexão Guiada** (perguntas: como foi o dia? o que aprendi? desafios?)
4. **Mood Journal** (humor + eventos + reflexão)
5. **Bullet Journal** (lista de eventos/tarefas/notas)

UI: Modal bottom sheet com preview de cada template

---

### FASE 3: FEATURES AVANÇADAS

**3.1 Segurança**

```dart
lib/src/features/diary/
└── security/
    ├── biometric_auth_service.dart
    │   // local_auth package
    │   // Fingerprint/Face ID
    │
    └── diary_lock_screen.dart
        // PIN code fallback
        // Auto-lock after 5min
        // Mostrar antes de abrir diary
```

**3.2 Export/Share**

```dart
lib/src/features/diary/
└── export/
    ├── diary_exporter.dart
    │   // PDF export (com formatação)
    │   // Markdown export
    │   // JSON backup
    │
    └── diary_share_service.dart
        // Share entry as image
        // Share entry as text
        // Share via Share sheet
```

**3.3 Notificações**

```dart
lib/src/features/diary/
└── notifications/
    └── diary_reminder_service.dart
        // Daily reminder notification
        // Custom time picker
        // Integration com AwesomeNotifications (já no app)
```

**3.4 Gamification Integration**

```dart
// Adicionar conquistas no synced_gamification_repository:

achievements:
- "Primeiro Diário" (criar primeira entry)
- "Escritor Assíduo" (7 dias consecutivos)
- "Memórias Vívidas" (50 entries)
- "Historiador" (100 entries)
- "Reflexivo" (usar 20 tags diferentes)
- "Fotógrafo" (anexar 50 fotos)
- "Maratonista" (1000+ palavras em uma entry)

// XP por ações:
- Criar entry: +10 XP
- Entry com 500+ palavras: +20 XP
- Entry com foto: +5 XP
- 7 dias streak: +50 XP
```

---

### FASE 4: OTIMIZAÇÃO E PERFORMANCE

**4.1 Performance Improvements**

- ✅ Paginação (20 entries por load)
- ✅ Lazy loading de imagens
- ✅ Debounce em search (300ms)
- ✅ Cache de previews (searchableText)
- ✅ Index otimizado para busca no Hive
- ✅ Compute isolation para operações pesadas (stats)

**4.2 Code Quality**

- ✅ Error handling com try-catch em todos os use cases
- ✅ Loading states granulares
- ✅ Logging de erros (debugPrint)
- ✅ Analytics tracking (Firebase Analytics):
  - `diary_entry_created`
  - `diary_entry_updated`
  - `diary_entry_deleted`
  - `diary_search_performed`
  - `diary_export_completed`

**4.3 Accessibility**

- ✅ Semantics em todos os widgets
- ✅ Screen reader tested
- ✅ Font scaling support
- ✅ High contrast support

---

## 🎨 DESIGN SYSTEM

### Seguir os padrões do app:

**Cores e Tema:**
- Usar `Theme.of(context).colorScheme`
- Seguir Material 3 (já implementado no app)
- Dynamic color support (já tem)

**Widgets Reutilizáveis (já existem no app):**
- `OdysseyCard` (lib/src/utils/widgets/odyssey_card.dart)
- `FeedbackWidgets` (haptic feedback)
- `StaggeredListAnimation` (já usado em outras features)
- `SoundService` (tocar sons em ações)

**Animações:**
- Hero animations entre pages
- Staggered animations em listas
- Smooth transitions
- Spring animations (motor package já instalado)

**Typography:**
```dart
// Headers
Theme.of(context).textTheme.titleLarge // Títulos
Theme.of(context).textTheme.titleMedium // Subtítulos

// Body
Theme.of(context).textTheme.bodyLarge // Texto normal
Theme.of(context).textTheme.bodyMedium // Texto secundário

// Weights
FontWeight.w700 // Bold
FontWeight.w600 // Semi-bold
FontWeight.w500 // Medium
FontWeight.w400 // Regular
```

---

## 📦 PACKAGES A USAR

**Já instalados (use sem medo):**
- `flutter_riverpod` - state management
- `hive` + `hive_flutter` - storage
- `freezed` + `freezed_annotation` - immutability
- `flutter_quill` - rich text editor
- `image_picker` - pick images
- `intl` - dates/formatting
- `fl_chart` - charts
- `table_calendar` - calendar widget
- `awesome_notifications` - notifications
- `firebase_core` + `firebase_analytics` - analytics
- `shared_preferences` - settings
- `path_provider` - file paths
- `share_plus` - sharing

**Adicionar se necessário (você decide):**
- `local_auth` - biometric auth
- `pdf` - PDF generation
- `cached_network_image` - image caching
- `photo_view` - image viewer
- `flutter_cache_manager` - cache management
- `image_cropper` - crop images

---

## 🚨 REGRAS IMPORTANTES

### DEVE FAZER:
1. ✅ **SEGUIR O PADRÃO DE OUTRAS FEATURES**
   - Olhar como está implementado em `mood_records`, `time_tracker`, `library`
   - Usar `SyncedRepository` igual às outras features
   - Seguir mesma estrutura de pastas

2. ✅ **USAR LOCALIZATION**
   - Todas as strings via `AppLocalizations.of(context)!`
   - Adicionar keys necessárias em `lib/src/localization/app_localizations.dart`
   - Exemplo: `l10n.diary`, `l10n.newEntry`, `l10n.searchDiary`

3. ✅ **ERROR HANDLING ROBUSTO**
   - Try-catch em todos os lugares que fazem I/O
   - Mostrar SnackBar com erros user-friendly
   - Logging com `debugPrint` para debug

4. ✅ **PERFORMANCE FIRST**
   - Não carregar tudo de uma vez
   - Paginação obrigatória
   - Lazy loading de imagens
   - Debounce em buscas

5. ✅ **CLEAN CODE**
   - Funções pequenas e focadas
   - Nomenclatura clara
   - Comments apenas onde necessário
   - Separation of concerns

### NÃO DEVE FAZER:
1. ❌ **NÃO reinventar a roda** - use widgets/services existentes
2. ❌ **NÃO usar hardcoded strings** - sempre i18n
3. ❌ **NÃO fazer requests síncronos** - sempre async/await
4. ❌ **NÃO ignorar erros** - sempre handle exceptions
5. ❌ **NÃO deixar memory leaks** - dispose controllers/streams
6. ❌ **NÃO usar Navigator.push diretamente** - use GoRouter
7. ❌ **NÃO fazer builds gigantes** - extrair widgets

---

## 📝 EXEMPLO DE CÓDIGO (REFERÊNCIA)

### Use Case Pattern:
```dart
// domain/use_cases/create_entry_use_case.dart
class CreateEntryUseCase {
  final IDiaryRepository repository;
  
  CreateEntryUseCase(this.repository);
  
  Future<Either<Failure, DiaryEntryEntity>> call(DiaryEntryEntity entry) async {
    try {
      return Right(await repository.createEntry(entry));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
```

### Controller Pattern:
```dart
// presentation/controllers/diary_controller.dart
@riverpod
class DiaryController extends _$DiaryController {
  @override
  FutureOr<DiaryState> build() async {
    return await _loadEntries();
  }
  
  Future<DiaryState> _loadEntries({int page = 1}) async {
    try {
      final entries = await ref.read(diaryRepositoryProvider)
        .getEntriesPaginated(page: page, limit: 20);
      
      return DiaryState.loaded(entries: entries, hasMore: entries.length == 20);
    } catch (e) {
      return DiaryState.error(e.toString());
    }
  }
  
  Future<void> createEntry(DiaryEntryEntity entry) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(diaryRepositoryProvider).createEntry(entry);
      // Track analytics
      ref.read(analyticsServiceProvider).logEvent('diary_entry_created');
      // Add XP
      await ref.read(syncedGamificationRepositoryProvider).addXP(10);
      
      return await _loadEntries();
    });
  }
}
```

### Widget Pattern:
```dart
// presentation/widgets/diary_entry_card.dart
class DiaryEntryCard extends ConsumerWidget {
  final DiaryEntryEntity entry;
  
  const DiaryEntryCard({required this.entry});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Hero(
      tag: 'diary_${entry.id}',
      child: OdysseyCard(
        onTap: () => context.push('/diary/entry/${entry.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com data e feeling
            _buildHeader(context),
            
            // Título
            if (entry.title != null) _buildTitle(context),
            
            // Preview do conteúdo
            _buildContentPreview(context),
            
            // Tags
            if (entry.tags.isNotEmpty) _buildTags(context),
            
            // Footer com stats
            _buildFooter(context),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 CHECKLIST FINAL (VALIDAÇÃO)

Antes de considerar completo, verificar:

### Funcionalidades Core:
- [ ] CRUD completo de entries (create, read, update, delete)
- [ ] Auto-save funcionando (3s debounce)
- [ ] Sync com Google Drive/Firebase funcionando
- [ ] Busca com filtros (tags, feelings, date)
- [ ] Paginação funcionando (20/page)
- [ ] Anexar múltiplas fotos
- [ ] Templates de diário disponíveis
- [ ] Export para PDF/Markdown/JSON
- [ ] Share entry

### UI/UX:
- [ ] Timeline view elegante
- [ ] Grid view para entries com fotos
- [ ] Calendar view integrado
- [ ] Insights page com stats
- [ ] Empty states bonitos
- [ ] Loading states (skeletons)
- [ ] Error states informativos
- [ ] Animações suaves
- [ ] Hero transitions
- [ ] FAB animado
- [ ] Pull-to-refresh

### Integrações:
- [ ] Gamificação (XP + conquistas)
- [ ] Notificações diárias
- [ ] Analytics tracking
- [ ] Biometric lock (opcional mas recomendado)
- [ ] Sound effects em ações

### Performance:
- [ ] Lazy loading de imagens
- [ ] Paginação implementada
- [ ] Debounce em search
- [ ] Sem memory leaks
- [ ] Build time < 30s
- [ ] Scroll suave (60fps)

### Code Quality:
- [ ] Error handling em todos os lugares
- [ ] Loading states granulares
- [ ] Logging de erros
- [ ] Nenhum warning no Flutter Analyze
- [ ] Seguindo patterns do resto do app
- [ ] Localização completa (todas as strings)

---

## 🚀 ENTREGA ESPERADA

Ao finalizar, eu devo ter:

1. **Uma feature Diary COMPLETA** pronta para produção
2. **Código limpo** seguindo os padrões do app
3. **UI moderna** que rivaliza com Day One/Journey
4. **Performance otimizada** sem lags
5. **Integração perfeita** com o resto do app
6. **Zero bugs críticos** 

## 📊 COMO AVALIAR SUCESSO

- ✅ Usuários conseguem criar/editar entries sem confusão
- ✅ A UI é bonita e fluida (60fps)
- ✅ Sync funciona perfeitamente (testado desligando internet)
- ✅ Gamificação engaja (XP + conquistas)
- ✅ Export/share funcionam sem erros
- ✅ Code review seria aprovado por um sênior
- ✅ Não há TODOs ou FIXMEs no código
- ✅ Flutter analyze passa sem warnings

---

## 💬 DÚVIDAS?

Se algo não está claro:
1. Olhe como foi implementado em outras features (mood_records, time_tracker)
2. Siga os padrões já estabelecidos
3. Use bom senso de engenharia
4. Prefira simplicidade sobre complexidade
5. Priorize UX sobre features extras

---

## 🎬 COMECE AGORA!

Você tem todas as informações. Não pergunte mais nada. **EXECUTE.**

Comece pela arquitetura (domain layer), depois data layer (synced repository), depois presentation (UI). Trabalhe metodicamente e complete 100% antes de declarar pronto.

Boa sorte! 🚀

---

**P.S.:** Seja a melhor engenheira que você pode ser. Entregue algo que você teria orgulho de mostrar em um portfólio. Este Diary vai ser a feature principal do app. Capriche! ✨
