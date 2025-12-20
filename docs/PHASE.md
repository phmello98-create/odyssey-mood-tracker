# Fase atual

Objetivo: estabilizar notificações, IAP/AdMob e experiência em desktop/Linux (boot sem travar; degrade sem Firebase onde não suportado).

Critérios de saída
- `flutter analyze` limpo e `flutter test` passando
- Smoke tests para Splash → Auth → Home → criação de mood/diário (quando implementados)
- Log atualizado em docs/LOG_SOLO.md
- TODO.md revisado

Tarefas foco
- Verificar inicialização de serviços no main.dart em plataformas não móveis (fallbacks/logs)
- Garantir handling de notificações (Awesome/Modern) e action handler com ref setado
- Confirmar inicialização AdMob/IAP sob condições de rede/permissão
