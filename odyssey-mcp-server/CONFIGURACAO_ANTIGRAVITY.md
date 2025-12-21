# 🚀 Guia de Configuração MCP no Antigravity

Este guia mostra como configurar o servidor MCP do Odyssey no Antigravity IDE.

## 📋 Pré-requisitos

- Python 3.8 ou superior
- Antigravity IDE instalado
- Acesso ao projeto Odyssey

## 🔧 Passo a Passo

### 1. Instalar Dependências Python

Primeiro, crie um ambiente virtual e instale as dependências:

```bash
cd /home/agyspc/Downloads/odyssey-mood-tracker/odyssey-mcp-server

# Criar ambiente virtual (opcional mas recomendado)
python3 -m venv .venv

# Ativar ambiente virtual
source .venv/bin/activate  # Linux/Mac
# ou
.venv\Scripts\activate  # Windows

# Instalar dependências
pip install -r requirements.txt
```

### 2. Testar o Servidor Localmente

Antes de integrar com o Antigravity, teste se o servidor funciona:

```bash
python server.py
```

Você deve ver:
```
🚀 Odyssey Flutter MCP Server starting...
📂 Project root: /home/agyspc/Downloads/odyssey-mood-tracker
✓ Server initialized with X tools
✓ Resources available: X
✓ Prompts available: X
```

### 3. Configurar no Antigravity

#### Opção A: Configuração Global (Recomendado)

O Antigravity usa arquivos de configuração MCP. Você precisa criar ou editar o arquivo de configuração:

**Arquivo**: `~/.config/anthropic-mcp/mcp.json`

```json
{
  "mcpServers": {
    "odyssey-flutter": {
      "command": "python",
      "args": [
        "/home/agyspc/Downloads/odyssey-mood-tracker/odyssey-mcp-server/server.py"
      ],
      "env": {
        "PROJECT_ROOT": "/home/agyspc/Downloads/odyssey-mood-tracker",
        "PYTHONPATH": "/home/agyspc/Downloads/odyssey-mood-tracker/odyssey-mcp-server"
      }
    }
  }
}
```

**Se usar ambiente virtual**, modifique o `command`:

```json
{
  "mcpServers": {
    "odyssey-flutter": {
      "command": "/home/agyspc/Downloads/odyssey-mood-tracker/odyssey-mcp-server/.venv/bin/python",
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

#### Opção B: Script de Instalação Automática

Execute o script de instalação:

```bash
bash /home/agyspc/Downloads/odyssey-mood-tracker/odyssey-mcp-server/install.sh
```

### 4. Reiniciar o Antigravity

Após configurar, reinicie o Antigravity IDE para que ele carregue o servidor MCP.

### 5. Verificar Integração

No Antigravity, você deve conseguir ver e usar as ferramentas MCP:

1. Abra o Antigravity
2. Inicie uma conversa
3. O servidor MCP deve aparecer como disponível
4. Você pode usar comandos como:
   - "Analise o arquivo home_screen.dart"
   - "Liste todas as dependências do projeto"
   - "Gere um provider Riverpod chamado tasks"

## 🛠️ Ferramentas Disponíveis

Uma vez configurado, você terá acesso a:

### Análise
- `flutter_analyze_file` - Analisa arquivos Dart
- `analyze_performance` - Verifica performance
- `analyze_state_management` - Analisa providers
- `search_code` - Busca código

### Widgets
- `find_widget_usage` - Encontra uso de widgets
- `get_widget_tree` - Árvore de widgets
- `generate_widget_template` - Gera widgets

### Dependências
- `get_dependencies` - Lista dependências
- `find_unused_dependencies` - Encontra não usadas

### Geração
- `generate_riverpod_provider` - Gera providers
- `generate_widget_template` - Gera widgets
- `generate_screen` - Gera screens completas

### Projeto
- `list_project_features` - Lista features
- `analyze_routing` - Analisa rotas

## 📚 Recursos (Resources)

Acesse via URIs:
- `odyssey://project/structure`
- `odyssey://project/docs`
- `odyssey://patterns/common`
- `odyssey://project/dependencies`

## 🐛 Troubleshooting

### Servidor não inicia

1. Verifique se Python está instalado: `python --version`
2. Verifique se as dependências estão instaladas: `pip list`
3. Teste o servidor manualmente: `python server.py`

### Antigravity não reconhece o servidor

1. Verifique o arquivo de configuração MCP
2. Certifique-se de que os caminhos estão corretos
3. Reinicie o Antigravity
4. Verifique os logs do Antigravity

### Erros de importação Python

1. Verifique se `PYTHONPATH` está configurado
2. Use ambiente virtual e especifique o caminho do Python
3. Instale novamente as dependências: `pip install -r requirements.txt`

### Comandos não funcionam

1. Verifique se o projeto Flutter está no caminho correto
2. Verifique variável `PROJECT_ROOT`
3. Teste as ferramentas individualmente

## 💡 Dicas de Uso

### 1. Análise Rápida

```
Analise o arquivo lib/src/features/home/presentation/home_screen.dart
```

### 2. Gerar Código

```
Gere um StateNotifierProvider chamado 'tasks' para gerenciar tarefas
```

### 3. Buscar Widgets

```
Encontre todos os lugares onde StreakWidget é usado
```

### 4. Verificar Performance

```
Analise a performance do arquivo lib/src/features/community/presentation/community_screen.dart
```

### 5. Explorar Estrutura

```
Liste todas as features do projeto
```

## 🎯 Exemplos Práticos

### Debugging

Quando encontrar um erro:
```
Ajude-me a debuggar este erro:
[cole o erro aqui]
```

### Refatoração

```
Sugira refatorações para este código:
[cole o código aqui]
```

### Otimização

```
Como posso otimizar este widget para melhor performance?
[especifique o arquivo]
```

## 📞 Suporte

Se tiver problemas:
1. Verifique os logs do servidor
2. Teste o servidor manualmente
3. Verifique a configuração do Antigravity
4. Consulte a documentação do MCP

---

**Última atualização**: 2025-12-20
**Versão**: 1.0.0
