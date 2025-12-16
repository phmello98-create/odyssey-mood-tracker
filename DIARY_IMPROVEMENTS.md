# 📔 Melhorias do Diário - Inspirado no StoryPad

## 🎨 O que foi implementado

### 1. **Sistema de Preferências Visuais**
- Arquivo: `lib/src/features/diary/domain/entities/diary_preferences.dart`
- Permite personalizar:
  - Fonte (10 opções: Roboto, Montserrat, Playfair Display, etc.)
  - Tamanho do texto (12-24pt)
  - Espaçamento de linha (1.0-2.5x)
  - Cores de fundo e texto personalizadas
  - Gradientes para headers
  - Alinhamento de texto
  - 6 temas pré-definidos: Padrão, Noturno, Sereno, Romântico, Vintage, Moderno

### 2. **Feeling Picker com Emojis**
- Arquivo: `lib/src/features/diary/presentation/widgets/diary_feeling_picker.dart`
- 15 sentimentos disponíveis: 😄 Incrível, 😊 Feliz, 🙂 Bem, 😐 Ok, 😢 Triste, etc.
- Cada sentimento tem cor própria
- Versão completa e compacta (para toolbar)
- Componente `DiaryFeelingButton` para exibição nos cards

### 3. **Cards Modernos e Elegantes**
- Arquivo: `lib/src/features/diary/presentation/widgets/diary_entry_card.dart`
- **DiaryEntryCard**: Card completo com:
  - Header com gradiente (quando tema personalizado)
  - Display de sentimento com badge colorido
  - Preview do conteúdo com texto formatado
  - Footer com metadados (tempo de leitura, palavras, fotos)
  - Suporte a temas personalizados
  - Animação Hero para transições suaves
- **DiaryEntryCardCompact**: Versão compacta para grid view
  - Design otimizado para espaços pequenos
  - Mantém informações essenciais

### 4. **Editor Quill Integrado**
- Arquivo: `lib/src/features/diary/presentation/widgets/diary_quill_editor.dart`
- Formatação rica de texto:
  - Negrito, itálico, sublinhado, tachado
  - Listas (bullet, numeradas, checklist)
  - Citações e código inline
  - Cores de texto
  - Alinhamento de texto
  - Desfazer/refazer
- Toolbar personalizável com tema do app
- Estilos customizados para cada tipo de bloco
- Funções auxiliares para conversão de Delta para texto plano

### 5. **Headers com Gradiente**
- Arquivo: `lib/src/features/diary/presentation/widgets/diary_entry_header.dart`
- **DiaryEntryHeader**: Header completo com:
  - Gradiente baseado no sentimento ou tema personalizado
  - Data formatada em português
  - Badge do sentimento com blur shadow
  - Botões de ação (voltar, sentimento, favorito, mais)
  - Animação e sombras suaves
- **DiaryEntryCompactHeader**: Versão compacta para visualização

### 6. **Seletor de Temas**
- Arquivo: `lib/src/features/diary/presentation/widgets/diary_theme_selector.dart`
- Lista horizontal com preview dos temas
- Cada card mostra:
  - Header com gradiente
  - Preview da fonte e cores
  - Indicador de seleção
- **DiaryThemeCustomizer**: Editor completo de tema com:
  - Seletor de fonte com preview
  - Sliders para tamanho e espaçamento
  - Preview em tempo real
  - Bottom sheet modal responsivo

### 7. **Animações e Transições**
- Timeline view: Fade in + slide up escalonado
- Grid view: Scale in com easing back
- Cards: AnimatedScale no hover/seleção
- FAB: Hero animation com tag 'new_entry_fab'
- Transições suaves entre estados

### 8. **Modelo de Dados Atualizado**
- `diary_entry.dart` agora inclui:
  - `wordCount`: Contagem de palavras
  - `readingTimeMinutes`: Tempo de leitura estimado
  - `templateId`: ID do template usado
  - `location`: Local da escrita
  - `weather`: Clima do dia
  - `preferences`: Preferências visuais (DiaryPreferences)

## 🚀 Como usar

### Aplicar um tema pré-definido:
```dart
DiaryThemeSelector(
  currentPreferences: entry.preferences,
  onThemeSelected: (preferences) {
    // Salvar preferências
    controller.updateEntryPreferences(entryId, preferences);
  },
)
```

### Feeling Picker:
```dart
DiaryFeelingPicker(
  selectedFeeling: currentFeeling,
  onFeelingChanged: (feeling) {
    setState(() => currentFeeling = feeling);
  },
)
```

### Usar o Editor Quill:
```dart
DiaryQuillEditor(
  initialContent: entry.content,
  onContentChanged: (deltaJson) {
    // Salvar conteúdo
    controller.updateContent(deltaJson);
  },
)
```

### Exibir Cards:
```dart
// Timeline/Lista
DiaryEntryCard(
  entry: entry,
  onTap: () => openEntry(entry.id),
  onLongPress: () => showOptions(entry),
)

// Grid
DiaryEntryCardCompact(
  entry: entry,
  onTap: () => openEntry(entry.id),
)
```

## 🔧 Próximos passos (quando rodar build_runner)

1. Execute para gerar código Freezed e Hive:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

2. Registre o adapter do DiaryPreferences no Hive:
```dart
Hive.registerAdapter(DiaryPreferencesAdapter());
```

3. Importe os novos widgets nos arquivos do editor:
```dart
import '../widgets/diary_feeling_picker.dart';
import '../widgets/diary_entry_header.dart';
import '../widgets/diary_theme_selector.dart';
import '../widgets/diary_quill_editor.dart';
```

## 🎯 Melhorias de UX

- **Visual consistente**: Design inspirado no StoryPad com Material Design 3
- **Personalização**: 6 temas + personalização completa
- **Feedback visual**: Animações suaves e transições naturais
- **Acessibilidade**: Contraste adequado, tamanhos de fonte ajustáveis
- **Performance**: Hero animations, lazy loading nos cards
- **Responsivo**: Layouts adaptáveis para diferentes tamanhos de tela

## 📝 Estrutura dos arquivos criados/modificados

```
lib/src/features/diary/
├── domain/entities/
│   ├── diary_preferences.dart          ✨ NOVO
│   └── diary_entry_entity.dart         ✅ ATUALIZADO
├── data/models/
│   └── diary_entry.dart                ✅ ATUALIZADO
└── presentation/
    ├── pages/
    │   └── diary_home_page.dart        ✅ ATUALIZADO (animações)
    └── widgets/
        ├── diary_feeling_picker.dart   ✨ NOVO
        ├── diary_entry_card.dart       ✅ REDESENHADO
        ├── diary_quill_editor.dart     ✨ NOVO
        ├── diary_entry_header.dart     ✨ NOVO
        └── diary_theme_selector.dart   ✨ NOVO
```

## 🎨 Paleta de Cores dos Sentimentos

| Sentimento | Emoji | Cor |
|-----------|-------|-----|
| Incrível | 😄 | #FFD700 (Ouro) |
| Feliz | 😊 | #4CAF50 (Verde) |
| Bem | 🙂 | #8BC34A (Verde claro) |
| Ok | 😐 | #FFC107 (Âmbar) |
| Triste | 😢 | #2196F3 (Azul) |
| Ansioso | 😰 | #FF9800 (Laranja) |
| Irritado | 😠 | #F44336 (Vermelho) |
| Cansado | 😴 | #9E9E9E (Cinza) |
| Empolgado | 🤩 | #E91E63 (Rosa) |
| Grato | 🙏 | #9C27B0 (Roxo) |
| Sereno | 😌 | #00BCD4 (Ciano) |
| Amado | 🥰 | #FF4081 (Rosa forte) |
| Confuso | 😕 | #795548 (Marrom) |
| Orgulhoso | 😎 | #FF5722 (Laranja profundo) |
| Esperançoso | 🌟 | #FFEB3B (Amarelo) |

---

**Feito com ❤️ inspirado no belíssimo design do StoryPad**
