#!/bin/bash

# Script para configurar ambiente de "vibe coding" com Flutter e IA
# Uso: ./flutter-vibe.sh [comando]

set -e  # Sai se alguma operação falhar

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

echo_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

echo_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se estamos em um projeto Flutter
check_flutter_project() {
    if [ ! -f "pubspec.yaml" ] || ! grep -q "sdk: flutter" pubspec.yaml; then
        echo_error "Não parece ser um projeto Flutter (pubspec.yaml não encontrado ou não contém sdk: flutter)"
        exit 1
    fi
    echo_success "Projeto Flutter detectado!"
}

# Função para criar repomix.config.json se não existir
create_repomix_config() {
    if [ ! -f "repomix.config.json" ]; then
        echo_info "Criando repomix.config.json..."
        cat > repomix.config.json << 'EOF'
{
  "ignore": {
    "useGitignore": true,
    "customPatterns": [
      "**/android/**",
      "**/ios/**",
      "**/linux/**", 
      "**/macos/**",
      "**/web/**",
      "**/windows/**", 
      "**/build/**",
      "**/.dart_tool/**",
      "**/*.g.dart",
      "**/*.freezed.dart",
      "**/pubspec.lock",
      "**/assets/**"
    ]
  }
}
EOF
        echo_success "repomix.config.json criado!"
    else
        echo_info "repomix.config.json já existe"
    fi
}

# Função para criar fluttermap script
setup_fluttermap_alias() {
    # Para a nova versão do codemap, criamos um script que filtra os resultados
    FLUTTERMAP_SCRIPT_CONTENT='#!/bin/bash
# Script para mapeamento otimizado do Flutter
codemap . | grep -v -E "android/|ios/|linux/|macos/|web/|build/|\\.dart_tool/|\\.g\\.dart|\\.freezed\\.dart|pubspec\\.lock|windows/"'

    # Cria o script fluttermap no diretório local
    echo "$FLUTTERMAP_SCRIPT_CONTENT" > /tmp/fluttermap_script
    chmod +x /tmp/fluttermap_script

    # Tenta colocar no PATH
    if command -v sudo >/dev/null 2>&1; then
        sudo cp /tmp/fluttermap_script /usr/local/bin/fluttermap 2>/dev/null || cp /tmp/fluttermap_script $HOME/.local/bin/fluttermap
    else
        cp /tmp/fluttermap_script $HOME/.local/bin/fluttermap
    fi

    echo_info "Script fluttermap criado!"
}

# Função para gerar contexto do projeto
generate_context() {
    echo_info "Gerando contexto do projeto..."
    
    echo "=== PUBSPEC.YAML ===" > project-context.txt
    cat pubspec.yaml >> project-context.txt
    echo "" >> project-context.txt
    
    echo "=== ESTRUTURA DO PROJETO ===" >> project-context.txt
    # Para versão atual do codemap, criamos .gitignore temporário com os padrões de exclusão
    # ou usamos diretamente o codemap normal que já respeita .gitignore
    codemap . >> project-context.txt
    echo "" >> project-context.txt
    
    echo_success "Contexto salvo em project-context.txt"
    echo_info "Copie o conteúdo desse arquivo para enviar para IA"
}

# Função para analisar erros do Flutter
analyze_errors() {
    echo_info "Analisando erros do projeto..."
    flutter analyze > flutter-analyze-report.txt
    echo_success "Relatório de análise salvo em flutter-analyze-report.txt"
    
    if [ -s flutter-analyze-report.txt ] && ! grep -q "No issues found!" flutter-analyze-report.txt; then
        echo_warning "Erros encontrados! Veja flutter-analyze-report.txt"
        echo_info "Conteúdo relevante para IA:"
        grep -v "Analyzing" flutter-analyze-report.txt
    else
        echo_success "Nenhum erro encontrado!"
    fi
}

# Função para empacotar o projeto (opcional, por segurança)
package_project() {
    echo_info "Empacotando projeto (usando repomix.config.json)..."
    
    # Verifica se repomix está instalado
    if ! command -v repomix &> /dev/null; then
        echo_error "repomix não está instalado. Instale com: npm install -g repomix-cli"
        echo_warning "Pulando etapa de empacotamento"
        return
    fi
    
    repomix
    echo_success "Projeto empacotado em repomix-output.txt"
}

# Menu de opções
show_help() {
    echo "Uso: $0 [opção]"
    echo ""
    echo "Opções disponíveis:"
    echo "  setup     - Configura ambiente completo (repomix.config.json, alias, etc)"
    echo "  context   - Gera contexto do projeto para IA (project-context.txt)"
    echo "  analyze   - Roda flutter analyze e salva relatório"
    echo "  package   - Empacota o projeto usando repomix (opcional)"
    echo "  all       - Roda todas as etapas (menos package)"
    echo "  help      - Mostra esta ajuda"
    echo ""
    echo "Exemplo: $0 setup"
}

case "$1" in
    setup)
        echo_info "Configurando ambiente Flutter para IA..."
        check_flutter_project
        create_repomix_config
        setup_fluttermap_alias
        generate_context
        echo_success "Ambiente configurado! Recarregue o shell com: source ~/.zshrc ou source ~/.bashrc"
        ;;
    context)
        echo_info "Gerando contexto do projeto..."
        check_flutter_project
        generate_context
        ;;
    analyze)
        echo_info "Analisando projeto..."
        check_flutter_project
        analyze_errors
        ;;
    package)
        echo_info "Empacotando projeto..."
        check_flutter_project
        package_project
        ;;
    all)
        echo_info "Rodando todas as etapas..."
        check_flutter_project
        create_repomix_config
        generate_context
        analyze_errors
        ;;
    help|"")
        show_help
        ;;
    *)
        echo_error "Opção inválida: $1"
        show_help
        exit 1
        ;;
esac