#!/bin/bash

# Script de atalhos para desenvolvimento do projeto Odyssey
# Uso: ./odyssey_shortcuts.sh

PROJECT_DIR="/home/agyspc1/Documentos/app com opus 4.5 copia atual"

# Função para mostrar ajuda
show_help() {
    echo "Atalhos para o projeto Odyssey:"
    echo "  status          - Mostra o status do repositório Git"
    echo "  log             - Mostra os últimos 10 commits"
    echo "  diff            - Mostra diferenças não commitadas"
    echo "  build           - Executa flutter build"
    echo "  clean           - Executa flutter clean"
    echo "  analyze         - Executa flutter analyze"
    echo "  test            - Executa os testes do Flutter"
    echo "  run             - Executa o app Flutter"
    echo "  doctor          - Executa flutter doctor"
    echo "  pub-get         - Executa flutter pub get"
    echo "  pub-upgrade     - Executa flutter pub upgrade"
    echo "  deps            - Mostra dependências do projeto"
    echo "  loc             - Conta linhas de código no projeto"
    echo "  sizes           - Mostra tamanho das pastas importantes"
    echo "  backup-status   - Verifica status do backup automático"
    echo "  backup-start    - Inicia backup automático em segundo plano"
    echo "  backup-stop     - Para backup automático"
    echo "  git-stats       - Mostra estatísticas do Git"
    echo "  all-stats       - Mostra todas estatísticas do projeto"
    echo "  help            - Mostra esta mensagem"
}

# Mudar para o diretório do projeto
cd "$PROJECT_DIR" || { echo "Erro: Diretório do projeto não encontrado!"; exit 1; }

# Executar ação baseada no argumento
case "${1:-help}" in
    "help")
        show_help
        ;;
    "status")
        git status
        ;;
    "log")
        git log --oneline -n 10
        ;;
    "diff")
        git diff
        ;;
    "build")
        flutter build
        ;;
    "clean")
        flutter clean
        echo "Executando flutter pub get após limpeza..."
        flutter pub get
        ;;
    "analyze")
        flutter analyze
        ;;
    "test")
        flutter test
        ;;
    "run")
        flutter run
        ;;
    "doctor")
        flutter doctor
        ;;
    "pub-get")
        flutter pub get
        ;;
    "pub-upgrade")
        flutter pub upgrade
        ;;
    "deps")
        flutter pub deps
        ;;
    "loc")
        echo "Contagem de linhas de código:"
        tokei --exclude "build" .
        ;;
    "sizes")
        echo "Tamanhos das pastas principais:"
        du -sh lib/ test/ assets/ android/ ios/ 2>/dev/null || echo "Algumas pastas podem não existir"
        ;;
    "backup-status")
        source "$PROJECT_DIR/start_auto_backup.sh" status
        ;;
    "backup-start")
        source "$PROJECT_DIR/start_auto_backup.sh" start
        ;;
    "backup-stop")
        source "$PROJECT_DIR/start_auto_backup.sh" stop
        ;;
    "git-stats")
        echo "Estatísticas do Git:"
        echo "Total de commits:"
        git rev-list --count HEAD
        echo "Arquivos modificados:"
        git diff --shortstat
        echo "Contribuidores:"
        git shortlog -s -n
        ;;
    "all-stats")
        echo "=== Estatísticas do Projeto Odyssey ==="
        echo ""
        echo "Git:"
        echo "Commits totais: $(git rev-list --count HEAD)"
        echo "Branch atual: $(git branch --show-current)"
        echo "Último commit: $(git log -1 --format='%h - %an, %ar : %s')"
        echo ""
        echo "Código:"
        tokei --exclude "build" . | head -20  # Mostrar apenas as principais estatísticas
        echo ""
        echo "Tamanho do projeto:"
        du -sh . | cut -f1
        echo ""
        echo "Dependências:"
        flutter pub deps | head -20
        ;;
    *)
        echo "Opção inválida: $1"
        echo ""
        show_help
        ;;
esac