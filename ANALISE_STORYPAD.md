# 📖 Análise Completa do StoryPad - Diário Open Source

## 1. **Estrutura de Arquitetura**

### 1.1 Organização de Pastas
```
lib/
├── core/                          # Camada de negócio e dados
│   ├── databases/                 # ObjectBox + modelos
│   │   ├── models/               # Modelos de dados (Freezed-like)
│   │   ├── adapters/objectbox/   # Adapters ObjectBox
│   │   └── legacy/               # Migração SQLite antigo
│   ├── services/                 # Serviços de negócio
│   ├── objects/                  # Objetos de domínio
│   ├── storages/                 # Preferências/cache local
│   ├── types/                    # Enums e tipos
│   ├── extensions/               # Extensions Dart
│   ├── helpers/                  # Funções auxiliares
│   ├── mixins/                   # Mixins reutilizáveis
│   └── initializers/             # Inicializadores do app
├── views/                        # UI seguindo MVVM
│   ├── home/                     # Tela principal (timeline)
│   ├── stories/                  # Criar/editar/visualizar entradas
│   ├── search/                   # Busca avançada
│   ├── templates/                # Templates de diário
│   ├── calendar/                 # Calendário de humor/período
│   ├── library/                  # Biblioteca de fotos/áudio
│   ├── tags/                     # Gerenciamento de tags
│   ├── settings/                 # Configurações
│   └── backup_services/          # Backup Google Drive
├── widgets/                      # Widgets reutilizáveis
│   ├── base_view/                # ViewModelProvider
│   ├── bottom_sheets/            # Bottom sheets personalizados
│   ├── calendar/                 # Componentes de calendário
│   ├── story_list/               # Lista de stories
│   └── quill/                    # Customizações Quill
└── providers/                    # Providers globais (Provider)
    ├── backup_provider.dart
    ├── tags_provider.dart
    ├── in_app_purchase_provider.dart
    └── device_preferences_provider.dart
```

### 1.2 Padrão MVVM Implementado
**Cada feature segue:**
```dart
views/stories/edit/
├── edit_story_view.dart          // Constrói ViewModel + navegação
├── edit_story_content.dart       // UI pura (sem lógica)
├── edit_story_view_model.dart    // Lógica de negócio
└── local_widgets/                // Widgets locais da feature
```

**Separação de responsabilidades:**
- **Model**: `core/databases/models/` (dados + persistência)
- **View**: `*_view.dart` + `*_content.dart` (UI)
- **ViewModel**: `*_view_model.dart` (ChangeNotifier com lógica)

---

## 2. **Stack Tecnológica**

### 2.1 Principais Dependências
```yaml
# Editor de texto rico
flutter_quill: (fork customizado)  # Editor Quill com customizações

# Persistência
objectbox: 5.0.2                   # Banco de dados local NoSQL
sqflite: 2.4.2                     # Usado apenas para migração legada

# State Management
provider: 6.1.5+1                  # Provider (não Riverpod!)

# Backup/Sync
google_sign_in: 7.2.0              # Autenticação Google
googleapis: 15.0.0                 # Google Drive API
firebase_storage: 13.0.4           # Firebase Storage (assets)
cloud_firestore: 6.1.0             # Firestore (analytics)

# Mídia
image_picker: 1.2.1                # Seleção de fotos
record: 6.1.2                      # Gravação de áudio
just_audio: 0.10.5                 # Reprodução de áudio
audio_service: 0.18.18             # Áudio em background

# UI/UX
animations: 2.1.1                  # Animações Material
dynamic_color: 1.8.1               # Material You theming
google_fonts: 6.3.2                # 1300+ fontes Google
flutter_slidable: 4.0.3            # Swipe actions

# Monetização
purchases_flutter: 9.9.7           # RevenueCat (IAP)
in_app_review: 2.0.11             # Review prompt
in_app_update: 4.2.5              # Android updates

# Localização
easy_localization: 3.0.8           # i18n (20+ idiomas)

# Utilidades
freezed-like: copy_with_extension  # Immutability (não Freezed!)
json_annotation: 4.9.0             # Serialização JSON
```

### 2.2 Arquitetura de Dados
- **ObjectBox**: Banco NoSQL principal (rápido, sem SQL)
- **SharedPreferences**: Preferências do usuário
- **Flutter Secure Storage**: Tokens e dados sensíveis
- **Firebase**: Analytics, Remote Config, Crashlytics

---

## 3. **Principais Funcionalidades**

### 3.1 Timeline de Diário (Home)
- **View infinita**: Scroll por anos (swipe horizontal)
- **Agrupamento por data**: Stories organizadas por mês/dia
- **Throwback memories**: "Neste dia anos atrás"
- **Filtros**: Por ano, tag, favoritos
- **Multi-seleção**: Edição em lote (arquivar, deletar, tag)

### 3.2 Editor de Stories (Flutter Quill)
**Customizações importantes:**
```dart
// lib/views/stories/edit/edit_story_view_model.dart
- Suporte multi-páginas (1 story = N páginas)
- Auto-save em draft
- Detecção de mudanças (revert se não editou)
- Embed de imagens e áudio inline
- Rich text: negrito, listas, checkbox, cores, fontes
```

**Estrutura de dados:**
```dart
StoryDbModel {
  year, month, day, hour, minute   // Data customizável
  starred: bool                    // Favoritos
  feeling: String?                 // Emoji de humor
  tags: List<int>                  // Tags
  assets: List<int>                // Fotos/áudio
  latestContent: StoryContentDbModel  // Conteúdo publicado
  draftContent: StoryContentDbModel?  // Rascunho
  preferences: StoryPreferencesDbModel // Estilos da story
  type: PathType                   // docs/bins/archives
}

StoryContentDbModel {
  title: String
  plainText: String                // Para busca
  richPages: List<StoryPageDbModel> // Multi-páginas
}

StoryPageDbModel {
  title: String
  body: List<dynamic>              // Quill Delta JSON
}
```

### 3.3 Sistema de Templates
**Gallery Templates** (YAML):
```yaml
# templates/1_daily_reflection.yaml
category: "Daily Reflection"
templates:
  - id: "daily_check_in"
    name: "Daily Check-in"
    purpose: "Capture daily thoughts"
    pages:
      - title: "How are you feeling today?"
        content: ""
      - title: "What's been on your mind?"
        content: ""
```

**Custom Templates** (usuário cria):
- Salva no DB como `TemplateDbModel`
- Aplica conteúdo + preferências ao criar story
- Suporta multi-páginas e estilos

### 3.4 Busca Avançada
**Search Metadata** (pré-computado):
```dart
// Indexação ao salvar story:
searchMetadata = "${title}\n${plainText}"  // Concatenado

// Busca rápida (ObjectBox):
StoryObjectBox_.searchMetadata.contains(query, caseSensitive: false)
```

**Filtros combinados:**
```dart
SearchFilterObject {
  query: String?            // Texto livre
  years: Set<int>           // Anos específicos
  month, day: int?          // Data específica
  tagId: int?               // Tag
  starred: bool?            // Favoritos
  assetId: int?             // Stories com foto/áudio específico
  types: PathType           // docs/bins/archives
}
```

### 3.5 Sistema de Tags
- **Criação livre**: Usuário define cores
- **Auto-tagging**: Templates podem ter tags padrão
- **Asset tagging**: Fotos/áudio herdam tags das stories
- **Contagem**: Mostra quantas stories por tag

### 3.6 Calendário de Período
**Add-on premium:**
```dart
EventDbModel.period(date: DateTime)  // Marca dia do período
```
- Calendário visual com scroll infinito
- Integração com stories (cria entrada ao clicar)
- Histórico de ciclos

### 3.7 Voice Journal (Diário de Voz)
**Fluxo completo:**
```
1. Gravar áudio → VoiceRecorderService
2. Salvar → AssetDbModel (type: audio, metadata: {durationInMs})
3. Embed → BlockEmbed.audio("storypad://audio/123")
4. Backup → Google Drive (automático)
5. Biblioteca → Voice tab com filtros por tag
```

**Player customizado:**
- Drag para seek
- Speed control (1x, 1.5x, 2x)
- Reprodução em background
- Design minimalista (inspirado Telegram)

### 3.8 Biblioteca de Assets
**Tabs separadas:**
- **Images**: Grid de fotos com filtro por tag
- **Voice**: Lista de áudios com duração e status de backup

**Status de backup:**
```dart
🟡 Pendente (needBackup: true)
🟢 Backup completo
🔴 Erro (sem internet)
```

### 3.9 Backup Google Drive
**Estratégia v3 (Yearly Backups):**
```
appDataFolder/
  ├── backups/
  │   ├── Backup::3::2025::1734350000::iPhone.zip
  │   └── Backup::3::2024::1704067200::iPhone.zip
  ├── images/
  │   └── 1234567890.jpg
  └── audio/
      └── 1234567891.m4a
```

**Sync em 4 passos:**
1. **Upload Assets**: Fotos/áudios pendentes
2. **Check & Download**: Busca backups no Drive
3. **Import**: Merge por timestamp (newer wins)
4. **Upload Backups**: Envia backups atualizados

**Conflito resolution:**
- Timestamp-based (newer wins)
- Per-record comparison
- No deletion sync (deletar não propaga)

### 3.10 Relaxing Sounds (Add-on)
**Multi-audio player:**
- Mix de sons ambiente (rain, ocean, forest, etc.)
- Controle de volume individual
- Save mixes
- Timer de parada
- Notification controls

---

## 4. **Modelos de Dados**

### 4.1 Story (Entrada do Diário)
```dart
@CopyWith()
@JsonSerializable()
class StoryDbModel extends BaseDbModel {
  final int id;                    // Timestamp-based
  final int version;               // Schema version
  final PathType type;             // docs/bins/archives
  
  // Data customizável
  final int year, month, day;
  final int? hour, minute, second;
  
  // Metadata
  final bool? starred;
  final String? feeling;           // Emoji code
  final List<String>? tags;        // Tag IDs (como strings)
  final List<int>? assets;         // Asset IDs
  
  // Conteúdo
  final StoryContentDbModel? latestContent;
  final StoryContentDbModel? draftContent;
  
  // Estilos
  final StoryPreferencesDbModel? preferences;
  
  // Templates
  final String? galleryTemplateId;
  final int? templateId;
  final int? eventId;              // Period calendar
  
  // Lifecycle
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? movedToBinAt;
  final DateTime? permanentlyDeletedAt;
  final String? lastSavedDeviceId;
}
```

### 4.2 Asset (Foto/Áudio)
```dart
@CopyWith()
@JsonSerializable()
class AssetDbModel extends BaseDbModel {
  final int id;
  final AssetType type;            // Enum: image | audio
  final String originalSource;     // Path local
  final Map<String, dynamic>? metadata; // {durationInMs: 120000}
  final List<int>? tags;           // Herdadas das stories
  
  // Cloud destinations
  final Map<String, Map<String, Map<String, String>>> cloudDestinations;
  // cloudDestinations[google_drive][email] = {file_id, file_name}
  
  // Computed
  String get embedLink => type.buildEmbedLink(id);
  // "storypad://audio/123" ou "storypad://assets/456"
  
  int? get durationInMs => metadata?['duration_in_ms'];
  String? get formattedDuration; // "02:34"
}
```

### 4.3 Template
```dart
@CopyWith()
@JsonSerializable()
class TemplateDbModel extends BaseDbModel {
  final int id;
  final int index;                 // Ordem customizada
  final String? name;
  final String? note;
  final List<int>? tags;           // Tags padrão
  final StoryContentDbModel? content;
  final StoryPreferencesDbModel? preferences;
  final String? galleryTemplateId; // Ref ao gallery
  final DateTime? archivedAt;
}
```

### 4.4 Tag
```dart
@CopyWith()
@JsonSerializable()
class TagDbModel extends BaseDbModel {
  final int id;
  final String title;
  final int? colorValue;           // Color.value
  final int index;                 // Ordem
  final DateTime? archivedAt;
}
```

---

## 5. **UI/UX Patterns**

### 5.1 Theming System
```dart
DevicePreferencesObject {
  ThemeMode themeMode;             // light/dark/system
  Color? colorSeed;                // Material You seed
  String? fontFamily;              // 1300+ Google Fonts
  FontSizeOption fontSize;         // small/normal/large/extraLarge
  FontWeight fontWeight;
  TimeFormatOption timeFormat;     // 12h/24h
}

// Por-story preferences:
StoryPreferencesDbModel {
  colorSeed, colorTone;            // Tema customizado
  fontFamily, fontSize, fontWeight;
  titleFontFamily, titleFontWeight, titleExpanded;
  PageLayoutType layoutType;       // list/grid/pages
  starIcon, showDayCount, showTime;
}
```

### 5.2 Layouts de Visualização
**3 layouts para stories:**
1. **List**: Timeline vertical clássica
2. **Grid**: Grid de cards (inspirado Instagram)
3. **Pages**: Fullscreen swipeable (livro)

### 5.3 Bottom Sheets Personalizados
**Padrão consistente:**
```dart
class BaseBottomSheet {
  Future<T?> show<T>(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => this,
    );
  }
}

// Exemplos:
- SpVoiceRecordingSheet: Gravar áudio
- SpVoicePlaybackSheet: Reproduzir áudio
- SpImagePickerBottomSheet: Escolher foto
- SpFontsSheet: Selecionar fonte
- SpShareStoryBottomSheet: Compartilhar
```

### 5.4 Navegação
- **Navigator 1.0** (não 2.0)
- **BaseRoute** pattern:
```dart
class EditStoryRoute extends BaseRoute {
  final int? id;
  final int? initialYear;
  // ...
  
  @override
  Widget build(BuildContext context) {
    return EditStoryView(params: this);
  }
}
```

### 5.5 Componentes Reutilizáveis
- **SpCalendar**: Calendário infinito horizontal
- **SpStoryList**: Lista de stories com listener
- **SpStoryTile**: Card de story (multi-layout)
- **SpScrollableChoiceChips**: Chips com contagem
- **SpVoicePlayer**: Player de áudio (Telegram-style)

---

## 6. **Features Destacadas**

### 6.1 🌟 Throwback Memories
```dart
// Busca stories do mesmo dia/mês em outros anos
DateTime.now().year == year
  ? StoryDbModel.db.where(
      month: DateTime.now().month,
      day: DateTime.now().day,
      excludeYears: {DateTime.now().year},
    )
  : null
```

### 6.2 🎨 Customização Total
- **Por-device**: Tema global, fonte, tamanho
- **Por-story**: Cores, fonte, layout individuais
- **1300+ fontes**: Google Fonts integrado

### 6.3 📸 Multi-Asset Support
- **Inline embeds**: Fotos e áudio no meio do texto
- **Gallery layouts**: Grid de fotos em stories
- **Cloud sync**: Backup automático de assets

### 6.4 🔍 Busca Poderosa
- **Full-text**: Busca em títulos e conteúdo
- **Fuzzy matching**: Biblioteca `fuzzy` para relevância
- **Filtros combinados**: Ano + tag + favoritos + tipo

### 6.5 🔄 Multi-device Sync
- **Google Drive**: Backup privado e criptografado
- **Conflict resolution**: Timestamp-based merge
- **Incremental**: Sync apenas mudanças

### 6.6 🎭 Privacy-First
- **Local-first**: Tudo funciona offline
- **App Lock**: PIN/biometria
- **Google Drive privado**: appDataFolder (invisível)
- **No tracking**: Dados não saem do dispositivo/Drive

### 6.7 🎤 Voice Journaling
- **Gravação inline**: Durante a escrita
- **Player minimalista**: Drag to seek, speed control
- **Auto-tagging**: Áudio herda tags da story
- **Biblioteca**: Tab separada com filtros

### 6.8 📅 Period Calendar
- **Visual tracking**: Calendário de ciclo menstrual
- **Story integration**: Cria entradas ao clicar
- **Private**: Dados locais + Google Drive

---

## 7. **Diferenças do Nosso App (Odyssey)**

| Feature | StoryPad | Odyssey |
|---------|----------|---------|
| **Database** | ObjectBox | Hive |
| **State Management** | Provider | Riverpod |
| **Editor** | Flutter Quill | AppFlowy Editor |
| **Routing** | Navigator 1.0 | GoRouter |
| **Immutability** | copy_with_extension | Freezed |
| **Timeline** | Horizontal years | Vertical tabs (5 screens) |
| **Humor tracking** | Feeling emojis (45+) | Mood records (atividades) |
| **Multi-páginas** | Sim (1 story = N pages) | Não (1 note = 1 page) |
| **Templates** | Sim (gallery + custom) | Não |
| **Voice journal** | Sim (add-on premium) | Não |
| **Period calendar** | Sim (add-on premium) | Não |
| **Backup** | Google Drive (yearly) | Google Drive (monolítico) |
| **Monetização** | RevenueCat IAP | Nenhuma ainda |
| **Layouts** | 3 tipos (list/grid/pages) | 1 tipo (list) |
| **Localização** | 20+ idiomas | Português |

---

## 8. **Implementação no Odyssey**

### 8.1 Plano de Integração

#### **Opção 1: Feature completa (recomendado)**
Adicionar "Diário" como **6ª aba** no bottom navigation:

```dart
// lib/main.dart - Atualizar PageView
PageView(
  children: [
    HomeScreen(),      // Aba 1
    LogScreen(),       // Aba 2  
    MoodScreen(),      // Aba 3
    TimerScreen(),     // Aba 4
    ProfileScreen(),   // Aba 5
    DiaryScreen(),     // Aba 6 ← NOVO
  ],
)
```

**Escopo reduzido para MVP:**
- Timeline de diário (ano atual)
- Editor Quill básico (texto + fotos)
- Busca simples (texto)
- Backup Google Drive (usar nosso sistema)
- **SEM**: Templates, voice journal, period calendar (add-ons)

#### **Opção 2: Menu "Mais"**
Adicionar no menu "More" (como Settings, Notes, etc.):

```dart
// lib/features/profile/presentation/widgets/profile_tools_grid.dart
{
  'icon': Icons.book,
  'label': 'Diário',
  'route': '/diary',
}
```

Mais simples de integrar, mas menos destaque.

### 8.2 Adaptações Necessárias

#### **1. Converter de ObjectBox para Hive**
```dart
// StoryPad usa:
@Entity()
class StoryObjectBox { ... }

// Nosso adaptar para:
@HiveType(typeId: X)
class DiaryEntryModel extends HiveObject {
  @HiveField(0) int id;
  @HiveField(1) DateTime date;
  @HiveField(2) String title;
  @HiveField(3) String content; // Quill Delta JSON
  @HiveField(4) List<String> photoIds;
  @HiveField(5) bool starred;
  @HiveField(6) String? feeling;
}
```

#### **2. Converter de Provider para Riverpod**
```dart
// StoryPad usa:
class HomeViewModel extends ChangeNotifier { ... }

// Nosso adaptar para:
@riverpod
class DiaryController extends _$DiaryController {
  @override
  FutureOr<List<DiaryEntry>> build() async {
    return await ref.read(diaryRepositoryProvider).getEntries();
  }
}
```

#### **3. Integrar Flutter Quill**
```dart
// pubspec.yaml
dependencies:
  flutter_quill: ^10.8.7

// lib/features/diary/presentation/widgets/diary_editor.dart
QuillEditor(
  controller: _quillController,
  scrollController: ScrollController(),
  focusNode: FocusNode(),
  configurations: QuillEditorConfigurations(
    padding: EdgeInsets.all(16),
    customStyles: DefaultStyles(...),
  ),
)
```

#### **4. Reutilizar Backup Existente**
```dart
// lib/features/diary/data/repositories/diary_repository.dart
class DiaryRepositoryImpl {
  Future<void> backup() async {
    final entries = await _getAllEntries();
    final json = jsonEncode(entries.map((e) => e.toJson()).toList());
    
    // Usar nosso BackupService existente
    await ref.read(backupServiceProvider).uploadFile(
      'diary_backup.json',
      utf8.encode(json),
    );
  }
}
```

### 8.3 Cronograma Estimado

**Fase 1: MVP (2-3 semanas)**
- [ ] Setup Hive models (DiaryEntry)
- [ ] Repository + Riverpod providers
- [ ] Timeline UI (lista simples)
- [ ] Editor Quill básico
- [ ] CRUD (criar, ler, editar, deletar)
- [ ] Busca por texto
- [ ] Backup Google Drive

**Fase 2: Polish (1-2 semanas)**
- [ ] Favoritos (starred)
- [ ] Emojis de humor (feeling)
- [ ] Fotos inline (usando nosso asset system)
- [ ] Filtros (ano, favoritos)
- [ ] Animações e transições

**Fase 3: Advanced (futuro)**
- [ ] Templates (gallery + custom)
- [ ] Multi-páginas
- [ ] Voice journal
- [ ] Layouts alternativos
- [ ] Period calendar

---

## 9. **Conclusão**

### 9.1 Pontos Fortes do StoryPad
✅ **Arquitetura limpa**: MVVM bem estruturado  
✅ **Privacy-first**: Local + Google Drive privado  
✅ **Customização total**: Temas, fontes, layouts  
✅ **Multi-asset**: Fotos + áudio inline  
✅ **Templates**: Gallery + custom  
✅ **Backup inteligente**: Yearly, conflict resolution  
✅ **Open source**: GPL v3 (podemos estudar e adaptar)

### 9.2 Complexidades
⚠️ **ObjectBox**: Precisamos portar para Hive  
⚠️ **Provider**: Precisamos converter para Riverpod  
⚠️ **Multi-páginas**: Feature complexa (não prioridade)  
⚠️ **Templates**: Sistema robusto (pode ser simplificado)  
⚠️ **Voice journal**: Requer permissions e player  

### 9.3 Recomendação Final

**Implementar versão simplificada no Odyssey:**

1. **Como**: 6ª aba no bottom navigation (destaque)
2. **Escopo MVP**: Timeline + Editor Quill + Fotos + Busca
3. **Reutilizar**: Nosso backup, nosso asset system, nosso theme
4. **Inspiração**: StoryPad (não cópia direta)
5. **Diferencial**: Integração com Mood tracker (humor + diário)

**ROI esperado:**
- **Dev time**: 2-3 semanas MVP
- **User value**: Alta (diário é feature pedida)
- **Diferencial**: Única app mood tracker + diário integrados
- **Monetização**: Pode ser premium (como templates no StoryPad)

---

## 10. **Referências**

- **Repo**: https://github.com/theachoem/storypad
- **App Store**: https://apps.apple.com/app/storypad/id6744032172
- **Play Store**: https://play.google.com/store/apps/details?id=com.tc.writestory
- **Docs**: `/docs` folder no repo
- **License**: GPL v3.0 (open source, copyleft)
