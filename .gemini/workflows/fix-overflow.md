---
description: Guia para identificar e corrigir problemas de overflow em Flutter
---

# 🔧 Guia de Correção de Overflow - Odyssey

## Diagnóstico Rápido

### 1. Identificar o tipo de overflow
```
RenderFlex overflowed by X pixels on the right → Row sem Expanded/Flexible
RenderFlex overflowed by X pixels on the bottom → Column sem SingleChildScrollView
```

### 2. Comandos úteis
```bash
# Verificar erros de análise
flutter analyze

# Modo debug com layout overflow visível (linha amarela/preta)
flutter run --debug
```

## Correções por Padrão

### Padrão 1: Row com texto que pode estourar
**Problema:**
```dart
Row(
  children: [
    Icon(Icons.person),
    Text("Nome muito longo que pode estourar a tela"),
    Icon(Icons.arrow_forward),
  ],
)
```

**Solução:**
```dart
Row(
  children: [
    const Icon(Icons.person),
    Expanded(
      child: Text(
        "Nome muito longo que pode estourar a tela",
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    const Icon(Icons.arrow_forward),
  ],
)
```

### Padrão 2: Texto sem limite de linhas
**Problema:**
```dart
Text(record.label)
```

**Solução:**
```dart
Text(
  record.label,
  overflow: TextOverflow.ellipsis,
  maxLines: 1,
)
```

### Padrão 3: Coluna sem scroll em tela cheia
**Problema:**
```dart
Column(
  children: [
    // muitos widgets
  ],
)
```

**Solução:**
```dart
SingleChildScrollView(
  physics: const BouncingScrollPhysics(),
  child: Column(
    children: [
      // muitos widgets
    ],
  ),
)
```

### Padrão 4: Tags/chips lado a lado
**Problema:**
```dart
Row(
  children: tags.map((t) => Chip(label: Text(t))).toList(),
)
```

**Solução:**
```dart
Wrap(
  spacing: 8.0,
  runSpacing: 4.0,
  children: tags.map((t) => Chip(label: Text(t))).toList(),
)
```

### Padrão 5: Texto grande em espaço fixo
**Problema:**
```dart
SizedBox(
  width: 200,
  child: Text("Texto que pode não caber"),
)
```

**Solução:**
```dart
SizedBox(
  width: 200,
  child: FittedBox(
    fit: BoxFit.scaleDown,
    child: Text("Texto que pode não caber"),
  ),
)
```

## Checklist de Revisão

- [ ] Todos os `Text` em `Row` têm `Expanded` ou `Flexible`
- [ ] Textos longos têm `overflow: TextOverflow.ellipsis` e `maxLines`
- [ ] Telas com muito conteúdo usam `SingleChildScrollView` ou `CustomScrollView`
- [ ] Tags/chips usam `Wrap` em vez de `Row`
- [ ] Títulos em cards têm `maxLines: 2` com `ellipsis`

## Exemplos do Projeto Odyssey

### ✅ Bom (insight_card.dart)
```dart
Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        insight.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      // ...
    ],
  ),
),
```

### ✅ Bom (post_card.dart)
```dart
Flexible(
  child: Text(
    widget.post.userName,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: colors.onSurface,
    ),
    overflow: TextOverflow.ellipsis,
  ),
),
```

### ✅ Bom (book_card_list.dart)
```dart
Text(
  book.title,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w600,
  ),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
),
```

## Widgets Reutilizáveis

Considere criar widgets auxiliares para casos comuns:

```dart
/// Texto com ellipsis padrão
class SafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  
  const SafeText(this.text, {this.style, this.maxLines = 1, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
```

---
**Última atualização:** 2025-12-22
