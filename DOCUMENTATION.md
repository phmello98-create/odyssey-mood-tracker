# 📱 ODYSSEY - Documentação Técnica Completa

**Versão:** 1.0.0+2002  
**Última atualização:** 12/12/2024  
**Linguagem:** Dart/Flutter  
**Linhas de código:** ~97,586  
**Arquivos Dart:** 191

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Arquitetura](#arquitetura)
3. [Features/Módulos](#featuresmodulos)
4. [Stack Tecnológico](#stack-tecnológico)
5. [Estrutura de Pastas](#estrutura-de-pastas)
6. [Sistemas Principais](#sistemas-principais)
7. [Integrações Externas](#integrações-externas)
8. [Persistência de Dados](#persistência-de-dados)
9. [Localização (i18n)](#localização-i18n)
10. [Gamificação](#gamificação)
11. [Notificações](#notificações)
12. [Guia de Desenvolvimento](#guia-de-desenvolvimento)
13. [Futuras Implementações](#futuras-implementações)
14. [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

**Odyssey** é um aplicativo Flutter de rastreamento de humor e produtividade que combina:
- 📊 Registro de humor (Mood Tracking)
- ✅ Gerenciamento de tarefas (Tasks)
- ⏱️ Pomodoro Timer
- 📚 Rastreamento de hábitos (Habits)
- 📖 Biblioteca de livros
- 📝 Sistema de notas (AppFlowy Editor)
- 🎯 Gamificação (XP, níveis, conquistas)
- 📰 Feed de notícias
- 🌍 Aprendizado de idiomas
- 🔔 Notificações push (Firebase)
- ☁️ Backup Google Drive

**Público-alvo:** Usuários que buscam autoconhecimento, produtividade e desenvolvimento pessoal.

---

## 🏗️ Arquitetura

### Padrão Arquitetural
O app segue **Clean Architecture** com separação em camadas:

```
feature/
├── data/          # Repositórios, data sources
├── domain/        # Modelos, entidades, lógica de negócio
└── presentation/  # UI, controllers, widgets
```

### State Management
- **Riverpod 2.x** - Provider padrão para todo o app
- **StateNotifier** - Gerenciamento de estado complexo
- **AutoDispose** - Limpeza automática de providers

### Navegação
- **GoRouter 7.x** - Roteamento declarativo
- Navegação por índice (PageView) na home
- Deep linking support

### Persistência
- **Hive** - Banco de dados NoSQL local
- **SharedPreferences** - Configurações simples
- **Google Drive** - Backup em nuvem

---

## 🧩 Features/Módulos

### 1. 📊 Analytics
**Localização:** `lib/src/features/analytics/`

**Descrição:** Visualização de dados de humor e hábitos com gráficos interativos.

**Componentes principais:**
- `analytics_screen.dart` - Tela principal
- `mood_variation_line_chart.dart` - Gráfico de linha (variação de humor)
- `mood_count_bar_chart.dart` - Gráfico de barras (contagem)
- `chart_frame_card.dart` - Container reutilizável para gráficos

**Dependências:**
- `fl_chart` - Biblioteca de gráficos

**Dados analisados:**
- Média de humor por dia/semana/mês
- Distribuição de atividades
- Correlações entre humor e atividades
- Streaks e consistência

---

### 2. 🎯 Mood Records
**Localização:** `lib/src/features/mood_records/`

**Descrição:** Sistema completo de registro de humor com atividades e notas.

**Estrutura:**
```
mood_records/
├── data/
│   └── mood_log/
│       └── mood_record_repository.dart
├── domain/
│   ├── mood_log/
│   │   └── mood_record.dart (Freezed + Hive)
│   └── add_mood_record/
│       └── mood_option.dart
└── presentation/
    ├── mood_log/
    │   ├── mood_log_screen.dart
    │   ├── mood_record_card.dart
    │   └── mood_record_card_options.dart
    └── add_mood_record/
        ├── add_mood_record_form.dart
        └── add_mood_record_form_controller.dart
```

**Modelos:**
```dart
@freezed
@HiveType(typeId: 0)
class MoodRecord with _$MoodRecord {
  factory MoodRecord({
    required String label,      // "Happy", "Sad", etc
    required int score,          // 1-5
    required String iconPath,    // Path do SVG
    required int color,          // Color value
    required DateTime date,
    String? note,
    List<Activity>? activities,
  }) = _MoodRecord;
}
```

**Atividades disponíveis:**
- **Social:** família, amigos, encontro, festa
- **Hobbies:** filmes & tv, leitura, jogos, relaxar
- **Sono:** dormir cedo, sono bom/médio/ruim
- **Saúde:** exercício, beber água, caminhar
- **Better Me:** meditação, bondade, ouvir, doar, dar presente
- **Chores:** compras, limpeza, cozinhar, lavar roupa

**Localização:**
- Categorias e atividades traduzidas (PT/EN)
- Funções helper: `getLocalizedCategoryName()`, `getLocalizedActivityName()`

---

### 3. ✅ Tasks
**Localização:** `lib/src/features/tasks/`

**Descrição:** Sistema de gerenciamento de tarefas com categorias, prioridades e datas.

**Componentes:**
- `tasks_screen.dart` - Lista de tarefas
- `task_repository.dart` - CRUD operations
- `task.dart` - Model (Freezed + Hive)

**Modelo:**
```dart
@HiveType(typeId: 1)
class Task {
  @HiveField(0) String title;
  @HiveField(1) String? description;
  @HiveField(2) bool isCompleted;
  @HiveField(3) DateTime? dueDate;
  @HiveField(4) DateTime? dueTime;
  @HiveField(5) String priority; // 'low', 'medium', 'high'
  @HiveField(6) String category;
  @HiveField(7) DateTime createdAt;
}
```

**Funcionalidades:**
- ✅ Marcar como concluída
- 📅 Agendar para data específica
- 🎨 Categorização personalizada
- ⚡ Priorização (baixa, média, alta)
- 🔄 Adiar para amanhã/depois de amanhã
- 📊 Filtros (todas, pendentes, concluídas)
- 🔍 Agrupamento por data (hoje, amanhã, atrasadas, esta semana)

---

### 4. ⏱️ Time Tracker (Pomodoro)
**Localização:** `lib/src/features/time_tracker/`

**Descrição:** Timer Pomodoro com rastreamento de sessões focadas.

**Componentes:**
- `time_tracker_screen.dart` - UI do timer
- `timer_provider.dart` - Estado do timer (Riverpod)
- `time_tracking_repository.dart` - Persistência de sessões

**Modelo:**
```dart
@HiveType(typeId: 3)
class TimeSession {
  @HiveField(0) DateTime startTime;
  @HiveField(1) DateTime? endTime;
  @HiveField(2) int durationMinutes;
  @HiveField(3) String? category;
  @HiveField(4) String? note;
  @HiveField(5) bool completed;
}
```

**Configurações:**
- ⏰ Duração da sessão (padrão: 25 min)
- ☕ Intervalo curto (5 min)
- 🛌 Intervalo longo (15 min)
- 🔔 Notificações de término
- 🎵 Sons ambiente (opcional)

**Providers principais:**
```dart
final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>
final timeTrackingRepositoryProvider = Provider<TimeTrackingRepository>
```

---

### 5. 📚 Habits
**Localização:** `lib/src/features/habits/`

**Descrição:** Sistema de rastreamento de hábitos com calendário e estatísticas.

**Componentes:**
- `habits_calendar_screen.dart` - Visualização em calendário
- `habit_repository.dart` - CRUD
- `habit.dart` - Model

**Modelo:**
```dart
@HiveType(typeId: 2)
class Habit {
  @HiveField(0) String name;
  @HiveField(1) String? description;
  @HiveField(2) int iconCodePoint;
  @HiveField(3) int color;
  @HiveField(4) List<bool> weekDays; // [seg, ter, qua, qui, sex, sab, dom]
  @HiveField(5) Map<String, bool> completedDates; // "2024-12-12": true
  @HiveField(6) DateTime createdAt;
  @HiveField(7) String? category;
}
```

**Funcionalidades:**
- 📅 Calendário mensal de visualização
- 🔥 Streak tracking (sequência de dias)
- ✅ Marcar/desmarcar dia
- 📊 Estatísticas (taxa de conclusão, dias consecutivos)
- 🎯 Hábitos personalizados
- 🌈 Cores e ícones customizáveis

---

### 6. 📖 Library
**Localização:** `lib/src/features/library/`

**Descrição:** Rastreador de livros lidos com integração Open Library API.

**Componentes:**
- `library_screen.dart` - Lista de livros
- `book_repository.dart` - CRUD
- `book.dart` - Model (Freezed + Hive)

**Modelo:**
```dart
@freezed
@HiveType(typeId: 4)
class Book with _$Book {
  factory Book({
    required String id,
    required String title,
    String? subtitle,
    String? author,
    String? coverUrl,
    String? isbn,
    String status, // 'toRead', 'reading', 'read', 'abandoned'
    int? rating,
    DateTime? startDate,
    DateTime? endDate,
    int? totalPages,
    int? currentPage,
    String? genre,
    String? notes,
    String? review,
    bool? isFavorite,
  }) = _Book;
}
```

**Integração Open Library:**
- 🔍 Busca de livros por título/autor/ISBN
- 📷 Download automático de capas
- 📚 Metadados automáticos (autor, ano, páginas)

**Status de leitura:**
- Para Ler
- Lendo
- Lido
- Abandonado

---

### 7. 📝 Notes
**Localização:** `lib/src/features/notes/`

**Descrição:** Editor de notas rico com AppFlowy Editor.

**Componentes:**
- `notes_screen.dart` - Lista de notas
- `note_editor_screen.dart` - Editor
- `note.dart` - Model

**Features do editor:**
- **Formatação:** negrito, itálico, sublinhado
- **Cores:** texto e fundo
- **Listas:** ordenadas e não ordenadas
- **Checklist:** para to-dos
- **Citações e código**
- **Markdown support**

**Dependência:**
- `appflowy_editor: ^6.1.0`

---

### 8. 🎮 Gamification
**Localização:** `lib/src/features/gamification/`

**Descrição:** Sistema de XP, níveis e conquistas para engajamento.

**Componentes:**
- `profile_screen.dart` - Perfil do usuário
- `gamification_repository.dart` - Lógica de XP
- `user_stats.dart` - Modelo de estatísticas
- `user_skills.dart` - Skills especializadas

**Modelo UserStats:**
```dart
@HiveType(typeId: 10)
class UserStats {
  @HiveField(0) int totalXP;
  @HiveField(1) int level;
  @HiveField(2) int currentLevelXP;
  @HiveField(3) int nextLevelXP;
  @HiveField(4) int streak;
  @HiveField(5) int totalDays;
  @HiveField(6) Map<String, int> skillLevels; // 'mood': 5, 'tasks': 3...
  @HiveField(7) List<String> achievements;
  @HiveField(8) DateTime lastActivity;
}
```

**Sistema de XP:**
- **Mood record:** +10 XP
- **Task completa:** +15 XP
- **Hábito completo:** +20 XP
- **Pomodoro completo:** +25 XP
- **Nota criada:** +5 XP
- **Livro terminado:** +50 XP
- **Streak diário:** +bonus XP

**Skills especializadas:**
- 🎯 Mood Mastery
- ✅ Task Warrior
- 🔥 Habit Hero
- ⏱️ Focus Champion
- 📚 Book Worm

**Níveis:**
- Cálculo: `level = floor(sqrt(totalXP / 100))`
- XP próximo nível: `(level + 1)^2 * 100`

---

### 9. 📰 News
**Localização:** `lib/src/features/news/`

**Descrição:** Feed de notícias com scraping de sites de notícias.

**Componentes:**
- `news_screen.dart` - Feed de notícias
- `news_scraper.dart` - Web scraping
- `news_image_fetcher.dart` - Busca imagens (Unsplash/Pexels)

**Sources:**
- CNN Brasil
- G1
- BBC Brasil
- El País
- The Guardian

**Funcionalidades:**
- 🔄 Refresh manual/automático
- 🖼️ Imagens de fallback (Unsplash/Pexels API)
- 🔗 Abrir notícia no navegador (WebView)
- 📱 Cache de imagens

---

### 10. 🌍 Language Learning
**Localização:** `lib/src/features/language_learning/`

**Descrição:** Sistema completo de rastreamento de aprendizado de idiomas.

**Componentes:**
- `language_learning_screen.dart` - Dashboard
- `language_detail_screen.dart` - Detalhes do idioma
- `immersion_screen.dart` - Rastreamento de imersão
- `daily_challenge_screen.dart` - Desafios diários
- `study_timer_screen.dart` - Timer de estudo

**Modelos:**

**Language:**
```dart
@HiveType(typeId: 20)
class Language {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String flag;
  @HiveField(3) String level; // 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'
  @HiveField(4) int totalMinutes;
  @HiveField(5) DateTime startDate;
  @HiveField(6) String? notes;
}
```

**StudySession:**
```dart
@HiveType(typeId: 21)
class StudySession {
  @HiveField(0) String id;
  @HiveField(1) String languageId;
  @HiveField(2) String activityType;
  @HiveField(3) int durationMinutes;
  @HiveField(4) DateTime date;
  @HiveField(5) int? rating;
  @HiveField(6) String? notes;
  @HiveField(7) String? resource;
}
```

**Activity Types:**
- 📖 Reading (Leitura)
- ✍️ Writing (Escrita)
- 🎧 Listening (Escuta)
- 🗣️ Speaking (Fala)
- 📚 Grammar (Gramática)
- 📝 Vocabulary (Vocabulário)
- 💬 Conversation (Conversação)
- 🎬 Immersion (Imersão)

**ImmersionLog:**
```dart
@HiveType(typeId: 24)
class ImmersionLog {
  @HiveField(0) String id;
  @HiveField(1) String languageId;
  @HiveField(2) String type;
  @HiveField(3) String title;
  @HiveField(4) int durationMinutes;
  @HiveField(5) DateTime date;
  @HiveField(6) int? rating;
  @HiveField(7) String? notes;
}
```

**Immersion Types:**
- 🎬 Movie (Filme)
- 📺 Series (Série)
- 🎭 Anime
- 🎵 Music (Música)
- 🎙️ Podcast
- 📱 YouTube
- 📖 Book (Livro)
- 🎮 Game (Jogo)
- 💬 Conversation (Conversa)
- 🌐 Social (Redes)
- 📰 News (Notícias)

**Features:**
- 📊 Estatísticas por atividade
- 🔥 Streak de dias estudados
- 🏆 Desafios diários
- ⏱️ Timer de estudo integrado
- 📈 Gráficos de progresso

---

### 11. 🏠 Home
**Localização:** `lib/src/features/home/`

**Descrição:** Dashboard principal com widgets personalizáveis.

**Componentes:**
- `home_screen.dart` - Dashboard principal (~4400 linhas!)
- `odyssey_home.dart` - Container principal com navegação
- `home_widgets_provider.dart` - Gerenciamento de widgets visíveis
- `widgets/` - Widgets modulares

**Widgets disponíveis:**
- **Quick Mood** - Log rápido de humor
- **Quick Pomodoro** - Iniciar timer
- **Daily Goals** - Progresso de metas diárias
- **Streak** - Sequência de dias
- **News Carousel** - Últimas notícias
- **Habit Summary** - Resumo de hábitos
- **Task Preview** - Tarefas pendentes
- **Stats Card** - Estatísticas gerais

**Customização:**
- Widgets podem ser ativados/desativados
- Ordem personalizável (drag & drop)
- Configuração salva em `SharedPreferences`

**Frases motivacionais:**
- Sistema de insights diários
- Frases estoicas, céticas e motivacionais
- Rotação aleatória

---

### 12. ⚙️ Settings
**Localização:** `lib/src/features/settings/`

**Descrição:** Configurações do app e gerenciamento de conta.

**Componentes:**
- `settings_screen.dart` - Menu de configurações
- `backup_screen.dart` - Google Drive backup
- `notification_settings_screen.dart` - Config de notificações
- `fcm_token_debug_screen.dart` - Debug de FCM

**Configurações disponíveis:**
- **Tema:** Claro, Escuro, Sistema
- **Idioma:** Português, Inglês
- **Notificações:** Habilitar/desabilitar
- **Sons:** Feedback sonoro
- **Hápticos:** Vibração
- **Backup:** Google Drive sync

**Backup Google Drive:**
- Autenticação via Google Sign-In
- Upload automático/manual
- Restauração de backup
- Export/Import JSON

---

### 13. 🔔 Notifications
**Localização:** `lib/src/utils/services/notification_service.dart`

**Descrição:** Sistema de notificações push e locais.

**Tecnologias:**
- **Firebase Cloud Messaging (FCM)**
- **Awesome Notifications** - Notificações locais
- **Timezone** - Agendamento

**Tipos de notificações:**
- 🎯 Lembrete de mood log
- ✅ Lembrete de tarefas
- 🔥 Lembrete de hábitos
- ⏰ Timer Pomodoro concluído
- 🏆 Conquistas desbloqueadas
- 📰 Novas notícias

**Configuração:**
- Canais separados por tipo
- Prioridade alta para lembretes
- Sons customizados
- Ações rápidas (mark as done, snooze)

**Providers:**
```dart
final notificationServiceProvider = Provider<NotificationService>
```

---

## 🛠️ Stack Tecnológico

### Core
- **Flutter SDK:** 3.x
- **Dart:** 3.0+
- **State Management:** Riverpod 2.6.1
- **Router:** GoRouter 7.1.1

### Persistência
- **Hive:** 2.2.3 - NoSQL local
- **SharedPreferences:** 2.5.3 - Configurações
- **Path Provider:** 2.1.1 - File system

### UI/UX
- **Material Design 3** - Componentes
- **Dynamic Color:** 1.6.3 - Cores dinâmicas
- **Flex Color Scheme:** 8.4.0 - Temas avançados
- **Lottie:** 3.1.0 - Animações
- **Motor:** 1.0.0 - Spring animations
- **FL Chart:** 1.1.1 - Gráficos

### Funcionalidades
- **AppFlowy Editor:** 6.1.0 - Editor de texto
- **Table Calendar:** 3.2.0 - Calendário
- **Timeline Tile:** 2.0.0 - Timeline UI
- **Image Picker:** 1.0.4 - Câmera/galeria
- **File Picker:** 10.3.7 - Seletor de arquivos
- **Share Plus:** 12.0.1 - Compartilhamento
- **URL Launcher:** 6.2.1 - Abrir links
- **Speech to Text:** 7.0.0 - Reconhecimento de voz

### Firebase
- **Firebase Core:** 3.8.1
- **Firebase Messaging:** 15.1.6 - Push notifications
- **Firebase Analytics:** 11.3.6 - Analytics
- **Firebase Remote Config:** 5.1.6 - Feature flags

### Google Services
- **Google Sign In:** 6.2.1
- **Google APIs:** 15.0.0 - Drive API
- **Extension Google Sign In:** 2.0.12

### Audio
- **Flutter SoLoud:** 3.4.6 - Sistema de som
- Biblioteca customizada de sons UI

### Networking
- **HTTP:** 1.6.0 - Requests
- **Flutter InAppWebView:** 6.0.0 - WebView

### Dev Tools
- **Freezed:** 2.5.2 - Code generation
- **Build Runner:** 2.4.13
- **Hive Generator:** 2.0.0
- **JSON Serializable:** 6.8.0
- **Flutter Gen:** 5.9.0 - Asset generation
- **Flutter Launcher Icons:** 0.14.3

---

## 📁 Estrutura de Pastas

```
odyssey/
├── android/                    # Código nativo Android
├── assets/                     # Assets estáticos
│   ├── mood_icons/            # SVGs de humor
│   ├── emojis/                # Lottie emojis
│   ├── sounds/                # Sistema de sons
│   │   ├── ambient/
│   │   └── ui/
│   │       ├── clicks/
│   │       ├── transitions/
│   │       ├── feedback/
│   │       ├── popups/
│   │       ├── notifications/
│   │       └── mood/
│   └── app_icon/              # Ícones do app
├── build/                      # Build artifacts
├── docs/                       # Documentação adicional
├── lib/
│   ├── gen/                   # Código gerado (assets)
│   ├── main.dart              # Entry point
│   └── src/
│       ├── app.dart           # MaterialApp config
│       ├── constants/         # Constantes globais
│       │   ├── app_theme.dart
│       │   └── app_sizes.dart
│       ├── features/          # Features modulares
│       │   ├── activities/
│       │   ├── analytics/
│       │   ├── auth/
│       │   ├── calendar/
│       │   ├── gamification/
│       │   ├── habits/
│       │   ├── home/
│       │   ├── language_learning/
│       │   ├── library/
│       │   ├── log/
│       │   ├── mood_records/
│       │   ├── news/
│       │   ├── notes/
│       │   ├── settings/
│       │   ├── splash/
│       │   ├── subscription/
│       │   ├── tasks/
│       │   └── time_tracker/
│       ├── localization/       # Internacionalização
│       │   ├── app_en.arb     # Inglês
│       │   ├── app_pt.arb     # Português
│       │   └── *.dart         # Gerado
│       ├── providers/          # Providers globais
│       │   ├── theme_provider.dart
│       │   └── language_provider.dart
│       ├── routing/            # Configuração de rotas
│       │   └── app_router.dart
│       └── utils/              # Utilitários
│           ├── services/       # Serviços
│           │   ├── notification_service.dart
│           │   ├── sound_service.dart
│           │   ├── haptic_service.dart
│           │   └── backup_service.dart
│           ├── widgets/        # Widgets reutilizáveis
│           │   ├── odyssey_card.dart
│           │   ├── feedback_widgets.dart
│           │   └── smart_quick_add.dart
│           ├── animations/     # Animações
│           ├── extensions/     # Extensions
│           ├── icon_map.dart   # Mapeamento de ícones
│           └── smart_classifier.dart
├── test/                       # Testes
├── .metadata
├── analysis_options.yaml       # Análise estática
├── l10n.yaml                   # Config de localização
├── pubspec.yaml               # Dependências
└── README.md
```

---

## 🔧 Sistemas Principais

### 1. Sistema de Som
**Localização:** `lib/src/utils/services/sound_service.dart`

**Biblioteca:** `flutter_soloud`

**Sons disponíveis:**
```
sounds/
├── ambient/
│   ├── rain.mp3
│   ├── ocean.mp3
│   └── forest.mp3
├── ui/
    ├── clicks/
    │   ├── soft_click.mp3
    │   └── button_press.mp3
    ├── transitions/
    │   ├── swipe.mp3
    │   └── page_turn.mp3
    ├── feedback/
    │   ├── success.mp3
    │   ├── error.mp3
    │   └── warning.mp3
    ├── popups/
    │   ├── modal_open.mp3
    │   └── modal_close.mp3
    ├── notifications/
    │   └── gentle_bell.mp3
    └── mood/
        ├── happy.mp3
        ├── neutral.mp3
        └── sad.mp3
```

**API:**
```dart
class SoundService {
  Future<void> playClick();
  Future<void> playSuccess();
  Future<void> playError();
  Future<void> playMoodSound(String mood);
  Future<void> playAmbient(String type);
  Future<void> stopAmbient();
  void setVolume(double volume);
}
```

---

### 2. Sistema de Feedback Háptico
**Localização:** `lib/src/utils/services/haptic_service.dart`

**Tipos de feedback:**
```dart
enum HapticType {
  light,      // Feedback leve
  medium,     // Feedback médio
  heavy,      // Feedback pesado
  selection,  // Seleção
  success,    // Sucesso
  warning,    // Aviso
  error,      // Erro
}
```

**Uso:**
```dart
HapticFeedback.selectionClick();
HapticFeedback.lightImpact();
HapticFeedback.mediumImpact();
HapticFeedback.heavyImpact();
```

---

### 3. Sistema de Temas
**Localização:** `lib/src/constants/app_theme.dart`

**Cores principais (UltravioletColors):**
```dart
class UltravioletColors {
  static const primary = Color(0xFF7C3AED);
  static const secondary = Color(0xFFEC4899);
  static const tertiary = Color(0xFF14B8A6);
  static const background = Color(0xFF1A1A2E);
  static const surface = Color(0xFF16213E);
  static const onSurface = Color(0xFFE4E4E7);
  static const onSurfaceVariant = Color(0xFFA1A1AA);
  // ... mais cores
}
```

**Provider:**
```dart
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>
```

**Modos:**
- Light
- Dark
- System (padrão)

---

### 4. Sistema de Localização (i18n)
**Localização:** `lib/src/localization/`

**Idiomas suportados:**
- 🇧🇷 Português (pt_BR) - PRINCIPAL
- 🇺🇸 Inglês (en)

**Arquivos:**
- `app_pt.arb` - ~960 strings
- `app_en.arb` - ~960 strings
- Gerados automaticamente: `app_localizations_*.dart`

**Uso:**
```dart
// Via context
AppLocalizations.of(context)!.taskCompleted

// Via extension
context.loc.taskCompleted
```

**Strings com parâmetros:**
```dart
// ARB
"tasksCompleted": "{count} de {total} tarefas concluídas"

// Uso
context.loc.tasksCompleted(5, 10)
// Output: "5 de 10 tarefas concluídas"
```

**Adicionar novas traduções:**
1. Adicionar em `app_pt.arb`
2. Adicionar em `app_en.arb`
3. Rodar `flutter gen-l10n`

---

### 5. Sistema de Navegação
**Localização:** `lib/src/routing/app_router.dart`

**Estrutura:**
```dart
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => OdysseyHome()),
      GoRoute(path: '/tasks', builder: (context, state) => TasksScreen()),
      GoRoute(path: '/notes', builder: (context, state) => NotesScreen()),
      // ... mais rotas
    ],
  );
});
```

**Navegação principal (PageView):**
```dart
PageView(
  controller: _pageController,
  children: [
    HomeScreen(),      // 0
    LogScreen(),       // 1
    MoodScreen(),      // 2
    TimerScreen(),     // 3
    ProfileScreen(),   // 4
  ],
)
```

**Provider de navegação:**
```dart
final navigationProvider = StateProvider<int>((ref) => 0);
```

---

## 💾 Persistência de Dados

### Hive Boxes

**Boxes registrados:**
```dart
// main.dart
await Hive.initFlutter();

// Registrar adapters
Hive.registerAdapter(MoodRecordAdapter());
Hive.registerAdapter(TaskAdapter());
Hive.registerAdapter(HabitAdapter());
Hive.registerAdapter(BookAdapter());
Hive.registerAdapter(TimeSessionAdapter());
Hive.registerAdapter(UserStatsAdapter());
Hive.registerAdapter(LanguageAdapter());
Hive.registerAdapter(StudySessionAdapter());
Hive.registerAdapter(ImmersionLogAdapter());
// ... mais adapters

// Abrir boxes
await Hive.openBox<MoodRecord>('mood_records');
await Hive.openBox<Task>('tasks');
await Hive.openBox('habits');
await Hive.openBox('books_v3');
await Hive.openBox('notes_v2');
await Hive.openBox('quotes');
await Hive.openBox('user_stats');
```

**Type IDs (IMPORTANTE - não duplicar!):**
```dart
0  - MoodRecord
1  - Task
2  - Habit
3  - TimeSession
4  - Book
10 - UserStats
11 - UserSkills
20 - Language
21 - StudySession
22 - VocabularyEntry
23 - Resource
24 - ImmersionLog
```

**Padrão de Repository:**
```dart
class MoodRecordRepository {
  final Box<MoodRecord> _box;
  
  MoodRecordRepository(this._box);
  
  // CRUD operations
  Future<void> createMoodRecord(MoodRecord record) {
    return _box.add(record);
  }
  
  List<MoodRecord> getAllMoodRecords() {
    return _box.values.toList();
  }
  
  MoodRecord? getMoodRecord(dynamic key) {
    return _box.get(key);
  }
  
  Future<void> updateMoodRecord(dynamic key, MoodRecord record) {
    return _box.put(key, record);
  }
  
  Future<void> deleteMoodRecord(dynamic key) {
    return _box.delete(key);
  }
}

// Provider
final moodRecordRepositoryProvider = Provider<MoodRecordRepository>((ref) {
  final box = Hive.box<MoodRecord>('mood_records');
  return MoodRecordRepository(box);
});
```

---

## 🎮 Sistema de Gamificação

### Cálculo de XP

**Fórmula de nível:**
```dart
int calculateLevel(int totalXP) {
  return (sqrt(totalXP / 100)).floor();
}
```

**XP necessário para próximo nível:**
```dart
int xpForNextLevel(int currentLevel) {
  return pow((currentLevel + 1), 2).toInt() * 100;
}
```

**Exemplo:**
- Level 0: 0 XP
- Level 1: 100 XP
- Level 2: 400 XP
- Level 3: 900 XP
- Level 10: 10.000 XP

### Conquistas (Achievements)

**Lista de conquistas:**
```dart
enum Achievement {
  firstMoodLog,        // Primeiro registro de humor
  firstTaskCompleted,  // Primeira tarefa concluída
  firstHabit,          // Primeiro hábito criado
  streak7Days,         // 7 dias consecutivos
  streak30Days,        // 30 dias consecutivos
  mood100Logs,         // 100 registros de humor
  tasks50Completed,    // 50 tarefas concluídas
  habits10Created,     // 10 hábitos criados
  books5Read,          // 5 livros lidos
  pomodoro50Sessions,  // 50 sessões Pomodoro
  level10Reached,      // Nível 10 alcançado
  level25Reached,      // Nível 25 alcançado
  explorer,            // Explorou todas as features
  // ... adicionar mais
}
```

**Desbloquear conquista:**
```dart
Future<void> unlockAchievement(Achievement achievement) async {
  final stats = await getUserStats();
  if (!stats.achievements.contains(achievement.name)) {
    stats.achievements.add(achievement.name);
    stats.totalXP += 100; // Bonus XP
    await saveUserStats(stats);
    _showAchievementNotification(achievement);
  }
}
```

---

## 🔔 Sistema de Notificações

### Firebase Cloud Messaging (FCM)

**Setup:**
```dart
// main.dart
await Firebase.initializeApp();

final messaging = FirebaseMessaging.instance;

// Solicitar permissão
await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

// Obter token
final token = await messaging.getToken();
print('FCM Token: $token');

// Handlers
FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
```

**Notificações locais:**
```dart
class NotificationService {
  final AwesomeNotifications _notifications;
  
  Future<void> initialize() async {
    await _notifications.initialize(
      'resource://drawable/notification_icon',
      [
        NotificationChannel(
          channelKey: 'mood_reminders',
          channelName: 'Lembretes de Humor',
          channelDescription: 'Lembretes diários para registrar seu humor',
          importance: NotificationImportance.High,
          defaultColor: UltravioletColors.primary,
          playSound: true,
        ),
        // ... mais canais
      ],
    );
  }
  
  Future<void> scheduleMoodReminder() async {
    await _notifications.createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'mood_reminders',
        title: 'Como você está se sentindo?',
        body: 'Registre seu humor de hoje',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: 20,
        minute: 0,
        repeats: true,
      ),
    );
  }
}
```

---

## 📊 Widgets Reutilizáveis

### OdysseyCard
**Localização:** `lib/src/utils/widgets/odyssey_card.dart`

Container estilizado padrão do app.

```dart
OdysseyCard(
  padding: EdgeInsets.all(16),
  child: Text('Conteúdo'),
)
```

### FeedbackWidgets
**Localização:** `lib/src/utils/widgets/feedback_widgets.dart`

**Componentes:**
- `SuccessToast` - Toast de sucesso
- `ErrorToast` - Toast de erro
- `LoadingIndicator` - Indicador de carregamento
- `EmptyState` - Estado vazio
- `ErrorState` - Estado de erro

### AnimatedStats
**Localização:** `lib/src/utils/widgets/animated_stats.dart`

Números animados com efeito de contagem.

```dart
AnimatedStats(
  value: 1234,
  duration: Duration(seconds: 2),
  style: TextStyle(fontSize: 24),
)
```

---

## 🧪 Guia de Desenvolvimento

### Setup Inicial

1. **Instalar Flutter:**
```bash
flutter doctor
```

2. **Clonar e instalar dependências:**
```bash
git clone <repo>
cd odyssey
flutter pub get
```

3. **Gerar código:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Gerar localizações:**
```bash
flutter gen-l10n
```

5. **Rodar:**
```bash
flutter run
# ou
flutter run -d chrome  # web
```

### Adicionar Nova Feature

1. **Criar estrutura:**
```bash
lib/src/features/minha_feature/
├── data/
│   └── minha_feature_repository.dart
├── domain/
│   └── minha_feature_model.dart
└── presentation/
    └── minha_feature_screen.dart
```

2. **Criar modelo Hive:**
```dart
// domain/minha_feature_model.dart
import 'package:hive/hive.dart';

part 'minha_feature_model.g.dart';

@HiveType(typeId: 25) // USAR PRÓXIMO ID DISPONÍVEL!
class MinhaFeature extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  MinhaFeature({
    required this.id,
    required this.name,
  });
}
```

3. **Registrar adapter:**
```dart
// main.dart
Hive.registerAdapter(MinhaFeatureAdapter());
await Hive.openBox<MinhaFeature>('minha_feature');
```

4. **Criar repository:**
```dart
// data/minha_feature_repository.dart
class MinhaFeatureRepository {
  final Box<MinhaFeature> _box;
  
  MinhaFeatureRepository(this._box);
  
  List<MinhaFeature> getAll() => _box.values.toList();
  Future<void> add(MinhaFeature item) => _box.add(item);
}

final minhaFeatureRepositoryProvider = Provider<MinhaFeatureRepository>((ref) {
  final box = Hive.box<MinhaFeature>('minha_feature');
  return MinhaFeatureRepository(box);
});
```

5. **Criar screen:**
```dart
// presentation/minha_feature_screen.dart
class MinhaFeatureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(minhaFeatureRepositoryProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Minha Feature')),
      body: ListView(
        children: repository.getAll().map((item) {
          return ListTile(title: Text(item.name));
        }).toList(),
      ),
    );
  }
}
```

### Adicionar Tradução

1. **Adicionar em PT:**
```json
// lib/src/localization/app_pt.arb
{
  "minhaFeature": "Minha Feature",
  "minhaFeatureDescription": "Descrição da feature"
}
```

2. **Adicionar em EN:**
```json
// lib/src/localization/app_en.arb
{
  "minhaFeature": "My Feature",
  "minhaFeatureDescription": "Feature description"
}
```

3. **Gerar:**
```bash
flutter gen-l10n
```

4. **Usar:**
```dart
Text(context.loc.minhaFeature)
```

### Debug

**Hive Inspector:**
```dart
// Imprimir conteúdo de um box
final box = Hive.box('mood_records');
print('Total items: ${box.length}');
box.toMap().forEach((key, value) {
  print('$key: $value');
});
```

**Provider Inspector:**
```dart
// Usar Riverpod DevTools
// flutter pub global activate devtools
// flutter pub global run devtools
```

**Logs:**
```dart
debugPrint('Debug message');
print('Normal log');
```

### Build Release

**Android:**
```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## 🚀 Futuras Implementações

### Prioridade ALTA ⭐⭐⭐

#### 1. **Sistema de Backup Automático**
- 🎯 **Objetivo:** Sincronização automática em segundo plano
- 📂 **Localização sugerida:** `lib/src/features/settings/data/auto_backup_service.dart`
- 🔧 **Implementação:**
  - Usar `WorkManager` para agendar backups periódicos
  - Opções: diário, semanal, mensal
  - Versionamento de backups (manter últimos 5)
  - Indicador visual de último backup
- 📦 **Dependências:** `workmanager: ^0.5.0`

#### 2. **Exportação de Relatórios (PDF)**
- 🎯 **Objetivo:** Gerar relatórios mensais/anuais em PDF
- 📂 **Localização sugerida:** `lib/src/features/analytics/data/report_generator.dart`
- 🔧 **Implementação:**
  - Relatório de humor com gráficos
  - Relatório de produtividade (tarefas, hábitos, pomodoro)
  - Estatísticas gerais
  - Compartilhar via Share API
- 📦 **Dependências:** `pdf: ^3.10.0`, `printing: ^5.11.0`

#### 3. **Widget de Tela Inicial (Android)**
- 🎯 **Objetivo:** Widget para quick add na home screen
- 📂 **Localização sugerida:** `lib/src/features/widgets/`
- 🔧 **Implementação:**
  - Widget de mood log rápido
  - Widget de timer Pomodoro
  - Widget de próxima tarefa
- 📦 **Dependências:** `home_widget: ^0.4.0`

#### 4. **Dark Mode Adaptativo com Cores de Acentuação**
- 🎯 **Objetivo:** Temas personalizáveis com Material You
- 📂 **Localização sugerida:** `lib/src/constants/app_theme.dart`
- 🔧 **Implementação:**
  - Picker de cores customizado
  - Preview em tempo real
  - Presets de temas (Violet, Blue, Green, Red)
  - Salvar preferência
- 📦 **Dependências:** `flutter_colorpicker: ^1.0.0`

---

### Prioridade MÉDIA ⭐⭐

#### 5. **Integração com Calendário do Sistema**
- 🎯 **Objetivo:** Sincronizar tarefas com calendário nativo
- 📂 **Localização sugerida:** `lib/src/features/tasks/data/calendar_sync_service.dart`
- 🔧 **Implementação:**
  - Exportar tarefas para Google Calendar
  - Importar eventos do calendário
  - Sincronização bidirecional
- 📦 **Dependências:** `device_calendar: ^4.5.0`

#### 6. **Sistema de Tags para Tarefas e Notas**
- 🎯 **Objetivo:** Organização avançada com tags
- 📂 **Localização sugerida:** `lib/src/features/tags/`
- 🔧 **Implementação:**
  - CRUD de tags
  - Filtros por tags
  - Busca por tags
  - Cores personalizadas
- 🗄️ **Modelo:**
```dart
@HiveType(typeId: 26)
class Tag {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) int color;
  @HiveField(3) String icon;
}
```

#### 7. **Modo Offline Completo**
- 🎯 **Objetivo:** App 100% funcional sem internet
- 📂 **Localização sugerida:** `lib/src/utils/services/offline_service.dart`
- 🔧 **Implementação:**
  - Queue de sincronização
  - Cache de imagens
  - Indicador de status offline
  - Sync automático ao reconectar
- 📦 **Dependências:** `connectivity_plus: ^5.0.0`

#### 8. **Análise de Sentimentos com IA**
- 🎯 **Objetivo:** Analisar notas e sugerir insights
- 📂 **Localização sugerida:** `lib/src/features/mood_records/data/sentiment_analyzer.dart`
- 🔧 **Implementação:**
  - Integração com ML Kit (Google)
  - Análise de texto das notas
  - Sugestões baseadas em padrões
  - Insights personalizados
- 📦 **Dependências:** `google_mlkit_text_recognition: ^0.10.0`

---

### Prioridade BAIXA ⭐

#### 9. **Modo Colaborativo (Família/Equipe)**
- 🎯 **Objetivo:** Compartilhar hábitos/tarefas com outros usuários
- 📂 **Localização sugerida:** `lib/src/features/collaboration/`
- 🔧 **Implementação:**
  - Backend Firebase/Supabase
  - Convites por email
  - Sincronização em tempo real
  - Permissões (view/edit)
- 📦 **Dependências:** `cloud_firestore: ^4.13.0`

#### 10. **Integração com Smartwatch**
- 🎯 **Objetivo:** Controlar timer e registrar mood no relógio
- 📂 **Localização sugerida:** `lib/src/features/wearables/`
- 🔧 **Implementação:**
  - Wear OS app
  - Apple Watch app
  - Notificações no relógio
  - Quick actions
- 📦 **Dependências:** `wear: ^1.1.0`

#### 11. **Modo Foco (Bloqueio de Apps)**
- 🎯 **Objetivo:** Bloquear apps distrativos durante Pomodoro
- 📂 **Localização sugerida:** `lib/src/features/time_tracker/data/focus_mode_service.dart`
- 🔧 **Implementação:**
  - Lista de apps bloqueados
  - Timer de bloqueio
  - Exceções de emergência
  - Estatísticas de uso
- 📦 **Dependências:** `app_usage: ^2.0.0` (Android only)

#### 12. **Chatbot de Bem-Estar**
- 🎯 **Objetivo:** Assistente virtual para suporte emocional
- 📂 **Localização sugerida:** `lib/src/features/chatbot/`
- 🔧 **Implementação:**
  - Integração com ChatGPT/Gemini
  - Respostas baseadas em contexto do usuário
  - Sugestões personalizadas
  - Check-ins diários
- 📦 **Dependências:** `chat_gpt_sdk: ^2.2.0` ou `google_generative_ai: ^0.2.0`

---

### Melhorias de Performance 🚀

#### 13. **Lazy Loading de Listas Longas**
- 🎯 **Problema:** Listas de humor/tarefas ficam lentas com muitos itens
- 🔧 **Solução:** Implementar paginação e virtual scrolling
- 📂 **Arquivos a modificar:**
  - `lib/src/features/mood_records/presentation/mood_log_screen.dart`
  - `lib/src/features/tasks/presentation/tasks_screen.dart`
- 📦 **Dependências:** `infinite_scroll_pagination: ^4.0.0`

#### 14. **Otimização de Imagens**
- 🎯 **Problema:** Capas de livros pesadas
- 🔧 **Solução:** Compressão e cache eficiente
- 📂 **Arquivos a modificar:**
  - `lib/src/features/library/data/book_repository.dart`
- 📦 **Dependências:** `cached_network_image: ^3.3.0`, `flutter_image_compress: ^2.1.0`

#### 15. **Service Locator com GetIt**
- 🎯 **Problema:** Muitos providers globais
- 🔧 **Solução:** Centralizar injeção de dependências
- 📂 **Criar:** `lib/src/utils/service_locator.dart`
- 📦 **Dependências:** `get_it: ^7.6.0`

---

### Features Experimentais 🧪

#### 16. **Modo Noturno Inteligente**
- Ajusta tema automaticamente baseado em horário e localização
- Usa sensor de luz ambiente

#### 17. **Reconhecimento de Emoções por Voz**
- Analisar tom de voz para detectar humor
- 📦 **Dependências:** `audio_waveforms: ^1.0.0`

#### 18. **Realidade Aumentada para Visualização de Progresso**
- Visualizar estatísticas em AR
- 📦 **Dependências:** `ar_flutter_plugin: ^0.7.0`

#### 19. **Integração com Wearables de Saúde**
- Importar dados de sono/exercício do Google Fit/Apple Health
- 📦 **Dependências:** `health: ^10.0.0`

#### 20. **Sistema de Recompensas Reais**
- Integração com programas de fidelidade
- Descontos por metas atingidas

---

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Erro de Build Runner
```bash
# Limpar cache
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. Erro de Hive TypeId Duplicado
**Sintoma:** `HiveError: TypeId already registered`

**Solução:** Verificar `DOCUMENTATION.md` seção "Type IDs" e usar próximo ID disponível.

#### 3. Ícones não aparecem (Tree Shaking)
**Sintoma:** `non-constant IconData`

**Solução:** Usar métodos helper como `StudyActivityTypes.getIcon()` ao invés de `IconData(code, ...)`.

#### 4. Localização não funciona
```bash
flutter gen-l10n
flutter run
```

#### 5. Firebase não inicializa
- Verificar `google-services.json` em `android/app/`
- Verificar `GoogleService-Info.plist` em `ios/Runner/`
- Rodar `flutterfire configure`

#### 6. Sons não tocam
- Verificar permissões no AndroidManifest
- Verificar paths em `assets/sounds/`
- Testar em device real (emulador pode ter problemas)

#### 7. Notificações não aparecem
**Android:**
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

**Código:**
```dart
// Solicitar permissão
await AwesomeNotifications().requestPermissionToSendNotifications();
```

---

## 📞 Contato e Contribuição

### Estrutura de Issues
Ao reportar bugs ou sugerir features, usar template:

```markdown
## Tipo
- [ ] Bug
- [ ] Feature Request
- [ ] Melhoria
- [ ] Documentação

## Descrição
[Descrição clara e concisa]

## Passos para Reproduzir (se bug)
1. ...
2. ...

## Comportamento Esperado
[O que deveria acontecer]

## Comportamento Atual
[O que está acontecendo]

## Screenshots
[Se aplicável]

## Ambiente
- OS: [Android/iOS/Web]
- Versão do App: 1.0.0+2002
- Device: [Modelo]
```

---

## 📚 Recursos Adicionais

### Documentação de Dependências
- [Flutter](https://flutter.dev/docs)
- [Riverpod](https://riverpod.dev/)
- [Hive](https://docs.hivedb.dev/)
- [GoRouter](https://pub.dev/packages/go_router)
- [FL Chart](https://pub.dev/packages/fl_chart)
- [Firebase](https://firebase.flutter.dev/)

### Code Style Guide
- Seguir [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Usar `flutter analyze` antes de commits
- Máximo 120 caracteres por linha
- Sempre usar trailing commas

### Git Workflow
```bash
# Feature branch
git checkout -b feature/nome-da-feature

# Commits semânticos
git commit -m "feat: adiciona sistema de tags"
git commit -m "fix: corrige erro no mood log"
git commit -m "docs: atualiza documentação"

# Push e PR
git push origin feature/nome-da-feature
```

---

## 🎓 Glossário

- **Mood:** Humor/estado emocional
- **Streak:** Sequência consecutiva de dias
- **XP:** Experience Points (pontos de experiência)
- **Pomodoro:** Técnica de produtividade (25 min foco + 5 min pausa)
- **Gamificação:** Elementos de jogo aplicados ao app
- **Hive:** Banco de dados NoSQL local
- **Provider:** Gerenciador de estado
- **Repository:** Camada de acesso a dados
- **ARB:** Application Resource Bundle (arquivos de tradução)
- **FCM:** Firebase Cloud Messaging

---

## 📝 Changelog

### v1.0.0+2002 (12/12/2024)
- ✨ Sistema de localização completo (PT/EN)
- 🐛 Correção de tree-shaking de ícones
- 📚 Documentação técnica completa
- 🎨 Melhorias no tema Ultraviolet
- 🔔 Sistema de notificações otimizado

---

**Última atualização:** 12/12/2024  
**Mantenedor:** Odyssey Team  
**Licença:** Proprietary

---

*Esta documentação é um documento vivo e deve ser atualizada conforme o app evolui.*
