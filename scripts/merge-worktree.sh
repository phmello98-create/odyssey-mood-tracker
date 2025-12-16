#!/bin/bash
# Merge Worktree - Juntar mudanças de volta à main com segurança

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

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

clear
print_title "🔀 MERGE SEGURO"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Este diretório não é um repositório Git!"
    exit 1
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Verificar se está na main
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "main" ]; then
    print_error "Você deve estar na branch main para fazer merge!"
    echo ""
    print_info "Execute primeiro: ${BLUE}cd $PROJECT_ROOT${NC}"
    exit 1
fi

# Verificar se há mudanças não commitadas na main
if ! git diff-index --quiet HEAD --; then
    print_error "Você tem mudanças não commitadas na main!"
    echo ""
    print_info "Salve ou descarte as mudanças primeiro"
    exit 1
fi

# Listar branches disponíveis (exceto main)
echo ""
print_info "Branches disponíveis para merge:"
echo ""

BRANCHES=$(git branch | grep -v "^\*" | grep -v "main" | sed 's/^[* ]*//')

if [ -z "$BRANCHES" ]; then
    print_warning "Nenhuma branch encontrada para merge!"
    exit 0
fi

i=1
declare -a BRANCH_LIST

while IFS= read -r branch; do
    BRANCH_LIST[$i]="$branch"
    
    # Contar commits à frente
    ahead=$(git rev-list --count main..$branch 2>/dev/null || echo "?")
    
    echo "  ${YELLOW}$i)${NC} $branch ${BLUE}(+$ahead commits)${NC}"
    
    ((i++))
done <<< "$BRANCHES"

echo ""
echo "Digite o número da branch ou 'q' para cancelar"
read -p "Escolha: " choice

if [[ $choice =~ ^[Qq]$ ]]; then
    print_info "Operação cancelada."
    exit 0
fi

# Validar escolha
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -ge "$i" ]; then
    print_error "Opção inválida!"
    exit 1
fi

branch_name="${BRANCH_LIST[$choice]}"

# Verificar se a branch existe
if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
    print_error "Branch não existe: $branch_name"
    exit 1
fi

# Mostrar preview do merge
echo ""
print_title "Preview do Merge"
echo ""
print_info "Branch: ${YELLOW}$branch_name${NC}"
print_info "Destino: ${YELLOW}main${NC}"
echo ""

# Mostrar commits que serão mergeados
print_info "Commits que serão adicionados à main:"
echo ""
git log main..$branch_name --oneline --decorate --color=always | head -10
echo ""

# Mostrar arquivos modificados
print_info "Arquivos modificados:"
echo ""
git diff --stat main..$branch_name | head -20
echo ""

# Confirmar merge
print_warning "⚠️  Isso vai fazer merge de '$branch_name' na main"
echo ""
read -p "Continuar? (s/n): " confirm

if [[ ! $confirm =~ ^[Ss]$ ]]; then
    print_info "Operação cancelada."
    exit 0
fi

# Criar backup automático antes do merge
BACKUP_BRANCH="backup-main-$(date +%Y%m%d-%H%M%S)"
echo ""
print_info "Criando backup de segurança: ${YELLOW}$BACKUP_BRANCH${NC}"
git branch "$BACKUP_BRANCH"

if [ $? -eq 0 ]; then
    print_status "Backup criado!"
    print_info "Para reverter: ${BLUE}git reset --hard $BACKUP_BRANCH${NC}"
else
    print_error "Erro ao criar backup!"
    exit 1
fi

# Fazer merge
echo ""
print_info "Fazendo merge de ${YELLOW}$branch_name${NC} em ${YELLOW}main${NC}..."
echo ""

git merge "$branch_name" --no-ff -m "Merge branch '$branch_name'"

if [ $? -eq 0 ]; then
    echo ""
    print_title "✨ Merge Concluído!"
    echo ""
    print_status "Branch ${YELLOW}$branch_name${NC} foi mergeada na main"
    print_status "Backup mantido em: ${YELLOW}$BACKUP_BRANCH${NC}"
    echo ""
    
    # Mostrar log depois do merge
    print_info "Últimos commits:"
    echo ""
    git log --oneline --decorate --color=always -5
    echo ""
    
    # Perguntar se quer deletar a branch
    read -p "Deletar branch ${YELLOW}$branch_name${NC}? (s/n): " delete_branch
    
    if [[ $delete_branch =~ ^[Ss]$ ]]; then
        # Remover worktree se existir
        WORKTREE_PATH="$PROJECT_ROOT/.worktrees/$branch_name"
        if [ -d "$WORKTREE_PATH" ]; then
            print_info "Removendo worktree..."
            git worktree remove "$WORKTREE_PATH" --force
        fi
        
        # Deletar branch
        git branch -d "$branch_name"
        
        if [ $? -eq 0 ]; then
            print_status "Branch deletada!"
        else
            print_warning "Não foi possível deletar a branch (use -D para forçar)"
        fi
    else
        print_info "Branch mantida: ${YELLOW}$branch_name${NC}"
    fi
    
    echo ""
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_info "Para testar as mudanças:"
    echo "  ${BLUE}flutter run${NC}"
    echo ""
    print_info "Para desfazer o merge:"
    echo "  ${BLUE}git reset --hard $BACKUP_BRANCH${NC}"
    echo ""
    print_info "Para limpar backup quando tiver certeza:"
    echo "  ${BLUE}git branch -D $BACKUP_BRANCH${NC}"
    print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
else
    echo ""
    print_error "❌ Conflito no Merge!"
    echo ""
    print_warning "Há conflitos que precisam ser resolvidos manualmente"
    echo ""
    
    # Mostrar arquivos com conflito
    print_info "Arquivos em conflito:"
    echo ""
    git diff --name-only --diff-filter=U | sed 's/^/  /'
    echo ""
    
    print_info "Para resolver:"
    echo ""
    echo "  1) Abra os arquivos com conflito no VS Code"
    echo "  2) Resolva os conflitos (procure por <<<<<<< e >>>>>>>)"
    echo "  3) Adicione os arquivos resolvidos:"
    echo "     ${BLUE}git add <arquivo>${NC}"
    echo "  4) Finalize o merge:"
    echo "     ${BLUE}git commit${NC}"
    echo ""
    
    print_info "Ou cancele o merge:"
    echo "  ${BLUE}git merge --abort${NC}"
    echo ""
    
    print_info "Para reverter ao estado anterior:"
    echo "  ${BLUE}git reset --hard $BACKUP_BRANCH${NC}"
fi

echo ""
