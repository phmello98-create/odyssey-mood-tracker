# Sistema de Backup Automático para o Projeto Odyssey

Este sistema realiza backups automáticos do seu código usando Git com commits automáticos.

## Funcionalidades

- Monitora alterações nos arquivos do projeto
- Faz commits automáticos a cada intervalo definido (padrão: 5 minutos)
- Registra logs de todas as operações
- Funciona em segundo plano
- Alerta para alterações não salvas

## Comandos Disponíveis

### Iniciar o sistema de backup automático:
```bash
source /home/agyspc1/Documentos/app com opus 4.5 copia atual/start_auto_backup.sh start
```

### Parar o sistema de backup automático:
```bash
source /home/agyspc1/Documentos/app com opus 4.5 copia atual/start_auto_backup.sh stop
```

### Verificar status do sistema:
```bash
source /home/agyspc1/Documentos/app com opus 4.5 copia atual/start_auto_backup.sh status
```

### Fazer commit imediato:
```bash
source /home/agyspc1/Documentos/app com opus 4.5 copia atual/auto_backup.sh commit
```

### Verificar status do repositório:
```bash
source /home/agyspc1/Documentos/app com opus 4.5 copia atual/auto_backup.sh status
```

## Atalhos Disponíveis

Depois de reiniciar o terminal ou executar `source ~/.zshrc`, você terá os seguintes atalhos:

- `auto_backup_start` - Inicia o sistema de backup automático
- `auto_backup_stop` - Para o sistema de backup automático
- `auto_backup_status` - Verifica o status do sistema
- `auto_commit` - Faz um commit automático imediato
- `check_backup` - Verifica o status do backup automático rapidamente

## Integração com Kitty Terminal

A configuração do Kitty (em kitty_backup_integration.conf) inclui:

- `F1`: Fazer commit automático imediato
- `Ctrl+F1`: Iniciar backup automático em segundo plano
- `Ctrl+F2`: Parar backup automático
- `F2`: Verificar status do backup automático

## Arquivos Importantes

- `auto_backup.sh` - Script principal de backup
- `start_auto_backup.sh` - Script de controle em segundo plano
- `auto_backup.log` - Log das operações de backup
- `.auto_backup_aliases` - Arquivo com aliases de terminal

## Configuração Automática

O sistema já está configurado para iniciar automaticamente quando você abrir seu terminal, graças à inclusão no arquivo ~/.zshrc.

## Personalização

Você pode ajustar o intervalo de backup editando o arquivo `auto_backup.sh` e modificando a variável `BACKUP_INTERVAL` (em segundos).

## Recomendações

- O sistema está configurado para monitorar alterações em arquivos `.dart`, `.yaml`, `.md`, `.txt`, `.sh`, `.py`, `.json`, `.toml`
- O sistema faz backup local somente, mas pode ser facilmente estendido para fazer push para um repositório remoto
- Revise periodicamente os commits automáticos para garantir que tudo está sendo salvo corretamente