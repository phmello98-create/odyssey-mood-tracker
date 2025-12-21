# 🚀 Quick Reference - Antigravity + Odyssey

## 📍 Invocação de Sub-Agentes

### Sintaxe
```
@nome-do-agente [sua solicitação]
```

### Agentes Disponíveis

**🎨 @ui-specialist**
- Design de telas
- Widgets customizados
- Temas e cores
- Animações

**🔄 @state-management**
- Providers Riverpod
- StateNotifiers
- Otimização de rebuilds
- State complexo

**💾 @data-layer**
- Hive (storage principal)
- Isar (notes, quotes, community)
- Firebase sync
- Repositories

**✨ @code-quality**
- Análise de código
- Refactoring
- Performance
- Linting

**🧪 @testing**
- Unit tests
- Widget tests
- Mocks
- Coverage

**🔥 @firebase-backend**
- Authentication
- Firestore
- Push notifications
- Storage

---

## 🛠️ MCP Server - Comandos Úteis

### Análise de Código
```
"Analise o arquivo [caminho]"
"Encontre problemas de performance em [arquivo]"
"Liste imports não utilizados"
```

### Navegação
```
"Onde o widget [nome] é usado?"
"Mostre a árvore de widgets de [arquivo]"
"Liste todas as features do projeto"
```

### Geração
```
"Gere um provider Riverpod para [nome]"
"Crie um widget stateless chamado [nome]"
```

### Dependencies
```
"Liste todas as dependências"
"Encontre dependências não utilizadas"
"Verifique integração Firebase"
```

---

## 📦 Tecnologias do Projeto

### Persistência
- **Hive** → mood, tasks, habits, diary, library
- **Isar** → notes, quotes, community ⚡
- **Firebase** → auth, sync, FCM

### State
- **Riverpod 2.x** → Obrigatório
- **AutoDispose** → Para evitar leaks

### UI
- **Material Design 3**
- **Temas múltiplos**
- **Lottie** animations

---

## 🎯 Comandos Rápidos

### Build
```bash
# Gerar código (Freezed + Hive)
flutter pub run build_runner build --delete-conflicting-outputs

# Gerar código Isar
dart run build_runner build

# Watch mode
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Análise
```bash
flutter analyze      # Warnings/errors
flutter test         # Testes
flutter run          # Executar
```

---

## 🔒 Regras de Ouro

1. ❌ NUNCA modifique `.g.dart` ou `.freezed.dart`
2. ✅ SEMPRE use Riverpod (não setState)
3. ✅ SEMPRE localize strings (pt_BR → en)
4. ✅ Registre adapters Hive em `AppInitializer`
5. ✅ Use `const` sempre que possível
6. ✅ Evite aninhamento > 5 níveis

---

## 📁 Localização de Arquivos

```
/home/agys/.gemini/
├── GEMINI.md              # Regras globais
├── agents/                # Sub-agentes
│   └── README.md          # Guia completo
└── antigravity/
    └── mcp_config.json    # Config MCP

/home/agys/Documentos/odyssey-mood-tracker/
├── odyssey-mcp-server/    # Servidor MCP
└── .gemini/
    └── CONFIGURACAO_COMPLETA.md  # Guia detalhado
```

---

**Após reiniciar o Antigravity, tudo estará ativo!**
