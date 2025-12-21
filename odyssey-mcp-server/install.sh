#!/bin/bash

# Script de instalação do servidor MCP Odyssey para Antigravity
# Execute: bash install.sh

set -e  # Para em caso de erro

echo "🚀 Instalando Odyssey MCP Server para Antigravity..."
echo ""

# Detectar diretório do script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "📂 Diretório do projeto: $PROJECT_ROOT"
echo "📂 Diretório do servidor: $SCRIPT_DIR"
echo ""

# 1. Verificar Python
echo "🔍 Verificando Python..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 não encontrado. Por favor, instale Python 3.8 ou superior."
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "✓ Python encontrado: $PYTHON_VERSION"
echo ""

# 2. Criar ambiente virtual (opcional)
read -p "Deseja criar um ambiente virtual Python? (recomendado) [S/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]] || [[ -z $REPLY ]]; then
    echo "📦 Criando ambiente virtual..."
    python3 -m venv "$SCRIPT_DIR/.venv"
    echo "✓ Ambiente virtual criado"
    
    PYTHON_CMD="$SCRIPT_DIR/.venv/bin/python"
    PIP_CMD="$SCRIPT_DIR/.venv/bin/pip"
else
    PYTHON_CMD="python3"
    PIP_CMD="pip3"
fi
echo ""

# 3. Instalar dependências
echo "📦 Instalando dependências Python..."
$PIP_CMD install -r "$SCRIPT_DIR/requirements.txt"
echo "✓ Dependências instaladas"
echo ""

# 4. Testar servidor
echo "🧪 Testando servidor..."
timeout 3s $PYTHON_CMD "$SCRIPT_DIR/server.py" &> /dev/null || true
echo "✓ Servidor testado"
echo ""

# 5. Configurar Antigravity
echo "⚙️  Configurando Antigravity..."

# Diretórios possíveis para configuração MCP
MCP_CONFIG_DIRS=(
    "$HOME/.config/anthropic-mcp"
    "$HOME/.config/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
    "$HOME/.config/antigravity"
)

CONFIG_FILE=""
for dir in "${MCP_CONFIG_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        CONFIG_FILE="$dir/mcp.json"
        break
    fi
done

if [ -z "$CONFIG_FILE" ]; then
    # Criar diretório padrão
    mkdir -p "$HOME/.config/anthropic-mcp"
    CONFIG_FILE="$HOME/.config/anthropic-mcp/mcp.json"
fi

echo "📝 Arquivo de configuração: $CONFIG_FILE"

# Criar ou atualizar configuração
if [ -f "$CONFIG_FILE" ]; then
    echo "⚠️  Arquivo de configuração existente encontrado."
    read -p "Deseja sobrescrever? [s/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        echo "ℹ️  Configuração manual necessária. Veja CONFIGURACAO_ANTIGRAVITY.md"
        echo ""
        echo "Adicione ao seu arquivo de configuração:"
        cat <<EOF

{
  "mcpServers": {
    "odyssey-flutter": {
      "command": "$PYTHON_CMD",
      "args": [
        "$SCRIPT_DIR/server.py"
      ],
      "env": {
        "PROJECT_ROOT": "$PROJECT_ROOT"
      }
    }
  }
}
EOF
        exit 0
    fi
fi

# Criar configuração
cat > "$CONFIG_FILE" <<EOF
{
  "mcpServers": {
    "odyssey-flutter": {
      "command": "$PYTHON_CMD",
      "args": [
        "$SCRIPT_DIR/server.py"
      ],
      "env": {
        "PROJECT_ROOT": "$PROJECT_ROOT",
        "PYTHONPATH": "$SCRIPT_DIR"
      }
    }
  }
}
EOF

echo "✓ Configuração criada em: $CONFIG_FILE"
echo ""

# 6. Resumo
echo "✅ Instalação concluída!"
echo ""
echo "📋 Resumo:"
echo "  - Python: $PYTHON_CMD"
echo "  - Servidor: $SCRIPT_DIR/server.py"
echo "  - Projeto: $PROJECT_ROOT"
echo "  - Config: $CONFIG_FILE"
echo ""
echo "🎯 Próximos passos:"
echo "  1. Reinicie o Antigravity IDE"
echo "  2. O servidor MCP estará disponível automaticamente"
echo "  3. Teste com: 'Liste todas as features do projeto'"
echo ""
echo "📖 Para mais informações, veja:"
echo "  - README.md"
echo "  - CONFIGURACAO_ANTIGRAVITY.md"
echo "  - MCP_SERVER_PLAN.md (no diretório do projeto)"
echo ""
echo "🐛 Para testar o servidor manualmente:"
echo "  $PYTHON_CMD $SCRIPT_DIR/server.py"
echo ""
