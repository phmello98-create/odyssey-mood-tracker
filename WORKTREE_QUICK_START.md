# 🚀 INSTALAÇÃO RÁPIDA - Worktree Automático

## ⚡ Setup em 30 Segundos

```bash
# 1. Ir para o projeto
cd ~/Documentos/odyssey-mood-tracker

# 2. Rodar setup
bash scripts/setup-worktree.sh

# 3. Pronto! 🎉
```

## 📖 Uso Diário

### Antes de Começar a Trabalhar
```bash
cd ~/Documentos/odyssey-mood-tracker
git work
```

### Terminei o Trabalho - Juntar com Main
```bash
cd ~/Documentos/odyssey-mood-tracker
git wmerge
```

### Ver Meus Worktrees
```bash
git wlist
```

### Limpar Worktrees Antigos
```bash
git wclean
```

## 🆘 Socorro Rápido

### Quebrei Tudo!
```bash
# Voltar pra main (está sempre segura!)
cd ~/Documentos/odyssey-mood-tracker
git reset --hard HEAD
```

### Onde Estou?
```bash
git branch --show-current
pwd
```

### Como Volto pra Main?
```bash
cd ~/Documentos/odyssey-mood-tracker
```

## 🎓 Fluxo de Trabalho

```
1. git work              → Criar ambiente seguro
2. cd .worktrees/...     → Ir para o worktree
3. Trabalhar normalmente → Fazer mudanças
4. git add + commit      → Salvar mudanças
5. cd ~/Documentos/...   → Voltar pra main
6. git wmerge            → Juntar mudanças (se deu certo)
   OU
   git wclean            → Deletar (se deu errado)
```

## 💡 Dicas

- ✅ **Sempre** use `git work` antes de trabalhar
- ✅ Teste bastante antes de fazer `git wmerge`
- ✅ A main **sempre** fica segura
- ✅ Pode ter vários worktrees ao mesmo tempo!
- ✅ Cada worktree é independente

## 📚 Documentação Completa

Leia: [GUIA_WORKTREE_AUTOMATICO.md](GUIA_WORKTREE_AUTOMATICO.md)

---

**Feito por:** Claude Code Assistant  
**Para:** Você nunca mais quebrar o código! 🛡️
