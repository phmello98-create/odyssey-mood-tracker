# Integração do Sistema de Backup com Kitty Terminal

## Configuração do Kitty

Para usar os atalhos do sistema de backup no Kitty terminal, você pode adicionar as seguintes linhas ao seu arquivo de configuração do Kitty:

```bash
# No seu arquivo ~/.config/kitty/kitty.conf
include /home/agyspc1/Documentos/app com opus 4.5 copia atual/kitty_backup_integration.conf
```

## Atalhos Disponíveis

- `F1`: Fazer commit automático imediato
- `F2`: Mostrar status do sistema de backup
- `Ctrl+F1`: Iniciar o sistema de backup automático em segundo plano
- `Ctrl+F2`: Parar o sistema de backup automático

## Ativar Atalhos Manualmente

Se você quiser ativar os atalhos agora sem reiniciar o terminal:

```bash
# No Kitty terminal
source /home/agyspc1/Documentos/app com opus 4.5 copia atual/.auto_backup_aliases
```

## Verificação de Funcionamento

Para confirmar que tudo está funcionando corretamente:

1. Verifique se o backup automático está rodando: `check_backup`
2. Verifique os últimos commits: `git log --oneline -n 3`
3. Faça um teste de commit manual: `auto_commit`

## Personalização Adicional

O sistema está configurado com um tema visual que ajuda a distinguir quando você está trabalhando no projeto Odyssey. Você pode personalizar as cores no arquivo `kitty_backup_integration.conf` de acordo com sua preferência.