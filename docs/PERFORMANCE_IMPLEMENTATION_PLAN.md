# 🚀 Plano de Otimização de Performance - Odyssey

## Visão Geral

Este plano detalha a estratégia para melhorar significativamente a performance do app Odyssey **sem remover nenhuma feature**. O foco é refatoração, otimização e boas práticas de Flutter/Riverpod.

### Problemas Identificados
1. **`home_screen.dart`** com 8.764 linhas (God File)
2. **19 Timer.periodic** espalhados causando rebuilds constantes
3. **Providers sem `select()`** causando rebuilds desnecessários
4. **Animações sem isolamento** com RepaintBoundary

### Impacto Esperado
- **+50% de fluidez** na navegação
- **-40% de uso de memória**
- **60 FPS consistentes**

---

## Fase 1: Quick Wins ⚡
**Tempo estimado:** 1-2 dias  
**Impacto:** Alto (resultados imediatos)

---

### 📋 Task 1.1: Granularizar Watches de Providers

> **Prompt para execução:**
> ```
> Refatore os ref.watch() no arquivo odyssey_home.dart para usar select().
> 
> Substitua padrões como:
> final settings = ref.watch(settingsProvider);
> 
> Por padrões granulares como:
> final userName = ref.watch(settingsProvider.select((s) => s.userName));
> final avatarPath = ref.watch(settingsProvider.select((s) => s.avatarPath));
> 
> Faça o mesmo para timerProvider, navigationProvider e qualquer outro provider
> que seja watchado de forma completa. O objetivo é que cada widget só faça 
> rebuild quando a propriedade específica que ele usa mudar.
> ```

**Arquivos alvo:**
- `lib/src/features/home/presentation/odyssey_home.dart`
- `lib/src/features/home/presentation/home_screen.dart`
- `lib/src/features/settings/presentation/settings_screen.dart`

**Checklist:**
- [ ] `odyssey_home.dart` - settingsProvider com select
- [ ] `odyssey_home.dart` - timerProvider com select
- [ ] `home_screen.dart` - todos os providers granularizados
- [ ] `settings_screen.dart` - providers granularizados

---

### 📋 Task 1.2: Adicionar RepaintBoundary em Animações Pesadas

> **Prompt para execução:**
> ```
> Adicione RepaintBoundary nos seguintes widgets do odyssey_home.dart:
> 
> 1. O menu lateral (_buildSideMenu) - já tem parcialmente, verificar
> 2. O AnimatedBuilder do main content (linha ~693)
> 3. O menu button flutuante (linha ~804)
> 4. O FloatingTimerWidget
> 5. O RiveBottomBar
> 
> Padrão para aplicar:
> RepaintBoundary(
>   child: <widget_animado>,
> )
> 
> Isso isola a área de repaint, evitando que a animação cause repaint 
> de toda a árvore de widgets.
> ```

**Arquivos alvo:**
- `lib/src/features/home/presentation/odyssey_home.dart`
- `lib/src/features/time_tracker/widgets/floating_timer_widget.dart`

**Checklist:**
- [ ] Menu lateral isolado
- [ ] Main content animado isolado
- [ ] Menu button isolado
- [ ] FloatingTimerWidget isolado
- [ ] RiveBottomBar isolado

---

### 📋 Task 1.3: Conversão para `const` Agressiva

> **Prompt para execução:**
> ```
> Analise os seguintes arquivos e adicione const em todos os widgets 
> e parâmetros que podem ser const:
> 
> Targets prioritários:
> - SizedBox(height: X) → const SizedBox(height: X)
> - EdgeInsets.all(X) → const EdgeInsets.all(X)
> - BorderRadius.circular(X) → const BorderRadius.circular(X)
> - Divider() → const Divider()
> - Icon(Icons.X) → const Icon(Icons.X) (quando cor é fixa)
> - Text('literal') → const Text('literal') (quando não usa context)
> 
> Foque em:
> 1. odyssey_home.dart
> 2. home_screen.dart
> 3. settings_screen.dart
> 
> Use o linter para identificar onde const pode ser aplicado.
> Rode: flutter analyze
> ```

**Checklist:**
- [ ] SizedBox convertidos para const
- [ ] EdgeInsets convertidos para const
- [ ] Dividers convertidos para const
- [ ] Icons estáticos convertidos para const

---

## Fase 2: Refatoração Estrutural 🏗️
**Tempo estimado:** 3-5 dias  
**Impacto:** Muito Alto (resolve problema raiz)

---

### 📋 Task 2.1: Fragmentar home_screen.dart

> **Prompt para execução:**
> ```
> O arquivo home_screen.dart tem 8.764 linhas e precisa ser fragmentado.
> 
> Crie a seguinte estrutura de arquivos:
> 
> lib/src/features/home/presentation/
> ├── home_screen.dart (MANTER - mas reduzir para ~300 linhas)
> ├── sections/
> │   ├── home_header_section.dart (saudação, busca, notificações)
> │   ├── home_insights_section.dart (cards de insights/filosofia)
> │   ├── home_widgets_grid.dart (grid de widgets configuráveis)
> │   ├── home_calendar_section.dart (calendário de humor)
> │   ├── home_community_section.dart (feed da comunidade)
> │   ├── home_analytics_section.dart (gráficos e estatísticas)
> │   └── home_quick_actions_section.dart (ações rápidas)
> └── controllers/
>     └── home_screen_controller.dart (lógica de estado)
> 
> Para cada seção:
> 1. Extraia o método _build correspondente
> 2. Crie um widget StatelessWidget ou ConsumerWidget separado
> 3. Passe apenas os parâmetros necessários
> 4. Importe de volta no home_screen.dart
> 
> O home_screen.dart final deve apenas:
> - Compor as seções
> - Gerenciar o ScrollController
> - Orquestrar o layout geral
> ```

**Nova estrutura de arquivos:**
```
lib/src/features/home/presentation/sections/
├── home_header_section.dart
├── home_insights_section.dart
├── home_widgets_grid.dart
├── home_calendar_section.dart
├── home_community_section.dart
├── home_analytics_section.dart
└── home_quick_actions_section.dart
```

**Checklist:**
- [ ] Criar diretório `sections/`
- [ ] Extrair HomeHeaderSection
- [ ] Extrair HomeInsightsSection
- [ ] Extrair HomeWidgetsGrid
- [ ] Extrair HomeCalendarSection
- [ ] Extrair HomeCommunitySection
- [ ] Extrair HomeAnalyticsSection
- [ ] Extrair HomeQuickActionsSection
- [ ] Refatorar home_screen.dart para usar os novos componentes
- [ ] Verificar que compila sem erros
- [ ] Testar no device

---

### 📋 Task 2.2: Criar Provider de Dashboard Agregado

> **Prompt para execução:**
> ```
> Crie um provider agregado para os dados da home screen que faz cache 
> de 5 minutos. Isso evita múltiplas queries a cada rebuild.
> 
> Criar arquivo: lib/src/features/home/presentation/providers/home_dashboard_provider.dart
> 
> Conteúdo:
> 
> import 'dart:async';
> import 'package:flutter_riverpod/flutter_riverpod.dart';
> 
> class HomeDashboardData {
>   final int todayMoodCount;
>   final int completedHabitsToday;
>   final int completedTasksToday;
>   final int currentStreak;
>   final int totalXP;
>   final String? currentInsight;
>   
>   const HomeDashboardData({
>     required this.todayMoodCount,
>     required this.completedHabitsToday,
>     required this.completedTasksToday,
>     required this.currentStreak,
>     required this.totalXP,
>     this.currentInsight,
>   });
> }
> 
> final homeDashboardProvider = FutureProvider.autoDispose<HomeDashboardData>((ref) async {
>   // Keep alive for 5 minutes
>   final link = ref.keepAlive();
>   final timer = Timer(const Duration(minutes: 5), link.close);
>   ref.onDispose(() => timer.cancel());
>   
>   // Buscar dados de múltiplos repositórios
>   final moodRepo = ref.watch(moodRepositoryProvider);
>   final habitRepo = ref.watch(habitRepositoryProvider);
>   final taskRepo = ref.watch(taskRepositoryProvider);
>   final gamificationRepo = ref.watch(gamificationRepositoryProvider);
>   
>   // Agregar dados
>   return HomeDashboardData(
>     todayMoodCount: await moodRepo.getTodayCount(),
>     completedHabitsToday: await habitRepo.getCompletedTodayCount(),
>     completedTasksToday: await taskRepo.getCompletedTodayCount(),
>     currentStreak: await gamificationRepo.getCurrentStreak(),
>     totalXP: await gamificationRepo.getTotalXP(),
>   );
> });
> 
> Depois, use este provider no home_screen.dart em vez de fazer 
> múltiplas queries separadas.
> ```

**Checklist:**
- [ ] Criar `home_dashboard_provider.dart`
- [ ] Implementar HomeDashboardData
- [ ] Implementar homeDashboardProvider com cache
- [ ] Refatorar home_screen para usar o novo provider
- [ ] Testar que dados carregam corretamente

---

### 📋 Task 2.3: Mover Lógica de Insights para Provider

> **Prompt para execução:**
> ```
> O Timer.periodic que atualiza insights a cada 30s está no home_screen.dart.
> Mova essa lógica para um provider dedicado.
> 
> Criar: lib/src/features/home/presentation/providers/home_insight_provider.dart
> 
> class HomeInsightNotifier extends StateNotifier<String> {
>   Timer? _timer;
>   final Random _random = Random();
>   
>   static const List<String> _insights = [
>     // Copiar lista de insights do home_screen.dart
>   ];
>   
>   HomeInsightNotifier() : super(_insights[Random().nextInt(_insights.length)]) {
>     _startTimer();
>   }
>   
>   void _startTimer() {
>     _timer = Timer.periodic(const Duration(seconds: 30), (_) {
>       _randomize();
>     });
>   }
>   
>   void _randomize() {
>     state = _insights[_random.nextInt(_insights.length)];
>   }
>   
>   void nextInsight() => _randomize();
>   
>   @override
>   void dispose() {
>     _timer?.cancel();
>     super.dispose();
>   }
> }
> 
> final homeInsightProvider = StateNotifierProvider.autoDispose<HomeInsightNotifier, String>((ref) {
>   return HomeInsightNotifier();
> });
> 
> Remova o Timer e a lógica de insights do _HomeScreenState e use o provider.
> ```

**Checklist:**
- [ ] Criar `home_insight_provider.dart`
- [ ] Mover lista de insights para o provider
- [ ] Remover Timer do _HomeScreenState
- [ ] Usar homeInsightProvider no widget de insights
- [ ] Testar rotação de insights

---

## Fase 3: Otimizações Avançadas 🔧
**Tempo estimado:** 1-2 semanas  
**Impacto:** Médio-Alto (polish final)

---

### 📋 Task 3.1: Criar TimerHub Centralizado

> **Prompt para execução:**
> ```
> Existem 19 Timer.periodic espalhados pelo código. Centralize em um hub.
> 
> Criar: lib/src/utils/services/timer_hub.dart
> 
> class TimerHub {
>   static final TimerHub _instance = TimerHub._();
>   static TimerHub get instance => _instance;
>   TimerHub._();
>   
>   Timer? _masterTimer;
>   final Map<String, VoidCallback> _secondListeners = {};
>   final Map<String, VoidCallback> _minuteListeners = {};
>   int _secondCount = 0;
>   
>   void addSecondListener(String key, VoidCallback callback) {
>     _secondListeners[key] = callback;
>     _ensureTimerRunning();
>   }
>   
>   void addMinuteListener(String key, VoidCallback callback) {
>     _minuteListeners[key] = callback;
>     _ensureTimerRunning();
>   }
>   
>   void removeListener(String key) {
>     _secondListeners.remove(key);
>     _minuteListeners.remove(key);
>     if (_secondListeners.isEmpty && _minuteListeners.isEmpty) {
>       _masterTimer?.cancel();
>       _masterTimer = null;
>     }
>   }
>   
>   void _ensureTimerRunning() {
>     _masterTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
>       _secondCount++;
>       
>       // Second listeners
>       for (final callback in _secondListeners.values) {
>         callback();
>       }
>       
>       // Minute listeners (a cada 60 segundos)
>       if (_secondCount % 60 == 0) {
>         for (final callback in _minuteListeners.values) {
>           callback();
>         }
>       }
>     });
>   }
> }
> 
> Migre os timers do timer_provider.dart e outros arquivos para usar o TimerHub.
> ```

**Checklist:**
- [ ] Criar `timer_hub.dart`
- [ ] Implementar listeners de segundo e minuto
- [ ] Migrar timer_provider.dart
- [ ] Migrar stopwatch_widget.dart
- [ ] Migrar notification_scheduler.dart
- [ ] Testar todos os timers funcionando

---

### 📋 Task 3.2: Converter Todos os Providers para AutoDispose

> **Prompt para execução:**
> ```
> Audite todos os providers do projeto e converta para autoDispose 
> os que não precisam de estado persistente.
> 
> Comando para encontrar providers sem autoDispose:
> grep -r "StateNotifierProvider<" lib/ --include="*.dart" | grep -v "autoDispose"
> grep -r "FutureProvider<" lib/ --include="*.dart" | grep -v "autoDispose"
> 
> Para cada provider encontrado:
> 1. Verifique se PRECISA de estado persistente
> 2. Se NÃO precisa, converta para autoDispose
> 3. Se PRECISA (ex: timerProvider), mantenha como está
> 
> Exemplo de conversão:
> ANTES:
> final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) => ...);
> 
> DEPOIS:
> final myProvider = StateNotifierProvider.autoDispose<MyNotifier, MyState>((ref) => ...);
> ```

**Checklist:**
- [ ] Listar todos os providers sem autoDispose
- [ ] Classificar: precisa persistir vs pode autoDispose
- [ ] Converter os que podem ser autoDispose
- [ ] Testar navegação (não deve perder estado indevidamente)

---

### 📋 Task 3.3: Implementar Lazy Loading em Listas Longas

> **Prompt para execução:**
> ```
> Identifique listas que podem ter muitos itens e garanta que usam 
> ListView.builder ou GridView.builder com RepaintBoundary.
> 
> Arquivos para verificar:
> - lib/src/features/mood_records/presentation/history_screen.dart
> - lib/src/features/tasks/presentation/tasks_screen.dart
> - lib/src/features/habits/presentation/habits_screen.dart
> - lib/src/features/library/presentation/library_screen.dart
> - lib/src/features/notes/presentation/notes_screen.dart
> - lib/src/features/community/presentation/screens/community_screen.dart
> 
> Padrão ideal:
> ListView.builder(
>   itemCount: items.length,
>   itemBuilder: (context, index) => RepaintBoundary(
>     child: _buildItem(items[index]),
>   ),
> )
> 
> Também considere adicionar:
> - cacheExtent: 100.0, // Pré-carrega 100 pixels extras
> - addRepaintBoundaries: true, // Default mas bom explicitar
> ```

**Checklist:**
- [ ] history_screen.dart usa ListView.builder
- [ ] tasks_screen.dart usa ListView.builder
- [ ] habits_screen.dart usa ListView.builder
- [ ] library_screen.dart usa ListView.builder
- [ ] notes_screen.dart usa ListView.builder
- [ ] community_screen.dart usa ListView.builder
- [ ] Cada item tem RepaintBoundary

---

### 📋 Task 3.4: Cache de Imagens da Comunidade

> **Prompt para execução:**
> ```
> Adicione cache de imagens para posts da comunidade.
> 
> Instalar pacote (se não instalado):
> flutter pub add cached_network_image
> 
> Substituir Image.network por CachedNetworkImage:
> 
> ANTES:
> Image.network(
>   post.userPhotoUrl,
>   fit: BoxFit.cover,
> )
> 
> DEPOIS:
> CachedNetworkImage(
>   imageUrl: post.userPhotoUrl,
>   fit: BoxFit.cover,
>   memCacheWidth: 100, // Limita tamanho em memória
>   placeholder: (context, url) => const CircularProgressIndicator(),
>   errorWidget: (context, url, error) => const Icon(Icons.person),
> )
> 
> Arquivos para modificar:
> - lib/src/features/community/presentation/widgets/post_card.dart
> - lib/src/features/community/presentation/widgets/user_avatar.dart
> ```

**Checklist:**
- [ ] cached_network_image instalado
- [ ] post_card.dart usando cache
- [ ] user_avatar.dart usando cache
- [ ] Testar carregamento de imagens

---

## Fase 4: Validação e Testes 🧪
**Tempo estimado:** 1 dia  
**Impacto:** Garantia de qualidade

---

### 📋 Task 4.1: Rodar Flutter Analyze

> **Prompt para execução:**
> ```
> Execute análise completa do código:
> 
> flutter analyze
> 
> Corrija todos os warnings e erros encontrados.
> Priorize:
> 1. Unused imports
> 2. Missing const
> 3. Deprecated APIs
> 4. Type inference issues
> ```

**Checklist:**
- [ ] flutter analyze sem erros
- [ ] flutter analyze sem warnings críticos
- [ ] Imports não utilizados removidos

---

### 📋 Task 4.2: Profile com DevTools

> **Prompt para execução:**
> ```
> Execute o app em modo profile e analise performance:
> 
> flutter run --profile
> 
> Abra DevTools:
> flutter pub global activate devtools
> flutter pub global run devtools
> 
> Na aba Performance:
> 1. Grave 10 segundos de uso normal
> 2. Identifique frames que passam de 16ms
> 3. Identifique rebuilds excessivos
> 4. Verifique uso de memória
> 
> Na aba Flutter Inspector:
> 1. Ative "Track widget rebuilds"
> 2. Navegue pelo app
> 3. Identifique widgets que rebuildam demais
> ```

**Checklist:**
- [ ] App roda em profile mode
- [ ] DevTools conectado
- [ ] Gravação de performance realizada
- [ ] Rebuilds excessivos identificados e corrigidos
- [ ] Frames abaixo de 16ms

---

### 📋 Task 4.3: Teste em Device Real

> **Prompt para execução:**
> ```
> Teste o app em um dispositivo Android real (não emulador):
> 
> ./run-android.sh
> 
> Testar cenários:
> 1. Abrir app frio (primeira vez)
> 2. Navegar entre todas as tabs
> 3. Abrir menu lateral várias vezes
> 4. Scroll rápido em listas longas
> 5. Usar timer/pomodoro
> 6. Registrar humor
> 7. Navegar pela comunidade
> 
> Para cada cenário, avaliar:
> - Fluidez (60fps?)
> - Responsividade ao toque
> - Ausência de jank/travamentos
> ```

**Checklist:**
- [ ] Abertura do app suave
- [ ] Navegação entre tabs fluida
- [ ] Menu lateral abre sem lag
- [ ] Scroll em listas fluido
- [ ] Timer funciona sem problemas
- [ ] Registro de humor responsivo
- [ ] Comunidade carrega bem

---

## 📊 Métricas de Sucesso

| Métrica | Antes | Meta | Como Medir |
|---------|-------|------|------------|
| home_screen.dart linhas | 8.764 | < 500 | `wc -l` |
| Timer.periodic | 19 | < 5 | `grep -r` |
| Frames/segundo | ~40 | 60 | DevTools |
| First Paint | ~2s | < 1s | DevTools |
| Memória | ~200MB | < 150MB | DevTools |

---

## 🗓️ Cronograma Sugerido

| Dia | Fase | Tasks |
|-----|------|-------|
| 1 | Fase 1 | 1.1, 1.2 |
| 2 | Fase 1 | 1.3, iniciar 2.1 |
| 3-4 | Fase 2 | 2.1 (fragmentação) |
| 5 | Fase 2 | 2.2, 2.3 |
| 6-7 | Fase 3 | 3.1, 3.2 |
| 8-9 | Fase 3 | 3.3, 3.4 |
| 10 | Fase 4 | Validação completa |

---

## ⚠️ Avisos Importantes

1. **Sempre compile após cada mudança** - `flutter analyze`
2. **Faça commits frequentes** - um por task completada
3. **Teste no device real** - emulador pode mascarar problemas
4. **Não remova features** - apenas refatore e otimize
5. **Documente decisões** - para futuras manutenções

---

**Última atualização:** 2025-12-22  
**Responsável:** Genta & Team
