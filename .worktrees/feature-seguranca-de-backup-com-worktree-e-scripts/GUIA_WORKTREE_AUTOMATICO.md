# 🌳 Sistema de Worktrees Automático - Odyssey

## 🎯 Objetivo

Criar um sistema que automaticamente cria branches de segurança antes de você começar a trabalhar, para nunca mais quebrar o código principal e perder seu progresso.

## 🤔 O Que São Worktrees?

Imagine que você tem várias "cópias" do seu projeto, cada uma em uma branch diferente, mas todas compartilhando o mesmo histórico Git. Você pode trabalhar em cada uma sem afetar as outras!

```
odyssey-mood-tracker/          (main - código estável)
├── worktrees/
│   ├── feature-nova/          (testando algo novo)
│   ├── fix-bug/               (corrigindo um bug)
│   └── experiment/            (experimentando)
```

## 📋 Plano de Implementação

### Fase 1: Setup Inicial (5 minutos)

#### 1.1 Estrutura de Diretórios
```bash
cd ~/Documentos/odyssey-mood-tracker

# Criar pasta para worktrees
mkdir -p .worktrees

# Adicionar ao .gitignore para não commitar
echo ".worktrees/" >> .gitignore
```

#### 1.2 Script de Auto-Backup
Criar `scripts/auto-worktree.sh`:

```bash
#!/bin/bash
# Auto Worktree - Sistema de Segurança Automático

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Verifica se está em um repositório Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Este diretório não é um repositório Git!"
    exit 1
fi

# Diretório base do projeto
PROJECT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_DIR="$PROJECT_ROOT/.worktrees"

# Garantir que a main está limpa
echo ""
print_info "Verificando estado do repositório..."

# Verificar se há mudanças não commitadas
if ! git diff-index --quiet HEAD --; then
    print_warning "Você tem mudanças não salvas!"
    echo ""
    echo "Opções:"
    echo "1) Salvar mudanças (git add + commit)"
    echo "2) Descartar mudanças (CUIDADO!)"
    echo "3) Cancelar"
    read -p "Escolha (1/2/3): " choice
    
    case $choice in
        1)
            print_info "Salvando mudanças..."
            git add -A
            read -p "Mensagem do commit: " commit_msg
            git commit -m "$commit_msg"
            print_status "Mudanças salvas!"
            ;;
        2)
            print_warning "Descartando mudanças..."
            git reset --hard HEAD
            git clean -fd
            print_status "Mudanças descartadas!"
            ;;
        3)
            print_info "Operação cancelada."
            exit 0
            ;;
        *)
            print_error "Opção inválida!"
            exit 1
            ;;
    esac
fi

# Nome da branch
echo ""
print_info "Criando nova branch de trabalho..."
DEFAULT_NAME="work-$(date +%Y%m%d-%H%M)"
read -p "Nome da branch (Enter para '$DEFAULT_NAME'): " BRANCH_NAME
BRANCH_NAME=${BRANCH_NAME:-$DEFAULT_NAME}

# Criar worktree
WORKTREE_PATH="$WORKTREE_DIR/$BRANCH_NAME"

if [ -d "$WORKTREE_PATH" ]; then
    print_error "Worktree já existe: $WORKTREE_PATH"
    exit 1
fi

print_info "Criando worktree em: $WORKTREE_PATH"
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"

if [ $? -eq 0 ]; then
    print_status "Worktree criado com sucesso!"
    echo ""
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
    
    # Perguntar se quer abrir automaticamente
    read -p "Abrir worktree no VS Code agora? (s/n): " open_code
    if [[ $open_code == "s" || $open_code == "S" ]]; then
        code "$WORKTREE_PATH"
        print_status "VS Code aberto!"
    fi
else
    print_error "Erro ao criar worktree!"
    exit 1
fi
```

#### 1.3 Script de Limpeza
Criar `scripts/clean-worktree.sh`:

```bash
#!/bin/bash
# Clean Worktree - Remover worktrees antigos

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

PROJECT_ROOT=$(git rev-parse --show-toplevel)
WORKTREE_DIR="$PROJECT_ROOT/.worktrees"

# Listar worktrees
echo ""
print_info "Worktrees existentes:"
echo ""
git worktree list

echo ""
echo "Opções:"
echo "1) Remover um worktree específico"
echo "2) Remover todos os worktrees"
echo "3) Cancelar"
read -p "Escolha (1/2/3): " choice

case $choice in
    1)
        read -p "Nome da branch para remover: " branch_name
        worktree_path="$WORKTREE_DIR/$branch_name"
        
        if [ -d "$worktree_path" ]; then
            print_info "Removendo worktree: $branch_name"
            git worktree remove "$worktree_path"
            
            read -p "Deletar a branch também? (s/n): " delete_branch
            if [[ $delete_branch == "s" ]]; then
                git branch -D "$branch_name"
                print_status "Branch deletada!"
            fi
            print_status "Worktree removido!"
        else
            echo "Worktree não encontrado: $worktree_path"
        fi
        ;;
    2)
        print_info "Removendo todos os worktrees..."
        git worktree list | grep -v "$(git rev-parse --show-toplevel)" | awk '{print $1}' | xargs -I {} git worktree remove {}
        print_status "Todos os worktrees removidos!"
        ;;
    3)
        print_info "Operação cancelada."
        ;;
    *)
        echo "Opção inválida!"
        ;;
esac
```

#### 1.4 Script de Merge Seguro
Criar `scripts/merge-worktree.sh`:

```bash
#!/bin/bash
# Merge Worktree - Juntar mudanças de volta à main com segurança

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Verificar se está na main
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "main" ]; then
    print_error "Você deve estar na branch main para fazer merge!"
    print_info "Execute: cd $PROJECT_ROOT"
    exit 1
fi

# Listar worktrees disponíveis
echo ""
print_info "Branches disponíveis para merge:"
echo ""
git branch | grep -v "main" | sed 's/^/  /'

echo ""
read -p "Nome da branch para fazer merge: " branch_name

# Verificar se a branch existe
if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
    print_error "Branch não existe: $branch_name"
    exit 1
fi

# Criar backup automático antes do merge
BACKUP_BRANCH="backup-main-$(date +%Y%m%d-%H%M%S)"
print_info "Criando backup da main em: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"
print_status "Backup criado! (pode deletar depois com: git branch -D $BACKUP_BRANCH)"

# Fazer merge
echo ""
print_info "Fazendo merge de $branch_name em main..."
echo ""

git merge "$branch_name" --no-ff

if [ $? -eq 0 ]; then
    print_status "Merge concluído com sucesso!"
    echo ""
    
    # Perguntar se quer deletar a branch
    read -p "Deletar branch $branch_name? (s/n): " delete_branch
    if [[ $delete_branch == "s" || $delete_branch == "S" ]]; then
        # Remover worktree se existir
        WORKTREE_PATH="$PROJECT_ROOT/.worktrees/$branch_name"
        if [ -d "$WORKTREE_PATH" ]; then
            git worktree remove "$WORKTREE_PATH"
        fi
        
        # Deletar branch
        git branch -d "$branch_name"
        print_status "Branch deletada!"
    fi
    
    echo ""
    print_info "Backup mantido em: $BACKUP_BRANCH"
    print_info "Para desfazer o merge: git reset --hard $BACKUP_BRANCH"
else
    print_error "Conflito no merge!"
    echo ""
    print_warning "Resolva os conflitos e depois:"
    echo "  1) git add <arquivos resolvidos>"
    echo "  2) git commit"
    echo ""
    print_info "Ou cancele o merge:"
    echo "  git merge --abort"
fi
```

### Fase 2: Atalhos e Aliases (2 minutos)

#### 2.1 Criar Aliases Git
Adicionar ao `~/.gitconfig`:

```bash
cat >> ~/.gitconfig << 'EOF'

# Odyssey Worktree Aliases
[alias]
    # Criar novo worktree de trabalho
    work = "!bash ~/Documentos/odyssey-mood-tracker/scripts/auto-worktree.sh"
    
    # Limpar worktrees
    wclean = "!bash ~/Documentos/odyssey-mood-tracker/scripts/clean-worktree.sh"
    
    # Merge seguro
    wmerge = "!bash ~/Documentos/odyssey-mood-tracker/scripts/merge-worktree.sh"
    
    # Listar worktrees
    wlist = worktree list
    
    # Status de todos os worktrees
    wstatus = "!git worktree list | awk '{print $1}' | xargs -I {} sh -c 'echo \"=== {} ===\"' && git -C {} status -s"
EOF
```

#### 2.2 Tornar Scripts Executáveis
```bash
cd ~/Documentos/odyssey-mood-tracker
chmod +x scripts/auto-worktree.sh
chmod +x scripts/clean-worktree.sh
chmod +x scripts/merge-worktree.sh
```

### Fase 3: Uso Diário (SUPER FÁCIL!)

#### Fluxo de Trabalho Recomendado

##### 1️⃣ Antes de Começar a Trabalhar
```bash
cd ~/Documentos/odyssey-mood-tracker

# Criar novo ambiente de trabalho
git work

# O script vai:
# - Verificar se você tem mudanças não salvas
# - Criar uma nova branch automática
# - Criar um worktree separado
# - Perguntar se quer abrir no VS Code
```

##### 2️⃣ Trabalhando no Worktree
```bash
# Você estará em: .worktrees/work-20251216-1810/

# Trabalhe normalmente
flutter run
flutter test

# Commite suas mudanças
git add .
git commit -m "Adicionei feature X"

# Teste bastante!
flutter analyze
```

##### 3️⃣ Se Deu Certo - Juntar com Main
```bash
# Voltar para a main
cd ~/Documentos/odyssey-mood-tracker

# Merge seguro (cria backup automático!)
git wmerge

# Escolher a branch que você criou
# O script cuida do resto!
```

##### 4️⃣ Se Deu Errado - Deletar e Recomeçar
```bash
# Limpar worktree problemático
git wclean

# Escolher qual remover
# Sua main continua intocada! 🎉
```

### Fase 4: Comandos Úteis

#### Ver Todos os Worktrees
```bash
git wlist
```

#### Ver Status de Todos
```bash
git wstatus
```

#### Criar Worktree Manual
```bash
# Para feature específica
git worktree add .worktrees/feature-login -b feature-login

# Para hotfix urgente
git worktree add .worktrees/hotfix-crash -b hotfix-crash
```

## 🆘 Cenários Comuns

### Cenário 1: "Quebrei Tudo na Main!"
```bash
# ANTES (sem worktree): 😱 PÂNICO!

# AGORA (com worktree): 😎 Tranquilo!
cd ~/Documentos/odyssey-mood-tracker  # Voltar pra main
git reset --hard HEAD                 # Resetar tudo
# Sua main volta ao estado anterior, mudanças quebradas ficam no worktree
```

### Cenário 2: "Quero Testar Duas Coisas Diferentes"
```bash
# Criar primeiro worktree
cd ~/Documentos/odyssey-mood-tracker
git work  # Nome: feature-a

# Criar segundo worktree
git work  # Nome: feature-b

# Agora você tem:
# - Main (estável)
# - .worktrees/feature-a (teste 1)
# - .worktrees/feature-b (teste 2)

# Pode abrir cada um em uma janela diferente do VS Code!
code .worktrees/feature-a
code .worktrees/feature-b
```

### Cenário 3: "Quero Guardar Meu Progresso Mas Não Está Pronto"
```bash
# No seu worktree
git add .
git commit -m "WIP: trabalho em progresso"

# Deixa lá no worktree, não precisa fazer merge
# A main continua limpa!

# Quando estiver pronto:
cd ~/Documentos/odyssey-mood-tracker
git wmerge
```

### Cenário 4: "Preciso Voltar Pra Main Urgente"
```bash
# Simplesmente volte!
cd ~/Documentos/odyssey-mood-tracker

# Sua main está intocada
# O worktree continua lá quando você quiser voltar
```

## 📊 Estrutura Final

```
odyssey-mood-tracker/                  (main - SEMPRE ESTÁVEL)
│
├── .worktrees/                        (Seus experimentos)
│   ├── work-20251216-1810/           (Testando feature X)
│   ├── fix-bug-login/                (Corrigindo bug)
│   └── experiment-ui/                (Experimentando UI nova)
│
├── scripts/
│   ├── auto-worktree.sh              (Criar worktree)
│   ├── clean-worktree.sh             (Limpar)
│   └── merge-worktree.sh             (Juntar com main)
│
└── lib/                               (Código principal)
```

## 🎓 Comandos de Emergência

### Resetar Tudo (Voltar ao Início)
```bash
cd ~/Documentos/odyssey-mood-tracker

# Limpar TODOS os worktrees
git wclean  # Opção 2 (remover todos)

# Resetar main para último commit
git reset --hard HEAD

# Descartar mudanças não commitadas
git clean -fd
```

### Ver O Que Mudou Antes de Merge
```bash
cd ~/Documentos/odyssey-mood-tracker

# Ver diferenças
git diff main..feature-x

# Ver commits
git log main..feature-x
```

### Recuperar de Backup
```bash
# Se fez merge e se arrependeu
git reset --hard backup-main-20251216-181000

# Listar backups
git branch | grep backup
```

## 🔐 Backup Automático Diário

Criar `scripts/daily-backup.sh`:

```bash
#!/bin/bash
# Backup Diário Automático

PROJECT_ROOT=~/Documentos/odyssey-mood-tracker
BACKUP_DIR=~/Documentos/odyssey-backups
DATE=$(date +%Y%m%d)

cd $PROJECT_ROOT

# Criar backup
git worktree add "$BACKUP_DIR/odyssey-$DATE" -b "backup-$DATE"

echo "✓ Backup criado em: $BACKUP_DIR/odyssey-$DATE"
echo "  Para restaurar: cd $BACKUP_DIR/odyssey-$DATE"
```

Adicionar ao crontab (executar todo dia às 10h):
```bash
crontab -e

# Adicionar linha:
0 10 * * * bash ~/Documentos/odyssey-mood-tracker/scripts/daily-backup.sh
```

## 📱 Integração com VS Code

Criar `.vscode/tasks.json` no projeto:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Criar Worktree",
      "type": "shell",
      "command": "bash scripts/auto-worktree.sh",
      "problemMatcher": []
    },
    {
      "label": "Limpar Worktrees",
      "type": "shell",
      "command": "bash scripts/clean-worktree.sh",
      "problemMatcher": []
    },
    {
      "label": "Merge Worktree",
      "type": "shell",
      "command": "bash scripts/merge-worktree.sh",
      "problemMatcher": []
    }
  ]
}
```

Usar: `Ctrl+Shift+P` → `Tasks: Run Task` → Escolher task

## ✅ Checklist de Implementação

### Setup Inicial
- [ ] Criar pasta `.worktrees`
- [ ] Adicionar `.worktrees/` ao `.gitignore`
- [ ] Criar `scripts/auto-worktree.sh`
- [ ] Criar `scripts/clean-worktree.sh`
- [ ] Criar `scripts/merge-worktree.sh`
- [ ] Tornar scripts executáveis (`chmod +x`)
- [ ] Adicionar aliases ao `~/.gitconfig`

### Teste
- [ ] Testar `git work` (criar worktree)
- [ ] Fazer algumas mudanças no worktree
- [ ] Testar `git wlist` (listar)
- [ ] Testar `git wmerge` (merge)
- [ ] Testar `git wclean` (limpar)

### Opcional
- [ ] Configurar backup diário
- [ ] Adicionar tasks no VS Code
- [ ] Criar atalhos no Kitty

## 🎯 Resumo para Noob (Você!)

1. **Rode uma vez:** Instale os scripts (Fase 1 e 2)
2. **Sempre antes de trabalhar:** `git work`
3. **Trabalhe tranquilo** no worktree criado
4. **Se deu bom:** `git wmerge`
5. **Se deu ruim:** `git wclean` e recomeça

**Resultado:** Nunca mais quebrar a main! 🎉

## 🤝 Ajuda Rápida

```bash
# Estou perdido, onde estou?
git branch --show-current

# Voltar pra main (seguro)
cd ~/Documentos/odyssey-mood-tracker

# Ver todos os locais de trabalho
git wlist

# Listar branches
git branch

# Criar novo lugar pra trabalhar
git work
```

---

**Dica Final:** Imprima este guia ou salve em Favoritos. É seu salva-vidas! 🛟
