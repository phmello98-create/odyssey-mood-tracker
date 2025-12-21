# Odyssey MCP Server

Um servidor MCP (Model Context Protocol) especializado para desenvolvimento e manutenção do app Flutter **Odyssey Mood Tracker**.

## 🎯 O que é este servidor?

Este é um servidor MCP que fornece ferramentas especializadas para:

- 🔍 Análise de código Flutter/Dart
- 📦 Gerenciamento de dependências
- 🎨 Inspeção de widgets
- ⚡ Análise de performance
- 🔥 Verificação de integração Firebase
- 💾 Análise de modelos Hive
- 🤖 Geração de código boilerplate
- 📚 Acesso à documentação do projeto

## 🚀 Instalação

### 1. Instalar dependências Python

```bash
cd odyssey-mcp-server
pip install -r requirements.txt
```

### 2. Configurar no Antigravity IDE

Adicione a seguinte configuração:

**Caminho do arquivo de configuração**: `~/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json`

```json
{
  "mcpServers": {
    "odyssey-flutter": {
      "command": "python",
      "args": [
        "/home/agyspc/Downloads/odyssey-mood-tracker/odyssey-mcp-server/server.py"
      ],
      "env": {
        "PROJECT_ROOT": "/home/agyspc/Downloads/odyssey-mood-tracker"
      }
    }
  }
}
```

### 3. Testar o servidor

```bash
python server.py
```

## 🛠️ Ferramentas Disponíveis

### Análise de Código

- **flutter_analyze_file**: Analisa um arquivo Dart específico
- **analyze_performance**: Identifica problemas de performance
- **analyze_state_management**: Analisa uso de Riverpod
- **search_code**: Busca código no projeto

### Widgets

- **find_widget_usage**: Encontra uso de widgets específicos
- **get_widget_tree**: Extrai árvore de widgets
- **generate_widget_template**: Gera templates de widgets

### Dependências

- **get_dependencies**: Lista todas as dependências
- **find_unused_dependencies**: Encontra dependências não utilizadas

### Firebase e Database

- **check_firebase_integration**: Verifica configuração Firebase
- **analyze_hive_models**: Analisa modelos Hive

### Geração de Código

- **generate_riverpod_provider**: Gera providers Riverpod
- **generate_widget_template**: Gera widgets

### Projeto

- **list_project_features**: Lista features do projeto
- **analyze_routing**: Analisa rotas GoRouter

## 📚 Recursos (Resources)

- `odyssey://project/structure` - Estrutura do projeto
- `odyssey://project/docs` - Documentação principal
- `odyssey://patterns/common` - Padrões comuns
- `odyssey://project/dependencies` - Grafo de dependências
- `odyssey://project/features/{feature_name}` - Detalhes de features

## 💬 Prompts

- **flutter_debug_prompt** - Ajuda com debugging
- **optimize_code_prompt** - Sugestões de otimização
- **refactor_suggestion_prompt** - Sugestões de refatoração

## 📖 Exemplos de Uso

### Analisar um arquivo

```
Use a ferramenta flutter_analyze_file com o caminho:
lib/src/features/home/presentation/home_screen.dart
```

### Gerar um provider

```
Use generate_riverpod_provider com:
- provider_name: "tasks"
- provider_type: "StateNotifierProvider"
```

### Encontrar widgets

```
Use find_widget_usage com:
- widget_name: "StreakWidget"
```

## 🔧 Desenvolvimento

### Estrutura

```
odyssey-mcp-server/
├── server.py              # Servidor principal
├── requirements.txt       # Dependências
├── tools/                 # Ferramentas MCP
│   ├── flutter_analyzer.py
│   ├── dependency_manager.py
│   ├── widget_inspector.py
│   └── code_generator.py
└── resources/             # Recursos MCP
    ├── project_structure.py
    └── documentation.py
```

### Adicionar nova ferramenta

1. Criar método no módulo apropriado (tools/)
2. Adicionar decorator `@mcp.tool()` no server.py
3. Documentar a ferramenta

## 📝 Licença

Este servidor faz parte do projeto Odyssey Mood Tracker.
