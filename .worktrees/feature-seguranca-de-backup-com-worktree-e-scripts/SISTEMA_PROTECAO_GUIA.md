# 🎯 Sistema de Proteção - Guia Rápido

## ✅ Sistema Configurado

Todos os comandos estão prontos para uso:

- `git work` - Criar ambiente seguro
- `git save` - Salvar manualmente
- `git wlist` - Listar ambientes
- `git wmerge` - Juntar com main
- `git wclean` - Deletar ambiente

---

## 🚀 Uso Diário Recomendado

### 1. Começar o Dia

```bash
cd ~/Documentos/odyssey-mood-tracker
git work
cd .worktrees/work-*
```

### 2. Ativar Proteção Automática (Recomendado)

```bash
nohup bash ~/Documentos/odyssey-mood-tracker/scripts/auto-save-watch.sh &
```

**O que faz**: Salva automaticamente a cada 5 minutos

### 3. Trabalhar Normalmente

- Edite arquivos
- Teste features
- Quebre e conserte
- **Sistema salva tudo automaticamente!**

### 4. Finalizar o Dia

**Se deu certo:**

```bash
cd ~/Documentos/odyssey-mood-tracker
git wmerge
```

**Se deu errado:**

```bash
cd ~/Documentos/odyssey-mood-tracker
git wclean
```

---

## 💡 Dicas Importantes

### ✅ Sempre Use Worktrees Para

- Testar novas features
- Fazer refatorações grandes
- Experimentar ideias
- Corrigir bugs complexos

### ⚠️ Benefícios

- **Main sempre segura** - Nunca quebra
- **Backups automáticos** - A cada 5 minutos
- **Desfazer fácil** - Se der errado, só deletar
- **Múltiplos experimentos** - Vários worktrees ao mesmo tempo

### 🔍 Verificar Status

```bash
git wlist                    # Ver todos os worktrees
ps aux | grep auto-save      # Ver se monitor está rodando
tail -f ~/auto_backup.log    # Ver logs do auto-save
```

---

## 🆘 Problemas Comuns

**Monitor não está rodando?**

```bash
nohup bash ~/Documentos/odyssey-mood-tracker/scripts/auto-save-watch.sh &
```

**Esqueci de fazer commit?**

```bash
git save  # Salva manualmente
```

**Worktree travou?**

```bash
git wclean  # Deleta e recria
```

---

## 📚 Documentação Completa

Para mais detalhes, consulte:

- `COMO_USAR_SISTEMA_COMPLETO.txt` - Guia rápido
- `GUIA_WORKTREE_AUTOMATICO.md` - Worktrees detalhado
- `SISTEMA_AUTO_COMMIT_BACKUP.md` - Auto-save completo

---

## 🎉 Pronto para Usar

Agora você pode trabalhar sem medo de perder código ou quebrar a main!
