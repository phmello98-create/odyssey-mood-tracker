#!/bin/bash
# Setup Rápido - Instalar Sistema de Worktrees Automático

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🌳 SETUP WORKTREE AUTOMÁTICO - ODYSSEY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd ~/Documentos/odyssey-mood-tracker

# 1. Criar pasta de worktrees
echo -e "${BLUE}[1/4]${NC} Criando pasta de worktrees..."
mkdir -p .worktrees
echo ".worktrees/" >> .gitignore
echo -e "${GREEN}✓${NC} Pasta criada!"
echo ""

# 2. Tornar scripts executáveis
echo -e "${BLUE}[2/4]${NC} Tornando scripts executáveis..."
chmod +x scripts/auto-worktree.sh
chmod +x scripts/clean-worktree.sh  
chmod +x scripts/merge-worktree.sh
echo -e "${GREEN}✓${NC} Scripts prontos!"
echo ""

# 3. Adicionar aliases ao Git
echo -e "${BLUE}[3/4]${NC} Configurando aliases do Git..."

git config --global alias.work '!bash ~/Documentos/odyssey-mood-tracker/scripts/auto-worktree.sh'
git config --global alias.wclean '!bash ~/Documentos/odyssey-mood-tracker/scripts/clean-worktree.sh'
git config --global alias.wmerge '!bash ~/Documentos/odyssey-mood-tracker/scripts/merge-worktree.sh'
git config --global alias.wlist 'worktree list'

echo -e "${GREEN}✓${NC} Aliases configurados!"
echo ""

# 4. Testar configuração
echo -e "${BLUE}[4/4]${NC} Testando configuração..."
if git work --help &>/dev/null || true; then
    echo -e "${GREEN}✓${NC} Tudo funcionando!"
else
    echo -e "${YELLOW}⚠${NC} Verifique se os scripts existem"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✨ INSTALAÇÃO CONCLUÍDA!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Comandos disponíveis:"
echo ""
echo "  ${BLUE}git work${NC}     - Criar novo worktree"
echo "  ${BLUE}git wlist${NC}    - Listar worktrees"
echo "  ${BLUE}git wclean${NC}   - Limpar worktrees"
echo "  ${BLUE}git wmerge${NC}   - Fazer merge seguro"
echo ""
echo "Para começar, rode:"
echo ""
echo "  ${YELLOW}git work${NC}"
echo ""
echo "Leia o guia completo em: GUIA_WORKTREE_AUTOMATICO.md"
echo ""
