# 📱 Estrutura da HomeScreen - Odyssey Mood Tracker

> **Arquivo:** `lib/src/features/home/presentation/home_screen.dart`  
> **Última atualização:** 18/12/2024

---

## 📋 Estrutura Completa (Top → Bottom)

### **1. HEADER (Top Bar)**
**Widget:** `_WellnessHeader` (Linhas 5758-5903)

**Componentes:**
- Avatar do usuário (clicável → Perfil)
- Saudação dinâmica ("Bom dia/Boa tarde/Boa noite, [Nome]")
- Botão Calendário (ícone `calendar_today_rounded`)
- Botão Add (+) com destaque visual

**Funcionalidades:**
- `onMenuTap` → Navega para Profile
- `onCalendarTap` → Abre HabitsCalendarScreen
- `onAddTap` → Abre Smart Add Sheet

---

### **2. BARRA DE BUSCA GLOBAL**
**Widget:** `GlobalSearchBar` (Linha 362-365)

**Funcionalidade:**
- Busca universal no app (tarefas, notas, hábitos, etc)

---

### **3. ACTIVITY CARD (Visão Geral do Dia)**
**Widget:** `_DayOverviewCard` (Linhas 5908-6267)

**Grid 3x2 com 6 cards:**

| Card | Ícone | Métrica | Ação |
|------|-------|---------|------|
| **Tarefas** | `check_circle_outline` | Contador pendentes | → TasksScreen |
| **Ideias** | `lightbulb_outline` | Notas capturadas | → NotesScreen |
| **Humor** | `sentiment_*` | Último registro | → AddMoodRecordForm |
| **Timer** | `timer` | Tempo ativo/registrado | → Timer Tab |
| **Pomodoro** | `fire` | Sessões completadas | → Timer (Pomodoro) |

**Features:**
- Indicador visual quando timer está ativo (borda + badge pulsante)
- Cores dinâmicas baseadas em prioridade/estado
- Animações de loading

---

### **4. SUGESTÕES INTELIGENTES**
**Widget:** `HomeSuggestionsWidget` (Linha 381-386)

**Funcionalidade:**
- Sugestões contextuais baseadas em histórico
- Sistema de machine learning local
- Adapta-se ao comportamento do usuário

---

### **5. INSPIRAÇÃO DO DIA**
**Widget:** `_buildDailyQuoteWidget()` (Linhas 970-1062)

**Design:**
- Card com gradiente roxo (`WellnessColors.purpleGradient`)
- Ícone de citação
- Título "Inspiração do Dia"

**Conteúdo:**
- Frase motivacional/filosófica (array `_dailyInsights`)
- Barra de progresso do dia (ex: "Dia 18/30")
- Troca automática a cada 30 segundos

**Fontes:**
- Frases céticas/estoicas
- Maslow, Viktor Frankl, Carl Rogers
- Epicteto, Sêneca, Marco Aurélio
- Zen/Mindfulness

---

### **6. MOOD CHECK-IN / COMUNIDADE**
**Widget:** `_buildMoodSection()` (Linhas 1226-1350)

**Layout:**
- Avatar circular
- Pergunta: "Como você está se sentindo?"
- Subtitle: "Registre seu humor do momento ✨"

**5 Botões de Humor:**

| SVG | Label | Cor | Score |
|-----|-------|-----|-------|
| `smile.svg` | Ótimo | Verde (`WellnessColors.success`) | 5 |
| `calm.svg` | Bem | Roxo (`WellnessColors.primary`) | 4 |
| `neutral.svg` | Ok | Amarelo (`Colors.amber`) | 3 |
| `sad.svg` | Mal | Laranja (`Colors.orange`) | 2 |
| `loudly_crying.svg` | Péssimo | Vermelho (`WellnessColors.error`) | 1 |

**Footer:**
- Ícones: ❤️ 48 | 💬 12 | 🔗 (mock data)

---

### **7. WIDGETS DINÂMICOS CONFIGURÁVEIS**
**Widget:** `_buildDynamicWidgets()` (Linhas 578-602)

**Sistema de Widgets Habilitáveis:**

| Widget | Tipo | Função |
|--------|------|--------|
| `QuickNotesWidget` | Atalho | Criar nota rápida |
| `StreakWidget` | Progresso | Sequências de hábitos |
| `TodayTasksWidget` | Lista | Tarefas do dia |
| `QuickPomodoroWidget` | Timer | Pomodoro compacto |
| `CurrentReadingWidget` | Leitura | Livro atual |
| `DailyGoalsWidget` | Metas | Objetivos diários |
| `ActivityGridWidget` | Heatmap | Calendário de atividade |
| `QuickMoodWidget` | Registro | Mood rápido |
| `WeekCalendar` | Calendário | Semana |
| `MonthlyOverview` | Resumo | Mês |

**Gerenciamento:**
- Provider: `enabledHomeWidgetsProvider`
- Animação: `FadeTransition` + `SizeTransition`

---

### **8. SEÇÃO COMUNIDADE**
**Widget:** `_buildCommunitySection()` (Linhas 604-750)

**Header:**
- Ícone `people_rounded` com fundo roxo
- Título "Comunidade"
- Botão "Ver tudo" → `CommunityScreen`

**Preview de Posts:**
- Últimos 3 posts do feed
- Cada post mostra:
  - Avatar com nível
  - Nome do usuário
  - Tempo relativo ("2h", "1d", etc)
  - Conteúdo (máx 2 linhas)
  - Contador de likes/comentários

**Botão CTA:**
- "Compartilhar algo" → `CreatePostScreen`

**Estado Vazio:**
- Ícone de grupo
- Texto: "Seja o primeiro!"
- Botão: "Criar Primeiro Post"

---

### **9. NAVEGAÇÃO DE MÊS**
**Widget:** Inline (Linha 456-491)

**Componentes:**
- Chevron esquerda (`Icons.chevron_left`)
- Nome do mês capitalizado (ex: "Dezembro 2024")
- Chevron direita (`Icons.chevron_right`)

**Funções:**
- `_previousMonth()` / `_nextMonth()`
- Atualiza `_selectedMonth`

---

### **10. SEÇÃO HÁBITOS/TAREFAS**
**Widget:** `_buildHabitsTasksSection()` (Linhas 1512-1609)

**Tab Bar:**
- 2 tabs: "Hábitos" | "Tarefas"
- Animação de slide

**Calendário Semanal:**
- 7 dias (S-D)
- Destaque no dia selecionado
- Botão "expandir" para calendário mensal

**Calendário Mensal (Overlay):**
- Popup sobre o conteúdo
- Grid completo do mês
- Navegação entre meses
- Botão "Pronto" para fechar

**Lista de Conteúdo:**
- **Hábitos:** Checkboxes com progresso
- **Tarefas:** Lista com prioridade e tags
- Filtro: Mostrar/Ocultar concluídos

---

### **11. ESTATÍSTICAS RÁPIDAS**
**Widget:** `_buildQuickStats()` (Linha 506-511)

**Métricas:**
- Cards compactos com números agregados
- Cores diferenciadas por categoria

---

### **12. GRÁFICO SEMANAL**
**Widget:** `_buildWeeklyChart()` (Linha 516-521)

**Visualização:**
- Barras verticais (S-D)
- Altura proporcional à atividade
- Destaque no dia atual
- Gradiente verde-água (`#26A69A`)

---

### **13. INSIGHTS BASEADOS EM DADOS**
**Widget:** `_buildDataInsights()` (Linha 526-531)

**Funcionalidade:**
- Análises automáticas de padrões
- Sugestões baseadas em dados

---

### **14. NOTAS E LEITURAS (Side by Side)**

**Widget Esquerdo:** `_buildNotesWidget()` (Linhas 5062-5152)
- Ícone: `sticky_note_2_outlined`
- Contador: "X notas"
- Última nota (título)
- Cor: Terciária

**Widget Direito:** `_buildReadingsWidget()` (Linhas 5157-5263)
- Ícone: `menu_book_outlined`
- Contador: "X lendo"
- Livro atual (título)
- Cor: Secundária

**Layout:**
- Row com 2 Expanded
- Gap de 12px
- Altura fixa: 120px
- Border radius: 20px

---

### **15. RESUMO MENSAL**
**Widget:** `_buildMonthlyOverview()` (Linha 552-557)

**Conteúdo:**
- Visão agregada do mês
- Estatísticas consolidadas

---

### **16. WIDGET DE NOTÍCIAS** ⭐
**Widget:** `_NewsCarouselWidget` (Linhas 5290-5754)

**Header:**
- Ícone `newspaper_rounded` (vermelho `#FF6B6B`)
- Título "Notícias"
- Contador: "1/6"
- Botões:
  - ⏭️ "Skip next" (próxima notícia)
  - 🔗 "Ver mais" → `NewsScreen`

**Carrossel:**
- Auto-slide a cada 5 segundos
- Swipe horizontal para navegar
- Cada notícia mostra:
  - Imagem (64x64, canto esquerdo)
  - Título (máx 2 linhas)
  - Fonte (ícone `public` + nome)
  - Ícone "abrir link" (`open_in_new`)

**Indicadores:**
- Dots na parte inferior
- Destaque no item ativo
- Máximo 6 notícias

**Fontes de Dados:**
1. **Primária:** Google News RSS (via rss2json.com)
2. **Fallback:** Wikipedia "Featured Today"

**Sistema de Imagens:**
- Fetch assíncrono via `NewsImageFetcher`
- Cache local de imagens
- Placeholder quando não disponível

**Padding Final:**
- `EdgeInsets.fromLTRB(20, 0, 20, 100)`
- Espaço extra no bottom para navegação

---

## 🎨 **Design System**

### **Cores Principais:**
- Primary: `WellnessColors.primary` (Roxo)
- Success: `WellnessColors.success` (Verde)
- Error: `WellnessColors.error` (Vermelho)
- Gradiente: `WellnessColors.purpleGradient`

### **Espaçamentos:**
- Padding lateral padrão: `20px`
- Gap entre seções: `16px` a `24px`
- Border radius: `16px` a `32px`

### **Tipografia:**
- Títulos: `20-22px`, `FontWeight.bold`
- Subtítulos: `14-16px`, `FontWeight.w600`
- Corpo: `12-13px`, `FontWeight.normal`

---

## 🔧 **Animações e Interações**

### **Animações:**
1. **Fade In:** `_fadeAnimation` (600ms, `Curves.easeOut`)
2. **Progress:** `_progressController` (1500ms)
3. **Insight Text:** `_insightController` (500ms)
4. **AnimatedSwitcher:** 300ms para widgets dinâmicos
5. **Timer Pulse:** Indicador com repeat infinito

### **Haptic Feedback:**
- `HapticFeedback.lightImpact()` em todos os taps
- `HapticFeedback.selectionClick()` em seleções de data

### **Sound Effects:**
- `soundService.playMoodSelect()` ao selecionar humor

---

## 📊 **Providers e Estado**

### **Principais Providers:**
- `settingsProvider` - Configurações do usuário
- `navigationProvider` - Navegação entre tabs
- `timerProvider` - Estado do timer/pomodoro
- `habitRepositoryProvider` - Hábitos
- `taskRepositoryProvider` - Tarefas
- `moodRecordRepositoryProvider` - Registros de humor
- `feedProvider` - Posts da comunidade
- `enabledHomeWidgetsProvider` - Widgets habilitados

### **Estado Local:**
- `_selectedMonth` - Mês selecionado
- `_selectedDate` - Data selecionada
- `_habitsTasksTabIndex` - Tab ativa (0=Hábitos, 1=Tarefas)
- `_isCalendarExpanded` - Calendário mensal expandido
- `_currentInsight` - Frase de inspiração atual
- `_showCompletedHabits` / `_showCompletedTasks` - Filtros

---

## 🎯 **Navegação**

### **Destinos Principais:**
- Profile Screen (avatar)
- HabitsCalendarScreen (botão calendário)
- TasksScreen (card tarefas)
- NotesScreen (card notas/ideias)
- LibraryScreen (card biblioteca)
- CommunityScreen (seção comunidade)
- NewsScreen (botão "Ver mais" notícias)
- Timer Tab (cards timer/pomodoro)

### **Modal Bottom Sheets:**
- `AddMoodRecordForm` (registrar humor)
- `SmartAddSheet` (adicionar item inteligente)

---

## 📝 **Notas Técnicas**

### **Performance:**
- Uso de `FutureBuilder` para dados assíncronos
- Lazy loading de imagens de notícias
- Animações otimizadas com `TickerProviderStateMixin`
- Cache de boxes Hive

### **Inicialização:**
- `_initHabitRepo()` / `_initTaskRepo()` no `initState`
- Timers para auto-slide e rotação de insights
- Showcase/Tutorial integrado

### **Cleanup:**
- Dispose de todos os controllers
- Cancelamento de timers
- Unregister de showcase

---

## 🚀 **Total: 16 Componentes/Seções**

Scroll vertical completo com física `BouncingScrollPhysics()` para feedback tátil.
