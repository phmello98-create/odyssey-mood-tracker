# Ferramentas Úis para o Terminal no Desenvolvimento do Projeto Odyssey

## 1. Gerenciadores de Terminal

### Tmux
- Permite criar sessões persistentes de terminal
- Possibilita dividir janelas e abas dentro do terminal
- Úil para manter o backup automático rodando em uma sessão separada
- Comando útil: `tmux new-session -s odyssey` para criar uma nova sessão para o projeto

### Screen
- Alternativa ao tmux para sessões persistentes

## 2. Ferramentas de Navegação e Busca

### Fzf (Fuzzy Finder)
- Busca poderosa por arquivos, histórico de comandos, branches do git, etc.
- Instalação: `sudo pacman -S fzf`
- Comando útil: `Ctrl+R` para pesquisar no histórico de comandos

### Bat
- Mostra conteúdo de arquivos com sintaxe colorida
- Substituição mais bonita para `cat`
- Instalação: `sudo pacman -S bat`

### Exa
- Substituição moderna para `ls` com muito mais informações
- Instalação: `sudo pacman -S exa`
- Comando útil: `alias ls='exa --icons'`

### Ranger
- Gerenciador de arquivos baseado em terminal
- Navegação hierárquica com pré-visualização
- Instalação: `sudo pacman -S ranger`

## 3. Monitoramento e Análise

### HTOP
- Monitor de processos visual e interativo
- Melhor que o tradicional `top`
- Instalação: `sudo pacman -S htop`

### Glances
- Monitoramento sistema abrangente
- Instalação: `sudo pacman -S glances`

### Bandwhich
- Monitoramento de uso de banda de rede por processo
- Instalação: `sudo pacman -S bandwhich`

## 4. Ferramentas para Desenvolvimento Flutter/Dart

### DVM (Dart Version Manager)
- Gerencia múltiplas versões do Dart SDK
- Instalação: `curl -fsSL https://github.com/bluefireteam/dvm/releases/download/v1.8.1/installer.sh | sh`

### FVM (Flutter Version Manager)
- Gerencia múltiplas versões do Flutter SDK
- Úil para testar diferentes versões do Flutter
- Instalação: `dart pub global activate fvm`

### FLOCC
- Contador de linhas de código para múltiplas linguagens
- Úil para medir progresso do projeto
- Instalação: `sudo pacman -S tokei` ou `cargo install tokei`
- Comando: `tokei` para analisar o projeto atual

## 5. Ferramentas de Produtoividade

### Taskwarrior
- Sistema de gerenciamento de tarefas baseado em terminal
- Úil para gerenciar tarefas do projeto Odyssey
- Instalação: `sudo pacman -S task`

### Tldr
- Versões simplificadas dos manuais (man pages)
- Mais legíveis que os manuais tradicionais
- Instalação: `sudo pacman -S tldr`
- Uso: `tldr git` ou `tldr flutter`

### Httpie
- Cliente HTTP mais intuitivo que curl
- Úil para testes de APIs
- Instalação: `sudo pacman -S httpie`

## 6. Extensões de Comando Úeis

### Git Extras
- Conjunto de comandos Git adicionais
- Instalação: `sudo pacman -S git-extras`
- Comandos úteis: `git summary`, `git effort`, `git changelog`

### Git-delta
- Visualizador de diffs do Git mais bonito
- Instalação: `sudo pacman -S git-delta`
- Configuração: `git config --global pager.diff "delta"` e `git config --global pager.log "delta"`

## 7. Personalização do Terminal

### Oh My Zsh (se estiver usando zsh)
- Framework para gerenciar configurações do Zsh
- Temas e plugins prontos
- Instalação: `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`

### Spaceship ZSH
- Prompt Zsh minimalista e informativo
- Mostra status do Git, versão do Dart/Flutter, etc.
- Instalação via Oh My Zsh

### Starship
- Prompt de terminal universal personalizável
- Funciona com bash, zsh, fish, etc.
- Instalação: `curl -sS https://starship.rs/install.sh | sh`
- Adicionar a `~/.zshrc` ou `~/.bashrc`: `eval "$(starship init zsh)"` ou `eval "$(starship init bash)"`

## 8. Ferramentas de Edição no Terminal

### Neovim
- Editor de texto poderoso para programação
- Instalação: `sudo pacman -S neovim`
- Pode substituir o VS Code para edição rápida

### Lazygit
- Interface visual para Git no terminal
- Instalação: `sudo pacman -S lazygit`
- Comando: `lazygit`

## 9. Monitoramento do Projeto

### Wego
- Previsão do tempo no terminal (útil para dizer "tempo afetando o humor")
- Instalação: `sudo pacman -S wego`

### Bottom (btm)
- Monitor de sistema moderno e bonito
- Alternativa ao htop
- Instalação: `sudo pacman -S bottom`

## 10. Scripts Personalizados para o Projeto Odyssey

Aqui estão algumas ideias de scripts que você pode criar para automatizar tarefas comuns:

### Contar arquivos Dart no projeto:
```bash
alias count_dart='find . -name "*.dart" | wc -l'
```

### Verificar tamanho total do projeto:
```bash
alias size_project='du -sh .'
```

### Verificar número de commits no projeto:
```bash
alias count_commits='git rev-list --count HEAD'
```

### Verificar as últimas modificações:
```bash
alias recent_changes='git log --oneline --since="7 days ago"'
```

### Checar tamanho da pasta de build:
```bash
alias size_build='du -sh build/ 2>/dev/null || echo "Build folder does not exist"'
```

Estas ferramentas aumentarão significativamente sua produtividade no desenvolvimento do projeto Odyssey diretamente pelo terminal!