
# Odyssey — Mood Tracker

App Flutter (Riverpod, GoRouter, Hive, Firebase, AdMob/IAP, notificações, áudio) para registro de humor, diário e hábitos.

SSOT (ponto único de verdade)
- Planejamento, fases e decisões: docs/ (ROADMAP, PHASE, LOG_SOLO, QUESTOES)
- TODO global: TODO.md
- Testes e qualidade: `flutter analyze` e `flutter test` (inclua goldens/smoke quando adicionados)

Arquitetura de pastas (resumo)
- lib/src/features/*: features modulares (auth, mood_records, diary, notifications, subscription, etc.)
- lib/src/utils/*: serviços centrais (notificações, ciclo de vida, som, tema)
- lib/main.dart: boot de serviços (Firebase, som, notificações, IAP) e MaterialApp

Fluxo de trabalho sugerido (solo)
1) Ler docs/PHASE.md + docs/ROADMAP.md + docs/LOG_SOLO.md
2) Rodar `flutter analyze` e `flutter test` antes de alterar
3) Implementar; evitar atalhos/compat hacks; remover código morto
4) Atualizar LOG_SOLO com decisões e TODO.md com pendências

Links rápidos
- docs/PHASE.md — foco atual
- docs/ROADMAP.md — backlog/planejamento
- docs/LOG_SOLO.md — log de sessões/decisões
- docs/QUESTOES.md — dúvidas em aberto
- TODO.md — tarefas pendentes com referências de arquivo/linha
