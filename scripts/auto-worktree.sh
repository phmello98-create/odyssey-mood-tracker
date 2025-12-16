#!/bin/bash
# Auto Worktree - Sistema de Segurança Automático para Odyssey

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Funções de print com cores (usando printf)
print_status() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

print_error() {
    printf "${RED}✗${NC} %s\n" "$1"
}

print_info() {
    printf "${BLUE}ℹ${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_title() {
    printf "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${MAGENTA}  %s${NC}\n" "$1"
    printf "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}
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
printf "${BLUE}ℹ${NC} Branch atual: ${YELLOW}%s${NC}\n" "$CURRENT_BRANCH"

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
            echo ""
            printf "  ${BLUE}1${NC}) 💾 WIP: Salvamento antes de worktree\n"
            printf "  ${BLUE}2${NC}) ✨ Feat: Nova funcionalidade\n"
            printf "  ${BLUE}3${NC}) 🐛 Fix: Correção de bug\n"
            printf "  ${BLUE}4${NC}) 🔧 Chore: Manutenção geral\n"
            printf "  ${BLUE}5${NC}) ✏️  Custom: Mensagem personalizada\n"
            echo ""
            printf "Escolha (1-5, Enter para opção 1): "
            read commit_choice
            commit_choice=${commit_choice:-1}
            
            case $commit_choice in
                1)
                    commit_msg="💾 WIP: Salvamento automático antes de criar worktree"
                    ;;
                2)
                    printf "Descrição da feature: "
                    read feat_desc
                    commit_msg="✨ Feat: ${feat_desc:-Nova funcionalidade}"
                    ;;
                3)
                    printf "O que foi corrigido: "
                    read fix_desc
                    commit_msg="🐛 Fix: ${fix_desc:-Correção de bug}"
                    ;;
                4)
                    commit_msg="🔧 Chore: Manutenção geral"
                    ;;
                5)
                    printf "Mensagem personalizada: "
                    read custom_msg
                    commit_msg="${custom_msg:-WIP: Salvamento antes de worktree}"
                    ;;
                *)
                    commit_msg="💾 WIP: Salvamento automático antes de criar worktree"
                    ;;
            esac
            
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
print_info "Escolha o tipo de branch:"
echo ""
printf "  ${BLUE}1${NC}) feature-    ${YELLOW}(nova funcionalidade)${NC}\n"
printf "  ${BLUE}2${NC}) fix-        ${YELLOW}(corrigir bug)${NC}\n"
printf "  ${BLUE}3${NC}) experiment- ${YELLOW}(testar algo)${NC}\n"
printf "  ${BLUE}4${NC}) refactor-   ${YELLOW}(refatoração)${NC}\n"
printf "  ${BLUE}5${NC}) work-       ${YELLOW}(trabalho geral)${NC}\n"
printf "  ${BLUE}6${NC}) custom      ${YELLOW}(nome personalizado)${NC}\n"
echo ""

DEFAULT_NAME="work-$(date +%Y%m%d-%H%M)"
printf "Escolha (1-6, Enter para '${YELLOW}%s${NC}'): " "$DEFAULT_NAME"
read choice

case $choice in
    1)
        printf "Nome da feature: "
        read feature_name
        BRANCH_NAME="feature-${feature_name:-nova}"
        ;;
    2)
        printf "O que vai corrigir: "
        read fix_name
        BRANCH_NAME="fix-${fix_name:-bug}"
        ;;
    3)
        printf "Nome do experimento: "
        read exp_name
        BRANCH_NAME="experiment-${exp_name:-teste}"
        ;;
    4)
        printf "O que vai refatorar: "
        read refactor_name
        BRANCH_NAME="refactor-${refactor_name:-code}"
        ;;
    5)
        printf "Descrição do trabalho: "
        read work_name
        BRANCH_NAME="work-${work_name:-task}"
        ;;
    6)
        printf "Nome personalizado: "
        read custom_name
        BRANCH_NAME="${custom_name:-$DEFAULT_NAME}"
        ;;
    *)
        BRANCH_NAME="$DEFAULT_NAME"
        ;;
esac

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
printf "${BLUE}ℹ${NC} Criando worktree em: ${YELLOW}%s${NC}\n" "$WORKTREE_PATH"

if [ "$CREATE_NEW_BRANCH" = true ]; then
    git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
else
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
fi

if [ $? -eq 0 ]; then
    echo ""
    print_title "✨ Worktree Criado com Sucesso!"
    echo ""
    printf "${GREEN}✓${NC} Branch: ${GREEN}%s${NC}\n" "$BRANCH_NAME"
    printf "${GREEN}✓${NC} Local: ${GREEN}%s${NC}\n" "$WORKTREE_PATH"
    echo ""
    
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Para trabalhar nesta branch:"
    echo ""
    printf "  ${BLUE}cd %s${NC}\n" "$WORKTREE_PATH"
    echo ""
    
    print_info "Para abrir no VS Code:"
    echo ""
    printf "  ${BLUE}code %s${NC}\n" "$WORKTREE_PATH"
    echo ""
    
    print_info "Para voltar à main:"
    echo ""
    printf "  ${BLUE}cd %s${NC}\n" "$PROJECT_ROOT"
    echo ""
    
    print_info "Para fazer merge (quando terminar):"
    echo ""
    printf "  ${BLUE}git wmerge${NC}\n"
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
    printf "${BLUE}ℹ${NC} Para ver todos os worktrees: ${BLUE}git wlist${NC}\n"
    echo ""
else
    print_error "Erro ao criar worktree!"
    exit 1
fi
