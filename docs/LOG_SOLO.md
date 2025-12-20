# Log de sessões (solo)

Formato sugerido
- Data/Hora:
- Tópico/Feature:
- Mudanças feitas:
- Decisões/justificativas:
- Testes rodados (analyze/test/goldens):
- Pendências/TODO(SOLO):

Entradas recentes
- Data/Hora: 2025-12-19 19:43
- Tópico/Feature: SSOT e governança
- Mudanças feitas: criado docs/PHASE.md, docs/ROADMAP.md, docs/LOG_SOLO.md, docs/QUESTOES.md, TODO.md; README atualizado para apontar SSOT.
- Decisões/justificativas: centralizar planejamento em docs/; usar TODO.md + TODO(SOLO) para pendências; manter fluxo analyze/test antes/depois.
- Testes rodados (analyze/test/goldens): não rodados (alteração somente de documentação).
- Pendências/TODO(SOLO): criar smoke/golden tests; revisar inicialização de serviços multi-plataforma; limpar features inativas; preencher TODOs com arquivos/linhas.
- Data/Hora: 2025-12-19 19:52
- Tópico/Feature: Smoke test
- Mudanças feitas: adicionado test/smoke_app_test.dart com overrides de providers para iniciar app até LoginScreen sem serviços pesados; TODO atualizado com status do smoke básico.
- Decisões/justificativas: evitar inicialização de Firebase/Hive/notificações nos testes; desabilitar animação do splash via mock de SharedPreferences para reduzir espera.
- Testes rodados (analyze/test/goldens): não rodados (ambiente local não executado nesta sessão).
- Pendências/TODO(SOLO): expandir smoke para cobrir fluxo até Home/mood; adicionar goldens; revisar inicialização multi-plataforma; limpeza de features inativas.
