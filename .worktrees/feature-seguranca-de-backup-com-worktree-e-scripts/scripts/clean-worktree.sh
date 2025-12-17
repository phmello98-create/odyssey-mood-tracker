#!/bin/bash
# Clean Worktree - Remover worktrees antigos do Odyssey

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
print_title "🧹 LIMPAR WORKTREES"

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Este diretório não é um repositório Git!"
    exit 1
fi

PROJECT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_DIR="$PROJECT_ROOT/.worktrees"

# Listar worktrees
echo ""
print_info "Worktrees existentes:"
echo ""

# Guardar lista de worktrees (exceto a main)
WORKTREES=$(git worktree list | grep -v "$(git rev-parse --show-toplevel)$")

if [ -z "$WORKTREES" ]; then
    print_warning "Nenhum worktree encontrado!"
    echo ""
    print_info "Para criar um novo: ${BLUE}git work${NC}"
    exit 0
fi

# Mostrar worktrees com numeração
i=1
declare -a WORKTREE_PATHS
declare -a WORKTREE_BRANCHES

while IFS= read -r line; do
    path=$(echo "$line" | awk '{print $1}')
    branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')
    
    WORKTREE_PATHS[$i]="$path"
    WORKTREE_BRANCHES[$i]="$branch"
    
    echo "  ${YELLOW}$i)${NC} $branch"
    echo "     └─ $path"
    echo ""
    
    ((i++))
done <<< "$WORKTREES"

echo ""
echo "Opções:"
echo "  ${YELLOW}1-$((i-1))${NC}) Remover worktree específico"
echo "  ${YELLOW}a${NC}) Remover TODOS os worktrees"
echo "  ${YELLOW}q${NC}) Cancelar"
echo ""
read -p "Escolha: " choice

case $choice in
    [1-9]|[1-9][0-9])
        if [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
            worktree_path="${WORKTREE_PATHS[$choice]}"
            branch_name="${WORKTREE_BRANCHES[$choice]}"
            
            echo ""
            print_info "Removendo worktree: ${YELLOW}$branch_name${NC}"
            print_warning "Local: $worktree_path"
            echo ""
            
            read -p "Tem certeza? (s/n): " confirm
            if [[ $confirm =~ ^[Ss]$ ]]; then
                # Remover worktree
                git worktree remove "$worktree_path" --force
                
                if [ $? -eq 0 ]; then
                    print_status "Worktree removido!"
                    
                    # Perguntar se quer deletar a branch
                    echo ""
                    read -p "Deletar branch ${YELLOW}$branch_name${NC} também? (s/n): " delete_branch
                    if [[ $delete_branch =~ ^[Ss]$ ]]; then
                        git branch -D "$branch_name"
                        if [ $? -eq 0 ]; then
                            print_status "Branch deletada!"
                        else
                            print_warning "Não foi possível deletar a branch"
                        fi
                    else
                        print_info "Branch mantida: ${YELLOW}$branch_name${NC}"
                    fi
                else
                    print_error "Erro ao remover worktree!"
                fi
            else
                print_info "Operação cancelada."
            fi
        else
            print_error "Opção inválida!"
        fi
        ;;
    [Aa])
        echo ""
        print_warning "⚠️  ATENÇÃO: Isso vai remover TODOS os worktrees!"
        echo ""
        read -p "Digite 'SIM' para confirmar: " confirm
        
        if [ "$confirm" = "SIM" ]; then
            print_info "Removendo todos os worktrees..."
            echo ""
            
            removed_count=0
            for ((j=1; j<i; j++)); do
                worktree_path="${WORKTREE_PATHS[$j]}"
                branch_name="${WORKTREE_BRANCHES[$j]}"
                
                print_info "Removendo: $branch_name"
                git worktree remove "$worktree_path" --force
                
                if [ $? -eq 0 ]; then
                    ((removed_count++))
                fi
            done
            
            echo ""
            print_status "$removed_count worktree(s) removido(s)!"
            
            # Perguntar se quer deletar as branches também
            echo ""
            read -p "Deletar as branches também? (s/n): " delete_branches
            if [[ $delete_branches =~ ^[Ss]$ ]]; then
                print_info "Deletando branches..."
                for ((j=1; j<i; j++)); do
                    branch_name="${WORKTREE_BRANCHES[$j]}"
                    git branch -D "$branch_name" 2>/dev/null
                done
                print_status "Branches deletadas!"
            fi
        else
            print_info "Operação cancelada."
        fi
        ;;
    [Qq])
        print_info "Operação cancelada."
        ;;
    *)
        print_error "Opção inválida!"
        ;;
esac

echo ""
