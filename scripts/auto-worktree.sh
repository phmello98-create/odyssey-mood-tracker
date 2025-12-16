#!/bin/bash
# Auto Worktree - Sistema de Segurança Automático para Odyssey

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Função para printar com cor
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_title() {
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Banner
clear
print_title "🌳 ODYSSEY AUTO WORKTREE"
echo ""

# Verifica se está em um repositório Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Este diretório não é um repositório Git!"
    exit 1
fi

# Diretório base do projeto
PROJECT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_DIR="$PROJECT_ROOT/.worktrees"

# Criar diretório de worktrees se não existir
if [ ! -d "$WORKTREE_DIR" ]; then
    mkdir -p "$WORKTREE_DIR"
    print_status "Diretório de worktrees criado: $WORKTREE_DIR"
fi

# Garantir que está no diretório correto
cd "$PROJECT_ROOT"

# Verificar branch atual
CURRENT_BRANCH=$(git branch --show-current)
print_info "Branch atual: ${YELLOW}$CURRENT_BRANCH${NC}"

# Se não está na main, avisar
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "Você não está na branch main!"
    read -p "Continuar mesmo assim? (s/n): " continue_anyway
    if [[ ! $continue_anyway =~ ^[Ss]$ ]]; then
        print_info "Operação cancelada."
        exit 0
    fi
fi

# Garantir que a main está limpa
echo ""
print_info "Verificando estado do repositório..."

# Verificar se há mudanças não commitadas
if ! git diff-index --quiet HEAD --; then
    print_warning "Você tem mudanças não salvas!"
    echo ""
    git status -s
    echo ""
    echo "Opções:"
    echo "1) Salvar mudanças (git add + commit)"
    echo "2) Guardar temporariamente (git stash)"
    echo "3) Descartar mudanças (⚠️ CUIDADO!)"
    echo "4) Cancelar"
    read -p "Escolha (1/2/3/4): " choice
    
    case $choice in
        1)
            print_info "Salvando mudanças..."
            git add -A
            read -p "Mensagem do commit: " commit_msg
            if [ -z "$commit_msg" ]; then
                commit_msg="WIP: Salvamento automático antes de criar worktree"
            fi
            git commit -m "$commit_msg"
            print_status "Mudanças salvas!"
            ;;
        2)
            print_info "Guardando mudanças temporariamente..."
            git stash push -m "Auto-stash antes de worktree $(date +%Y%m%d-%H%M%S)"
            print_status "Mudanças guardadas! (recupere com: git stash pop)"
            ;;
        3)
            print_warning "⚠️  Tem certeza? Esta ação NÃO pode ser desfeita!"
            read -p "Digite 'SIM' para confirmar: " confirm
            if [ "$confirm" = "SIM" ]; then
                print_info "Descartando mudanças..."
                git reset --hard HEAD
                git clean -fd
                print_status "Mudanças descartadas!"
            else
                print_info "Operação cancelada."
                exit 0
            fi
            ;;
        4)
            print_info "Operação cancelada."
            exit 0
            ;;
        *)
            print_error "Opção inválida!"
            exit 1
            ;;
    esac
fi

# Atualizar main (pull)
echo ""
print_info "Atualizando branch $CURRENT_BRANCH..."
git pull --rebase 2>/dev/null || print_warning "Não foi possível atualizar (sem remote ou sem conexão)"

# Nome da branch
echo ""
print_title "Nova Branch de Trabalho"
echo ""
print_info "Sugestões de nomes:"
echo "  • ${BLUE}feature-nome${NC} - Para nova funcionalidade"
echo "  • ${BLUE}fix-problema${NC} - Para corrigir bug"
echo "  • ${BLUE}experiment-ideia${NC} - Para testar algo"
echo "  • ${BLUE}work-tarefa${NC} - Trabalho geral"
echo ""

DEFAULT_NAME="work-$(date +%Y%m%d-%H%M)"
read -p "Nome da branch (Enter para '${YELLOW}$DEFAULT_NAME${NC}'): " BRANCH_NAME
BRANCH_NAME=${BRANCH_NAME:-$DEFAULT_NAME}

# Sanitizar nome (remover espaços e caracteres especiais)
BRANCH_NAME=$(echo "$BRANCH_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g')

# Verificar se branch já existe
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    print_error "Branch já existe: $BRANCH_NAME"
    read -p "Usar mesmo assim? Será criado um worktree dela. (s/n): " use_existing
    if [[ ! $use_existing =~ ^[Ss]$ ]]; then
        print_info "Operação cancelada."
        exit 0
    fi
    CREATE_NEW_BRANCH=false
else
    CREATE_NEW_BRANCH=true
fi

# Criar worktree
WORKTREE_PATH="$WORKTREE_DIR/$BRANCH_NAME"

if [ -d "$WORKTREE_PATH" ]; then
    print_error "Worktree já existe: $WORKTREE_PATH"
    print_info "Para limpar: git worktree remove $WORKTREE_PATH"
    exit 1
fi

echo ""
print_info "Criando worktree em: ${YELLOW}$WORKTREE_PATH${NC}"

if [ "$CREATE_NEW_BRANCH" = true ]; then
    git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
else
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
fi

if [ $? -eq 0 ]; then
    echo ""
    print_title "✨ Worktree Criado com Sucesso!"
    echo ""
    print_status "Branch: ${GREEN}$BRANCH_NAME${NC}"
    print_status "Local: ${GREEN}$WORKTREE_PATH${NC}"
    echo ""
    
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Para trabalhar nesta branch:"
    echo ""
    echo "  ${BLUE}cd $WORKTREE_PATH${NC}"
    echo ""
    
    print_info "Para abrir no VS Code:"
    echo ""
    echo "  ${BLUE}code $WORKTREE_PATH${NC}"
    echo ""
    
    print_info "Para voltar à main:"
    echo ""
    echo "  ${BLUE}cd $PROJECT_ROOT${NC}"
    echo ""
    
    print_info "Para fazer merge (quando terminar):"
    echo ""
    echo "  ${BLUE}git wmerge${NC}"
    echo ""
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Perguntar se quer abrir automaticamente
    read -p "Abrir worktree no VS Code agora? (s/n): " open_code
    if [[ $open_code =~ ^[Ss]$ ]]; then
        code "$WORKTREE_PATH"
        print_status "VS Code aberto!"
    fi
    
    echo ""
    print_info "Para ver todos os worktrees: ${BLUE}git wlist${NC}"
    echo ""
else
    print_error "Erro ao criar worktree!"
    exit 1
fi
