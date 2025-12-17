# 🎯 Guia de Boas Práticas - Performance e Tematização

## 📋 Checklist para Novos Componentes

### 1. Cores e Tema ✅

#### ✅ SEMPRE FAÇA
```dart
// Carregar cores do tema uma vez
Widget build(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  
  return Container(
    color: colors.surface,
    child: Text(
      'Hello',
      style: TextStyle(color: colors.onSurface),
    ),
  );
}
```

#### ❌ NUNCA FAÇA
```dart
// Cores hardcoded
Container(
  color: Colors.white, // ❌ Não respeita dark mode
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black), // ❌
  ),
)

// Múltiplas chamadas Theme.of
Container(
  color: Theme.of(context).colorScheme.surface, // Carrega uma vez
  child: Text(
    'Hello',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface, // ❌ Desnecessário
    ),
  ),
)
```

### 2. Performance com `const` 🚀

#### ✅ Use `const` quando possível
```dart
// Widget totalmente estático
const Padding(
  padding: EdgeInsets.all(16), // const
  child: const Icon(Icons.star), // const
)

// Texto estático
const Text(
  'Label fixo',
  style: const TextStyle(fontSize: 14), // const se valores fixos
)
```

#### 🤔 Quando NÃO usar `const`
```dart
// Valores dinâmicos
Padding(
  padding: EdgeInsets.all(dynamicValue), // ❌ Não pode ser const
  child: Text(userName), // ❌ userName muda
)

// Usa Theme ou MediaQuery
Container(
  color: colors.surface, // ❌ colors vem do contexto
)
```

### 3. Listas e Performance 📜

#### ✅ ListView.builder para listas longas
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return const ItemWidget(item); // const se possível
  },
)
```

#### ❌ Evite construir tudo de uma vez
```dart
// Se items.length > 20, preferir builder
Column(
  children: items.map((item) => ItemWidget(item)).toList(), // ❌
)
```

### 4. Riverpod Selectors 🎯

#### ✅ Seletores específicos
```dart
// Rebuild apenas quando isActive muda
final isActive = ref.watch(
  timerProvider.select((state) => state.isActive)
);

// Para valores complexos
final userName = ref.watch(
  userProvider.select((user) => user.profile.name)
);
```

#### ❌ Watch completo desnecessário
```dart
// Rebuild em QUALQUER mudança de timerProvider
final timer = ref.watch(timerProvider); // ❌ se só usa isActive
if (timer.isActive) {
  // ...
}
```

### 5. Extração de Widgets 🧩

#### ✅ Extrair widgets complexos
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Header(), // Extraído
        _buildBody(), // Método privado se precisa de estado
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();
  
  @override
  Widget build(BuildContext context) {
    // 50+ linhas de header aqui
  }
}
```

### 6. Operações de Banco 💾

#### ✅ Operações em lote
```dart
// Adicionar múltiplos items
await box.addAll(items);
await box.putAll({'key1': item1, 'key2': item2});

// Atualizar em batch no Firestore
WriteBatch batch = firestore.batch();
for (var doc in docs) {
  batch.set(doc.ref, doc.data);
}
await batch.commit();
```

#### ❌ Loop com await
```dart
// Muito lento para N items
for (var item in items) {
  await box.add(item); // ❌ Uma operação de disco por vez
}
```

## 🎨 Paleta de Cores Recomendada

### Uso Comum
```dart
final colors = Theme.of(context).colorScheme;

// Backgrounds
colors.surface          // Cards, dialogs
colors.background       // Fundo da tela
colors.surfaceVariant   // Alternativo
colors.surfaceContainerHighest // Inactive states

// Textos
colors.onSurface        // Texto principal
colors.onSurfaceVariant // Texto secundário/hints
colors.onPrimary        // Texto sobre primária

// Status
colors.primary          // Ação principal, highlights
colors.secondary        // Ações secundárias
colors.tertiary         // Success, amber tones
colors.error            // Erros, destructive actions

// Bordas e sombras
colors.outline          // Bordas sutis
colors.shadow           // Sombras
```

### Opacidades Padrão
```dart
// Fundos sutis
colors.primary.withOpacity(0.1)   // Muito sutil
colors.primary.withOpacity(0.15)  // Fundo de chip/tag
colors.primary.withOpacity(0.2)   // Fundo de botão hover

// Textos
colors.onSurface.withOpacity(0.6) // Texto disabled
colors.onSurface.withOpacity(0.8) // Texto secondary

// Bordas
colors.outline.withOpacity(0.1)   // Borda muito sutil
colors.outline.withOpacity(0.3)   // Borda padrão
```

## 🔥 Anti-Patterns a Evitar

### 1. setState em loops
```dart
// ❌ Muito lento
for (var i = 0; i < 100; i++) {
  setState(() {
    items.add(i);
  });
}

// ✅ Correto
final newItems = List.generate(100, (i) => i);
setState(() {
  items.addAll(newItems);
});
```

### 2. Lógica no build()
```dart
// ❌ Cálculo pesado a cada rebuild
Widget build(BuildContext context) {
  final result = _expensiveCalculation(); // ❌
  return Text('$result');
}

// ✅ Calcular fora ou memorizar
late final result = _expensiveCalculation(); // No initState
```

### 3. Nested widgets demais
```dart
// ❌ Difícil de ler e manter
return Container(
  child: Padding(
    child: Column(
      children: [
        Container(
          child: Row(
            children: [
              // 5+ níveis de profundidade ❌
            ],
          ),
        ),
      ],
    ),
  ),
);

// ✅ Extrair em widgets
return Column(
  children: [
    const _Header(),
    _buildContent(),
  ],
);
```

## 🧪 Testes de Performance

### DevTools
```bash
# Rodar em modo profile
flutter run --profile

# Abrir DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Métricas a Monitorar
- **Frame Rate**: Deve estar consistentemente acima de 58 FPS
- **Build Time**: Cada widget < 16ms (60 FPS)
- **Memory**: Heap estável, sem memory leaks
- **Jank**: Frames > 16ms devem ser < 1%

### Timeline
1. Gravar interação no DevTools
2. Identificar frames lentos (vermelho)
3. Expandir para ver widgets caros
4. Otimizar ou adicionar RepaintBoundary

## 📚 Referências Rápidas

### Flutter Performance
- [Best Practices](https://docs.flutter.dev/perf/best-practices)
- [Rendering Performance](https://docs.flutter.dev/perf/rendering-performance)
- [DevTools](https://docs.flutter.dev/tools/devtools/performance)

### Material Design
- [Color System](https://m3.material.io/styles/color/system/overview)
- [Dark Theme](https://m3.material.io/styles/color/dark-theme/overview)

### Riverpod
- [Performance Tips](https://riverpod.dev/docs/concepts/performance)
- [Providers](https://riverpod.dev/docs/providers/provider)

---

**Mantenha este guia atualizado com novos padrões descobertos!**
