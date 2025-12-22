# 🚀 Odyssey - Estratégia de Otimização de Performance

**Data:** 2025-12-22  
**Status:** EM ANÁLISE  
**Impacto Esperado:** Melhoria de 40-60% na fluidez

---

## 📊 Diagnóstico Atual

### 🔴 Problemas Críticos Identificados

#### 1. **God File: `home_screen.dart` (8.764 linhas!)**
- **Impacto:** CRÍTICO
- **Causa:** Arquivo monolítico impossível de otimizar
- **Sintomas:** 
  - Builds pesados em qualquer mudança de estado
  - Memória excessiva
  - Dificuldade de manutenção

#### 2. **Timer.periodic em Múltiplos Lugares**
```
Encontrados 19 Timer.periodic espalhados:
- home_screen.dart: 2 timers (insight + auto-slide)
- timer_provider.dart: 3 timers
- notification_scheduler.dart: 3 timers
- stopwatch_widget.dart: 2 timers
- Outros: 9 timers
```
- **Impacto:** ALTO
- **Causa:** Timers rodando continuamente causam rebuilds frequentes

#### 3. **Animações sem RepaintBoundary Adequado**
- Apesar de existir `optimized_animations.dart`, muitos widgets ainda não usam
- Animações do menu lateral e bottom bar rebuildam toda a árvore

#### 4. **Providers com Rebuilds Excessivos**
- `settingsProvider` watchado em múltiplos lugares
- `timerProvider` causando cascata de rebuilds
- Falta de `select()` para watches granulares

---

## 🎯 Estratégia de Otimização (Sem Remover Features)

### Fase 1: Quick Wins (1-2 dias) ⚡

#### 1.1 Granularizar Watches de Providers
**Antes:**
```dart
final settings = ref.watch(settingsProvider); // Rebuild em QUALQUER mudança
```

**Depois:**
```dart
final userName = ref.watch(settingsProvider.select((s) => s.userName));
final theme = ref.watch(settingsProvider.select((s) => s.themeMode));
```

**Arquivos Prioritários:**
- `odyssey_home.dart`
- `home_screen.dart`
- `settings_screen.dart`

#### 1.2 Adicionar `const` Agressivamente
```dart
// Buscar e converter para const:
- Containers decorativos
- Text widgets estáticos
- Icon widgets
- Dividers
- SizedBox
```

#### 1.3 Isolar Animações Pesadas com RepaintBoundary
**Prioritários:**
- Menu lateral do `odyssey_home.dart`
- Bottom bar animada
- Floating timer widget
- Widgets do home com animações

---

### Fase 2: Refatoração Estrutural (3-5 dias)

#### 2.1 Fragmentar `home_screen.dart`
**Estratégia:** Dividir em múltiplos arquivos menores

```
lib/src/features/home/presentation/
├── home_screen.dart (< 500 linhas - apenas scaffold)
├── sections/
│   ├── home_header_section.dart
│   ├── home_insights_section.dart
│   ├── home_widgets_grid.dart
│   ├── home_calendar_section.dart
│   ├── home_community_section.dart
│   ├── home_analytics_section.dart
│   └── home_quick_actions.dart
├── widgets/
│   ├── (widgets existentes)
│   └── insight_card.dart
└── controllers/
    ├── home_insights_controller.dart
    └── home_auto_slide_controller.dart
```

#### 2.2 Mover Lógica de Estado para Providers Dedicados
**Criar novos providers:**
```dart
// lib/src/features/home/presentation/providers/

// Provider para insights da home
final homeInsightProvider = StateNotifierProvider.autoDispose<HomeInsightNotifier, String>(...);

// Provider para controle do auto-slide
final homeAutoSlideProvider = StateNotifierProvider.autoDispose<...>(...);

// Provider para dados agregados da home (com cache)
final homeDashboardProvider = FutureProvider.autoDispose<HomeDashboardData>((ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(() => timer.cancel());
  
  // Agregar dados de múltiplas fontes
  return HomeDashboardData(...);
});
```

#### 2.3 Converter Widgets Pesados para Lazy Loading
```dart
// Para listas longas
ListView.builder(
  itemBuilder: (context, index) => RepaintBoundary(
    child: _buildItem(index),
  ),
)

// Para grids
GridView.builder(
  addRepaintBoundaries: true, // Já é default
  ...
)
```

---

### Fase 3: Otimizações Avançadas (1-2 semanas)

#### 3.1 Timer Centralizado
**Criar um TimerHub para evitar múltiplos timers:**
```dart
// lib/src/utils/services/timer_hub.dart
class TimerHub {
  static final TimerHub _instance = TimerHub._();
  static TimerHub get instance => _instance;
  TimerHub._();
  
  Timer? _masterTimer;
  final Map<String, VoidCallback> _listeners = {};
  
  void addListener(String key, VoidCallback callback) {
    _listeners[key] = callback;
    _ensureTimerRunning();
  }
  
  void removeListener(String key) {
    _listeners.remove(key);
    if (_listeners.isEmpty) _masterTimer?.cancel();
  }
  
  void _ensureTimerRunning() {
    _masterTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      for (final callback in _listeners.values) {
        callback();
      }
    });
  }
}
```

#### 3.2 Implementar `AutoDispose` Global
**Garantir que todos os providers usem autoDispose:**
```dart
// Bom ✅
final myProvider = StateNotifierProvider.autoDispose<...>(...);

// Ruim ❌
final myProvider = StateNotifierProvider<...>(...);
```

#### 3.3 Lazy Initialization de Features
```dart
// Carregar features apenas quando necessário
final notesFeatureProvider = FutureProvider.autoDispose((ref) async {
  // Só carrega quando a tela de notas é acessada
  return await NotesRepository.instance.init();
});
```

#### 3.4 Cache de Imagens e Assets
```dart
// Usar CachedNetworkImage para imagens da comunidade
CachedNetworkImage(
  imageUrl: url,
  memCacheWidth: 200, // Limitar tamanho em memória
  placeholder: (_, __) => shimmer,
  errorWidget: (_, __, ___) => fallback,
)
```

---

## 📋 Checklist de Implementação

### Prioridade 1 (Crítico)
- [ ] Fragmentar `home_screen.dart` em seções menores
- [ ] Adicionar `select()` em todos os watches de providers críticos
- [ ] Envolver animações pesadas com `RepaintBoundary`

### Prioridade 2 (Alto)
- [ ] Centralizar Timers em um TimerHub
- [ ] Converter providers para `autoDispose`
- [ ] Implementar cache de dados da home (5 minutos)

### Prioridade 3 (Médio)
- [ ] Adicionar `const` em widgets estáticos
- [ ] Implementar lazy loading para listas longas
- [ ] Otimizar imagens com cache

### Prioridade 4 (Melhoria Contínua)
- [ ] Perfil com Flutter DevTools
- [ ] Remover `debugPrint` excessivos
- [ ] Otimizar queries do Hive/Isar

---

## 📈 Métricas de Sucesso

| Métrica | Atual (estimado) | Meta |
|---------|------------------|------|
| First Meaningful Paint | ~2-3s | < 1s |
| Frames por segundo | ~30-40 fps | 60 fps |
| Memory usage | ~200MB+ | < 150MB |
| Build time de widgets | ~16ms+ | < 8ms |
| home_screen.dart linhas | 8.764 | < 500 |

---

## 🛠️ Ferramentas para Monitorar

```bash
# Ativar modo performance
flutter run --profile

# Overlay de performance
flutter run --profile --trace-skia

# DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Widgets para Debug
```dart
// Temporariamente para identificar rebuilds
Widget build(BuildContext context) {
  debugPrint('🔄 Rebuilding: ${runtimeType}');
  return ...
}
```

---

## ⚠️ O Que NÃO Fazer

1. ❌ Remover features para "otimizar"
2. ❌ Desabilitar animações completamente
3. ❌ Fazer cache agressivo demais (dados desatualizados)
4. ❌ Usar `setState` em vez de Riverpod
5. ❌ Ignorar warnings do Flutter analyze

---

## 🎯 Próximos Passos Imediatos

1. **HOJE:** Começar fragmentação do `home_screen.dart`
2. **AMANHÃ:** Implementar `select()` em providers críticos
3. **ESTA SEMANA:** Finalizar Fase 1 (Quick Wins)

---

**Responsável:** Genta & Team  
**Última atualização:** 2025-12-22
