# Roadmap

Curto prazo (próximas sessões)
- Criar smoke/golden tests para fluxo Splash → Auth → Home → mood/diário
- Revisar inicialização de serviços (Firebase, notificações, som, AdMob/IAP) com logs claros
- Sanitizar features não usadas/experimentais em lib/src/features/*

Médio prazo
- Modularizar features grandes mantendo arquivos <500–1000 linhas
- Endurecer persistência local (Hive) e sync opcional (Firebase) com detecção offline
- Melhorar monitoramento de erros (logging estruturado) e métricas de UX

Longo prazo
- Otimizar UI/tema dinâmico e acessibilidade
- Sincronização multi-dispositivo e backup seguro
- Automação de testes em pipelines (CI) com analyze/test/goldens
