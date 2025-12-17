# Plano Técnico Completo: Notificações Locais e Timer Persistente

**Data:** 2025-12-11  
**Versão:** 1.0  
**Analista:** IA Expert Flutter/Dart & Android/iOS

---

## 📋 Executive Summary

Este documento apresenta o plano técnico detalhado para implementação/melhoria de notificações locais confiáveis e timers persistentes no app Odyssey, focando em:

1. **Local-first architecture**: Notificações locais sem dependência de FCM para operações críticas
2. **Android**: Foreground Service robusto para timers + persistência após reboot
3. **iOS**: Agendamento local de notificações + recuperação de estado ao reabrir
4. **FCM**: Apenas como fallback opcional para sync multi-device ou mensagens server-driven

**Status atual**: O app já possui base sólida implementada:
- ✅ NotificationService com Awesome Notifications
- ✅ ForegroundTimerService (Android nativo) com persistência
- ✅ BootReceiver funcional
- ✅ Firebase/FCM configurado (opcional)
- ⚠️ iOS sem implementação específica para timer em background
- ⚠️ Faltam testes em devices com otimização agressiva de bateria

---

## 🎯 Objetivos e Requisitos

### Meta Principal
Implementar notificações locais e timers (Pomodoro/Time Tracker) confiáveis que funcionem mesmo com o app em background, killed ou após reboot do dispositivo.

### Requisitos Funcionais

#### R1. Lembretes Diários Recorrentes
- Lembretes de humor (mood reminder) configuráveis
- Lembretes de tarefas pontuais com notificação
- Repetição por timezone com suporte a DST
- Ações rápidas na notificação (registrar humor, concluir tarefa)

#### R2. Timer/Pomodoro Persistente
- Contagem confiável mesmo com app em background ou killed
- Notificação persistente com ações (pausar/resumir/parar)
- Notificação de conclusão ao término do período
- Restauração após reboot (Android)
- Sincronização de estado ao reabrir app (iOS)

#### R3. Notificações de Gamificação
- Level up, conquistas, streaks em risco
- Insights diários personalizados
- Re-engajamento para usuários inativos

#### R4. Permissões e UX
- Solicitação clara de permissões com rationale
- Instruções para whitelist em devices com otimização de bateria
- Configurações de notificação no app

---

## 🏗️ Arquitetura Proposta

### Visão Geral

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App Layer                        │
│  ┌────────────────┐  ┌──────────────────┐  ┌──────────────┐│
│  │ NotificationSvc│  │ ForegroundSvc    │  │ FirebaseSvc  ││
│  │ (Awesome Notif)│  │ (MethodChannel)  │  │ (FCM Bridge) ││
│  └────────┬───────┘  └────────┬─────────┘  └──────┬───────┘│
└───────────┼──────────────────┼────────────────────┼─────────┘
            │                  │                    │
            ▼                  ▼                    ▼
   ┌─────────────────┐ ┌──────────────────┐ ┌──────────────┐
   │ Awesome Notif   │ │ Native Services  │ │ FCM/Analytics│
   │ (Local Notif)   │ │ (Foreground Svc) │ │ (Optional)   │
   └─────────────────┘ └──────────────────┘ └──────────────┘
         Android              Android            Both
           iOS            (SharedPrefs)
```

### Decisões Técnicas

#### 1. Local-First Strategy
- **Notificações locais** (Awesome Notifications) para todos os lembretes baseados em horário
- **Foreground Service Android** para timer com notificação nativa e persistência
- **SharedPreferences** (Android) / **UserDefaults** (iOS) para estado do timer
- **FCM** apenas para casos específicos:
  - Sincronização entre dispositivos
  - Notificações server-driven (campanhas, admin)
  - Re-engajamento de usuários inativos

#### 2. Android: Foreground Service + AlarmManager
- `ForegroundTimerService.kt` mantém timer rodando em foreground
- Notificação persistente não-dismissible com ações
- `BootReceiver.kt` restaura timer após reboot
- Estado persistido em SharedPreferences a cada tick
- Flags corretas: `FOREGROUND_SERVICE_SPECIAL_USE`, `PendingIntent.FLAG_IMMUTABLE`

#### 3. iOS: Local Notifications + State Recovery
- **Limitação aceita**: iOS suspende execução em background
- **Solução**:
  - Ao iniciar timer: agendar `UNNotificationRequest` para horário de término
  - Ao pausar: cancelar notificação agendada
  - Ao retomar: recalcular e reagendar notificação
  - Ao reabrir app: recuperar estado de UserDefaults e atualizar UI
- **UNNotificationAction** para ações na notificação
- Não há contagem em tempo real no background

#### 4. Comunicação Flutter ↔ Native
- **MethodChannel**: `com.example.odyssey/foreground_service`
- **Métodos**:
  - `startTimer(taskName, durationSeconds?, isPomodoro)`
  - `pauseTimer()`
  - `resumeTimer()`
  - `stopTimer()`
  - `getTimerState()` → retorna estado atual
  - `updateNotification(taskName, elapsed, remaining?, isPaused)`
- **Callbacks Flutter → Native**:
  - `onTimerTick(elapsedSeconds)`
  - `onTimerPaused()`, `onTimerResumed()`, `onTimerStopped()`
  - `onTimerCompleted(elapsedSeconds)`

#### 5. Persistência Cross-Platform
- **Android**: SharedPreferences em `ForegroundTimerService`
  - Keys: `is_running`, `is_paused`, `task_name`, `elapsed_seconds`, `start_time`, `duration_seconds`, `is_pomodoro`
- **iOS**: UserDefaults
  - Same keys para compatibilidade
  - Estado salvo ao entrar em background (AppDelegate lifecycle)
- **Hive** para configurações do usuário (reminder settings, preferences)

---

## 📦 Análise da Implementação Atual

### ✅ Componentes Funcionais

#### NotificationService.dart
**Localização**: `lib/src/utils/services/notification_service.dart`

**Status**: ✅ Bem implementado

**Funcionalidades**:
- Channels configurados corretamente (pomodoro, reminders, insights, gamification, timer)
- Métodos de scheduling: `scheduleDailyMoodReminder`, `scheduleStreakReminder`
- Timer notifications: `showTimerRunningNotification`, `updateTimerNotification`, `cancelTimerNotification`
- Remote notifications: `showRemoteNotification` (FCM bridge)
- Action handlers: `onActionReceivedMethod` com callbacks para `PAUSE_TIMER`, `RESUME_TIMER`, `STOP_TIMER`

**Melhorias sugeridas**:
1. Consolidar IDs de notificação em constantes centralizadas para evitar colisões
2. Adicionar método `scheduleTaskReminder(DateTime when, String taskId, String title)` para lembretes pontuais
3. Implementar cancel por ID mais granular (ex: cancelar todos os lembretes de tarefas)
4. Adicionar logs estruturados para debug de notificações não exibidas

#### ForegroundTimerService.kt
**Localização**: `android/app/src/main/kotlin/com/example/odyssey/ForegroundTimerService.kt`

**Status**: ✅ Bem implementado

**Funcionalidades**:
- Service em foreground com notificação persistente
- Timer loop em Handler com tick a cada 1 segundo
- Persistência em SharedPreferences
- Ações via PendingIntent (pause/resume/stop)
- Suporte a Pomodoro com countdown
- Method callbacks para Flutter

**Melhorias sugeridas**:
1. Validar flags de PendingIntent para Android 12+ (já usando FLAG_IMMUTABLE ✅)
2. Adicionar `WakeLock` parcial para garantir ticks em Doze mode (opcional, pode drenar bateria)
3. Implementar recuperação de erro se `startForeground()` falhar
4. Adicionar telemetria: quantos timers completados, média de duração, taxa de cancelamento

#### ForegroundService.dart
**Localização**: `lib/src/utils/services/foreground_service.dart`

**Status**: ✅ Funcional

**Funcionalidades**:
- MethodChannel bridge bem estruturado
- Callbacks assíncronos com StreamController
- Estado local sincronizado (_isRunning, _isPaused, _elapsed)

**Melhorias sugeridas**:
1. Implementar retry logic em caso de erro de comunicação
2. Adicionar timeout para operações (startTimer, pauseTimer) para evitar freeze
3. Sincronizar estado ao inicializar app (chamar `getTimerState()` no init)

#### BootReceiver.kt
**Localização**: `android/app/src/main/kotlin/com/example/odyssey/BootReceiver.kt`

**Status**: ✅ Funcional

**Funcionalidades**:
- Detecta BOOT_COMPLETED e QUICKBOOT_POWERON
- Restaura timer se estava rodando antes do reboot
- Reaplica estado de pausa após delay

**Melhorias sugeridas**:
1. Adicionar logs para telemetria (quantos reboots com timer restaurado)
2. Validar se permissões estão ativas antes de tentar restaurar
3. Implementar exponential backoff se restauração falhar

#### FirebaseService.dart
**Localização**: `lib/src/utils/services/firebase_service.dart`

**Status**: ✅ Completo e moderno

**Funcionalidades**:
- FCM com background handler
- Analytics e Remote Config
- Topics subscription
- Token management e refresh

**Melhorias sugeridas**:
1. Adicionar endpoint para enviar token para backend (se houver)
2. Implementar estratégia de fallback se FCM não estiver disponível
3. Documentar casos de uso de FCM vs notificações locais

### ⚠️ Componentes a Implementar/Melhorar

#### iOS Timer Support
**Status**: ❌ Não implementado

**Necessário**:
1. AppDelegate listener para `applicationWillResignActive` e `applicationDidEnterBackground`
2. Salvar estado do timer em UserDefaults ao entrar em background
3. Agendar `UNNotificationRequest` para horário de término (calcular remaining time)
4. Cancelar notificação ao pausar/parar timer
5. Recuperar estado ao reabrir app (`applicationWillEnterForeground`)
6. Implementar `UNUserNotificationCenterDelegate` para handle ações de notificação

#### Testes em Devices Reais
**Status**: ⚠️ Não documentado

**Necessário**:
- Matriz de testes em devices com otimização de bateria (Xiaomi, Huawei, Samsung)
- Validar comportamento após reboot
- Testar kill do app pelo sistema em low memory
- Validar permissões e rationale UX

#### Instruções de Whitelist
**Status**: ❌ Não implementado

**Necessário**:
- UI para detectar OEM (Xiaomi, Huawei, etc.) e mostrar instruções específicas
- Links para configurações de otimização de bateria
- Explicação clara do por que é necessário

---

## 📝 Plano de Implementação

### Priorização: MoSCoW

- **Must Have (MVP)**: Essencial para launch
- **Should Have (V1.1)**: Importante mas pode ser feito em iteração seguinte
- **Could Have (V1.2+)**: Nice-to-have, baixa prioridade
- **Won't Have**: Out of scope

---

## 🎫 TICKETS DETALHADOS

### 🔴 MVP - Must Have

---

#### **T1: Consolidar e Melhorar NotificationService**
**Prioridade**: MUST HAVE  
**Estimativa**: 3-5 horas  
**Assignee**: Flutter Developer

**Contexto**:
O `NotificationService` está funcional mas precisa de refatoração para evitar colisões de IDs, adicionar métodos granulares e melhorar observabilidade.

**Tarefas**:
1. ✅ Criar enum `NotificationId` com todos os IDs centralizados
2. ✅ Implementar `scheduleTaskReminder(DateTime when, String taskId, String title, String? body)`
3. ✅ Implementar `cancelTaskReminder(String taskId)`
4. ✅ Implementar `cancelAllTaskReminders()`
5. ✅ Adicionar logs estruturados em todos os métodos públicos
6. ✅ Adicionar método `getScheduledNotifications()` para debug
7. ✅ Validar que todos os channels têm descrições claras para o usuário
8. ✅ Escrever unit tests para métodos de scheduling

**Critérios de Aceitação**:
- [ ] Nenhuma colisão de IDs entre notificações de tipos diferentes
- [ ] Possível agendar lembrete para tarefa específica com horário customizado
- [ ] Possível cancelar lembrete individual de tarefa por ID
- [ ] Logs em todos os métodos públicos com timestamp e parâmetros
- [ ] Tests com cobertura mínima de 80%
- [ ] Documentação atualizada com exemplos de uso

**Testes**:
1. Agendar 3 lembretes de tarefas diferentes → verificar IDs únicos
2. Cancelar lembrete específico → verificar que outros permanecem
3. Verificar logs após agendamento → confirmar formato estruturado
4. Rodar tests → 100% pass

**Riscos**:
- Mudança de IDs pode afetar notificações já agendadas → Mitigação: migração de IDs antigos
- Awesome Notifications tem limitação de IDs únicos → Mitigação: usar range de IDs por tipo

---

#### **T2: Validar e Estabilizar ForegroundTimerService (Android)**
**Prioridade**: MUST HAVE  
**Estimativa**: 5-8 horas  
**Assignee**: Android Developer

**Contexto**:
O serviço está funcional mas precisa de validações adicionais para Android 12+, error handling robusto e testes em cenários adversos.

**Tarefas**:
1. ✅ Validar flags de `PendingIntent` para Android 12+ (TARGET_SDK_VERSION 31+)
2. ✅ Implementar error handling em `startForeground()` com fallback
3. ✅ Adicionar logs estruturados com tags e níveis
4. ✅ Implementar telemetria básica (timer started/completed/cancelled)
5. ✅ Testar em Android 10, 11, 12, 13, 14
6. ✅ Validar comportamento em Doze mode e App Standby
7. ✅ Adicionar comentários de documentação em métodos públicos
8. ✅ Criar script de teste manual (checklist)

**Critérios de Aceitação**:
- [ ] Timer funciona em Android 10-14 sem crashes
- [ ] Notificação persistente não é dismissible pelo usuário
- [ ] Ações (pause/resume/stop) funcionam com app killed
- [ ] Timer continua rodando após entrar em Doze mode (com limitações aceitas)
- [ ] Logs estruturados em todos os pontos críticos
- [ ] Zero crashes em 100 inicializações de timer

**Testes**:
1. **Foreground**: Iniciar timer → verificar notificação → pausar → verificar estado
2. **Background**: Iniciar timer → minimizar app 10 min → verificar contagem
3. **Killed**: Iniciar timer → force stop app → verificar notificação persiste e contagem continua
4. **Reboot**: Iniciar timer → reboot device → verificar restauração via BootReceiver
5. **Doze**: Iniciar timer → forçar Doze mode → aguardar 30 min → verificar contagem (aceitar delay de alguns segundos)
6. **Low memory**: Iniciar timer → abrir 10 apps pesados → verificar se timer persiste

**Riscos**:
- OEMs podem matar service mesmo em foreground → Mitigação: documentar limitações + UX para whitelist
- Doze mode pode atrasar ticks → Mitigação: aceitar imprecisão de alguns segundos, documentar

---

#### **T3: Implementar Timer Support para iOS**
**Prioridade**: MUST HAVE  
**Estimativa**: 8-13 horas  
**Assignee**: iOS Developer + Flutter Developer

**Contexto**:
iOS não suporta foreground services como Android. A solução é agendar notificações locais para o horário de término do timer e recuperar estado ao reabrir o app.

**Tarefas**:
1. ✅ Implementar extensão de `AppDelegate` para lifecycle events
   - `applicationWillResignActive` → salvar estado
   - `applicationDidEnterBackground` → agendar notificação
   - `applicationWillEnterForeground` → recuperar estado
2. ✅ Implementar persistência em `UserDefaults`:
   - Keys: `timer_is_running`, `timer_task_name`, `timer_start_time`, `timer_duration`, `timer_is_pomodoro`
3. ✅ Implementar agendamento de `UNNotificationRequest` ao iniciar timer
   - Calcular tempo restante
   - Criar notification content com ações
4. ✅ Implementar cancelamento de notificação ao pausar/parar timer
5. ✅ Implementar `UNUserNotificationCenterDelegate`:
   - `userNotificationCenter(_:didReceive:withCompletionHandler:)` para ações
   - Handle ações: START_BREAK, START_FOCUS
6. ✅ Adicionar MethodChannel para iOS similar ao Android
7. ✅ Testar em simulador iOS 15, 16, 17 e device real
8. ✅ Documentar limitações (não há contagem em tempo real no background)

**Critérios de Aceitação**:
- [ ] Timer iniciado → app em background → notificação exibida no horário correto
- [ ] Timer pausado → notificação agendada é cancelada
- [ ] Timer retomado → notificação reagendada com tempo restante correto
- [ ] App reaberto após 10 min em background → estado sincronizado (tempo decorrido correto)
- [ ] Notificação de conclusão com ações → ações funcionam mesmo com app killed
- [ ] Zero crashes em 50 ciclos de timer (start → background → foreground → stop)

**Testes**:
1. **Basic flow**: Iniciar timer 5 min → background → aguardar → notificação exibida aos 5 min
2. **Pause/Resume**: Iniciar → pausar aos 2 min → background → aguardar 10 min → foreground → verificar tempo pausado em 2 min
3. **App killed**: Iniciar timer 3 min → kill app → aguardar → notificação exibida aos 3 min
4. **State recovery**: Iniciar timer → background 2 min → foreground → UI mostra tempo correto
5. **Actions**: Timer completo → tap "Iniciar Pausa" na notificação → app abre na tela de pausa

**Riscos**:
- iOS pode atrasar notificações em low power mode → Mitigação: usar `UNNotificationTrigger` com `interruptionLevel.timeSensitive`
- State recovery pode ter drift de alguns segundos → Mitigação: aceitar imprecisão de até 5 segundos, documentar
- Actions podem não funcionar com app totalmente killed → Mitigação: abrir app ao invés de action direta

**Arquivos a criar/modificar**:
- `ios/Runner/AppDelegate.swift` (modificar)
- `ios/Runner/TimerStateManager.swift` (criar)
- `lib/src/utils/services/foreground_service.dart` (adicionar suporte iOS)

---

#### **T4: Implementar Testes Manuais e Documentação de QA**
**Prioridade**: MUST HAVE  
**Estimativa**: 3-5 horas  
**Assignee**: QA + Tech Writer

**Contexto**:
Criar checklist de QA para validar comportamento em diferentes devices e cenários.

**Tarefas**:
1. ✅ Criar documento `QA_NOTIFICATION_CHECKLIST.md`
2. ✅ Listar devices para teste:
   - Android: Pixel (stock), Samsung, Xiaomi, Huawei
   - iOS: iPhone 12+, iOS 15, 16, 17
3. ✅ Criar matriz de testes por feature:
   - Mood reminder daily
   - Task reminder pontual
   - Timer pomodoro
   - Timer livre (sem duração)
   - Ações na notificação
   - Reboot (Android)
   - Background/foreground transitions
4. ✅ Documentar procedimento de teste passo-a-passo
5. ✅ Criar template de bug report
6. ✅ Definir critérios de pass/fail

**Critérios de Aceitação**:
- [ ] Documento com 100+ casos de teste
- [ ] Matriz device x feature preenchida
- [ ] Procedimentos claros o suficiente para QA executar sem dev
- [ ] Template de bug report com campos obrigatórios

**Entregável**: Documento `QA_NOTIFICATION_CHECKLIST.md`

---

#### **T5: Implementar UX para Solicitação de Permissões**
**Prioridade**: MUST HAVE  
**Estimativa**: 5-8 horas  
**Assignee**: Flutter Developer + UX Designer

**Contexto**:
Solicitar permissões com rationale claro e friendly UX, incluindo whitelist para otimização de bateria.

**Tarefas**:
1. ✅ Criar `PermissionRationaleDialog`:
   - Título: "Por que precisamos de permissões?"
   - Explicação clara: notificações de lembretes e timer
   - Botão: "Permitir notificações"
2. ✅ Criar `BatteryOptimizationDialog` (Android only):
   - Detectar OEM (Xiaomi, Huawei, Samsung, etc.)
   - Mostrar instruções específicas
   - Botão: "Abrir configurações"
3. ✅ Implementar screen `NotificationSettingsScreen`:
   - Toggle: Lembretes de humor (on/off)
   - TimePicker: Horário do lembrete
   - Toggle: Alertas de streak
   - Toggle: Notificações de Pomodoro
   - Botão: "Testar notificação"
4. ✅ Adicionar lógica de primeiro uso:
   - Mostrar rationale dialog na primeira vez
   - Salvar escolha do usuário em Hive
5. ✅ Implementar método `checkPermissionsStatus()` que retorna enum:
   - `granted`, `denied`, `permanentlyDenied`, `needsBatteryWhitelist`
6. ✅ Adicionar strings localizadas (pt_BR)

**Critérios de Aceitação**:
- [ ] Rationale dialog exibido apenas na primeira vez
- [ ] Usuário pode habilitar/desabilitar cada tipo de notificação
- [ ] Botão "Testar notificação" mostra notificação de exemplo
- [ ] Battery dialog mostrado apenas em OEMs conhecidos
- [ ] Instruções específicas por OEM (Xiaomi, Huawei, Samsung)
- [ ] Estado de permissões salvo e sincronizado

**Testes**:
1. Primeira abertura → rationale dialog exibido → permitir → não exibir novamente
2. Xiaomi device → iniciar timer → battery dialog exibido com instruções Xiaomi
3. Settings screen → toggle mood reminder off → verificar que daily reminder é cancelado
4. Settings screen → botão "Testar" → notificação de teste exibida

**Arquivos a criar**:
- `lib/src/features/settings/presentation/notification_settings_screen.dart`
- `lib/src/features/settings/presentation/widgets/permission_rationale_dialog.dart`
- `lib/src/features/settings/presentation/widgets/battery_optimization_dialog.dart`
- `lib/src/utils/helpers/permission_helper.dart`

---

### 🟡 Should Have - V1.1

---

#### **T6: Implementar Sincronização de Estado via FCM (opcional)**
**Prioridade**: SHOULD HAVE  
**Estimativa**: 8-13 horas  
**Assignee**: Backend + Flutter Developer

**Contexto**:
Se usuário tiver múltiplos dispositivos, permitir sincronizar estado do timer e lembretes via servidor.

**Tarefas**:
1. ✅ Criar backend endpoint: `POST /api/timer/sync`
   - Payload: `{ userId, timerState: {...} }`
   - Response: `{ syncedAt, conflicts: [] }`
2. ✅ Implementar lógica de conflict resolution:
   - Last-write-wins baseado em timestamp
   - Notificar usuário de conflitos
3. ✅ Adicionar no `ForegroundService.dart`:
   - Método `syncTimerState()` chamado ao parar timer
   - Listener para FCM data message `timer_sync`
4. ✅ Implementar Cloud Function para enviar push quando timer sincronizado:
   - Trigger: Firestore `timers/{userId}`
   - Action: Enviar FCM para outros devices do mesmo user
5. ✅ Testar em 2 devices do mesmo usuário

**Critérios de Aceitação**:
- [ ] Timer iniciado no device A → device B recebe notificação de sincronização
- [ ] Timer parado no device A → estado sincronizado para device B em < 5 segundos
- [ ] Conflitos resolvidos automaticamente (last-write-wins)
- [ ] Zero perda de dados em sync

**Out of Scope**: Este ticket é opcional para MVP.

---

#### **T7: Implementar Analytics de Notificações**
**Prioridade**: SHOULD HAVE  
**Estimativa**: 3-5 horas  
**Assignee**: Flutter Developer

**Contexto**:
Rastrear eventos de notificações para entender engagement e problemas.

**Tarefas**:
1. ✅ Adicionar tracking em `NotificationService`:
   - `notification_scheduled` (type, id)
   - `notification_displayed` (type, id)
   - `notification_action_tapped` (type, action)
   - `notification_dismissed` (type, id)
2. ✅ Adicionar tracking em `FirebaseService`:
   - `fcm_notification_received` (type)
   - `fcm_notification_opened` (type, action)
3. ✅ Criar dashboard no Firebase Analytics
4. ✅ Documentar eventos em `ANALYTICS.md`

**Critérios de Aceitação**:
- [ ] Todos os eventos trackados no Firebase Analytics
- [ ] Dashboard mostrando: Taxa de abertura de notificações, ações mais usadas, tipos mais engajados
- [ ] Documentação completa de eventos

---

#### **T8: Implementar Smart Notifications com Remote Config**
**Prioridade**: SHOULD HAVE  
**Estimativa**: 5-8 horas  
**Assignee**: Flutter Developer + Product

**Contexto**:
Usar Remote Config para A/B test de mensagens e timing de notificações.

**Tarefas**:
1. ✅ Criar variantes de mensagens no Remote Config:
   - `mood_reminder_variant_a`: "🎭 Como você está?"
   - `mood_reminder_variant_b`: "😊 Registre seu humor!"
2. ✅ Implementar lógica no `NotificationService` para buscar variante
3. ✅ Adicionar configurações de timing:
   - `optimal_reminder_hour`: 20 (default)
   - `streak_alert_enabled`: true
4. ✅ Implementar A/B test tracking:
   - `ab_test_group`: "control" | "variant_a" | "variant_b"
   - Track conversão (usuário registrou humor após notificação)

**Critérios de Aceitação**:
- [ ] Mensagens carregadas do Remote Config
- [ ] A/B test distribuído 50/50
- [ ] Taxa de conversão trackada por variante
- [ ] Product pode alterar mensagens sem deploy

---

### 🟢 Could Have - V1.2+

---

#### **T9: Implementar Multiple Timers Simultâneos**
**Prioridade**: COULD HAVE  
**Estimativa**: 13-21 horas  
**Assignee**: Flutter + Android + iOS Developer

**Contexto**:
Permitir rodar múltiplos timers ao mesmo tempo (ex: timer de foco + timer de pausa do café).

**Tarefas**:
1. Refatorar `ForegroundTimerService` para suportar múltiplas instâncias
2. Implementar gerenciamento de múltiplas notificações
3. UI para listar timers ativos
4. Testes com 3+ timers simultâneos

**Riscos**:
- Complexidade aumenta significativamente
- UX pode ser confusa
- Battery drain com múltiplos timers

**Recomendação**: Validar com usuários primeiro.

---

#### **T10: Implementar Notificações de Re-engajamento Inteligentes**
**Prioridade**: COULD HAVE  
**Estimativa**: 5-8 horas  
**Assignee**: Flutter Developer + Data Analyst

**Contexto**:
Enviar notificações personalizadas para re-engajar usuários inativos.

**Tarefas**:
1. Criar Cloud Function scheduled (daily):
   - Query users inativos (last login > 7 days)
   - Segmentar por engagement histórico
   - Enviar FCM personalizada
2. Criar variantes de mensagem por segmento:
   - Power users: "Sentimos sua falta, [name]! Seu streak era de X dias."
   - Casual users: "😊 Que tal registrar como você está hoje?"
3. Implementar opt-out de re-engagement
4. Track taxa de retorno

**Critérios de Aceitação**:
- [ ] Usuários inativos 7+ dias recebem notificação
- [ ] Mensagem personalizada por segmento
- [ ] Opt-out funcional
- [ ] Taxa de retorno > 10%

---

## 📊 Matriz de Testes

### Devices para Teste

| Categoria | Device | OS Version | Priority |
|-----------|--------|------------|----------|
| Android Stock | Pixel 6 | Android 14 | P0 |
| Android Samsung | Galaxy S21 | Android 13 | P0 |
| Android Xiaomi | Redmi Note 11 | Android 12 (MIUI 13) | P0 |
| Android Huawei | P40 | Android 10 (EMUI 11) | P1 |
| iOS | iPhone 13 | iOS 17 | P0 |
| iOS | iPhone 12 | iOS 16 | P1 |
| iOS | iPhone 11 | iOS 15 | P2 |

### Features x Devices

| Feature | Pixel | Samsung | Xiaomi | Huawei | iPhone 13 | iPhone 12 |
|---------|-------|---------|--------|--------|-----------|-----------|
| Daily Mood Reminder | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ✅ |
| Task Reminder | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ✅ |
| Timer Foreground | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Timer Background | ✅ | ✅ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Timer Killed | ✅ | ✅ | ⚠️ | ❌ | ❌ | ❌ |
| Timer Reboot | ✅ | ✅ | ⚠️ | ❌ | N/A | N/A |
| Actions in Notification | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| FCM Remote | ✅ | ✅ | ⚠️ | ❌ | ✅ | ✅ |

**Legenda**:
- ✅ Funciona conforme esperado
- ⚠️ Funciona com limitações (requer whitelist de bateria ou configurações)
- ❌ Não funciona (limitação do OS/OEM)
- N/A Não aplicável

### Casos de Teste Críticos

#### TC1: Timer Persistente - Happy Path
**Steps**:
1. Abrir app → navegar para timer
2. Iniciar timer (25 min Pomodoro) para tarefa "Estudar Flutter"
3. Verificar notificação persistente exibida
4. Minimizar app
5. Aguardar 10 minutos
6. Verificar notificação ainda ativa
7. Abrir app → verificar timer em 10:00 elapsed
8. Aguardar mais 15 minutos em background
9. Verificar notificação de conclusão exibida
10. Tap na notificação → app abre

**Expected**:
- Timer roda continuamente em background
- Notificação atualizada a cada segundo (Android) ou minuto (iOS)
- Notificação de conclusão exibida no tempo correto (±5s)
- App abre ao tap na notificação

**Priority**: P0

---

#### TC2: Timer Persistente - App Killed
**Steps**:
1. Iniciar timer (10 min)
2. Verificar notificação persistente
3. Force stop app (Settings → Apps → Odyssey → Force Stop)
4. Aguardar 5 minutos
5. Verificar notificação ainda ativa (Android only)
6. Aguardar mais 5 minutos
7. Verificar notificação de conclusão exibida
8. Tap na notificação → app abre

**Expected**:
- **Android**: Notificação persiste após force stop; timer continua; notificação de conclusão exibida
- **iOS**: Notificação de conclusão exibida (sem notificação persistente durante)

**Priority**: P0

---

#### TC3: Timer Reboot (Android only)
**Steps**:
1. Iniciar timer (30 min)
2. Aguardar 5 minutos
3. Reboot device
4. Aguardar device ligar
5. Verificar notificação restaurada com tempo correto (≈ 5 min elapsed)
6. Aguardar mais 25 minutos
7. Verificar notificação de conclusão

**Expected**:
- BootReceiver detecta reboot
- Timer restaurado com estado correto
- Notificação persistente exibida logo após boot
- Timer completa no horário correto (±10s de drift aceito)

**Priority**: P0 (Android only)

---

#### TC4: Ações na Notificação - Pause/Resume
**Steps**:
1. Iniciar timer
2. Tap "Pausar" na notificação
3. Verificar timer pausado (notificação mostra "⏸️ Pausado")
4. Aguardar 2 minutos
5. Abrir app → verificar tempo não aumentou
6. Voltar para background
7. Tap "Continuar" na notificação
8. Verificar timer retomado
9. Aguardar 1 minuto
10. Abrir app → verificar tempo aumentou 1 min

**Expected**:
- Pause funciona com app em background/killed
- Tempo não aumenta enquanto pausado
- Resume funciona e timer continua de onde parou

**Priority**: P0

---

#### TC5: Battery Optimization - Xiaomi
**Steps**:
1. Device: Xiaomi com MIUI
2. Iniciar timer
3. Ir para Settings → Battery → App battery saver
4. Verificar Odyssey com "No restrictions"
5. Se não, mostrar instrução
6. Aguardar 30 min em background
7. Verificar timer funcionou corretamente

**Expected**:
- Se app sem whitelist: timer pode parar ou atrasar
- Se app com whitelist: timer funciona normalmente
- UX detecta Xiaomi e sugere whitelist

**Priority**: P1

---

#### TC6: Daily Mood Reminder
**Steps**:
1. Abrir app → Settings → Notifications
2. Habilitar "Lembrete de humor"
3. Configurar horário: 14:00
4. Salvar
5. Aguardar até 14:00 (ou usar debug mode para forçar)
6. Verificar notificação exibida
7. Tap "Registrar humor" na notificação
8. Verificar app abre na tela de mood tracker

**Expected**:
- Notificação exibida no horário configurado (±5 min)
- Ação "Registrar humor" abre app na tela correta
- Reminder se repete todos os dias

**Priority**: P0

---

#### TC7: FCM Remote Notification
**Steps**:
1. Obter FCM token do device (console logs)
2. Enviar test notification via Firebase Console:
   - Title: "🏆 Conquista Desbloqueada!"
   - Body: "Você atingiu nível 5!"
   - Data: `{ "type": "achievement", "achievement_id": "level_5" }`
3. Verificar notificação recebida
4. Tap na notificação
5. Verificar app abre

**Expected**:
- Notificação exibida (foreground ou background)
- Tap abre app
- Analytics trackam `notification_received` e `notification_opened`

**Priority**: P1

---

## 🚨 Riscos e Mitigações

### R1: OEMs matam foreground services
**Probabilidade**: MÉDIA  
**Impacto**: ALTO  
**Mitigação**:
- Documentar devices problemáticos (Xiaomi, Huawei)
- Implementar UX para solicitar whitelist de bateria
- Instruções específicas por OEM
- Analytics para detectar taxa de kill por device

### R2: iOS não suporta timers em background
**Probabilidade**: ALTA (certeza)  
**Impacto**: MÉDIO  
**Mitigação**:
- Documentar limitação para usuários
- Implementar agendamento de notificação local para término
- Recuperar estado ao reabrir app
- UX clara: "Timer pode não atualizar em background no iOS"

### R3: Notificações agendadas não exibidas
**Probabilidade**: BAIXA  
**Impacto**: ALTO  
**Mitigação**:
- Validar permissões antes de agendar
- Usar exact alarms (Android 12+)
- Logs estruturados para debug
- Telemetria: taxa de notificações agendadas vs exibidas

### R4: Drift de tempo em timers longos
**Probabilidade**: MÉDIA  
**Impacto**: BAIXO  
**Mitigação**:
- Aceitar drift de até 5 segundos em timers > 30 min
- Usar `System.currentTimeMillis()` para cálculo ao invés de ticks
- Documentar imprecisão esperada

### R5: Bateria drain com timers frequentes
**Probabilidade**: BAIXA  
**Impacto**: MÉDIO  
**Mitigação**:
- Não usar WakeLock full (apenas partial se necessário)
- Reduzir frequência de ticks se bateria baixa (detectar battery level)
- Analytics para monitorar battery usage

### R6: Sincronização via FCM falha
**Probabilidade**: MÉDIA  
**Impacto**: BAIXO (feature opcional)  
**Mitigação**:
- FCM é apenas fallback/optional
- App funciona 100% offline
- Retry logic com exponential backoff
- Notificar usuário de falha de sync

---

## 📈 Estimativas e Cronograma

### MVP (Must Have)

| Ticket | Estimativa (h) | Developer | Dependencies |
|--------|----------------|-----------|--------------|
| T1 | 3-5 | Flutter Dev | - |
| T2 | 5-8 | Android Dev | - |
| T3 | 8-13 | iOS Dev + Flutter Dev | T1 |
| T4 | 3-5 | QA | T1, T2, T3 |
| T5 | 5-8 | Flutter Dev + UX | T1 |
| **Total MVP** | **24-39h** | | **3-5 sprints** |

### V1.1 (Should Have)

| Ticket | Estimativa (h) | Developer | Dependencies |
|--------|----------------|-----------|--------------|
| T6 | 8-13 | Backend + Flutter | MVP |
| T7 | 3-5 | Flutter Dev | MVP |
| T8 | 5-8 | Flutter Dev + Product | MVP |
| **Total V1.1** | **16-26h** | | **2-3 sprints** |

### V1.2+ (Could Have)

| Ticket | Estimativa (h) | Developer | Dependencies |
|--------|----------------|-----------|--------------|
| T9 | 13-21 | Full team | V1.1 |
| T10 | 5-8 | Flutter + Data Analyst | V1.1 |
| **Total V1.2** | **18-29h** | | **2-3 sprints** |

**Total geral**: 58-94 horas (7-12 sprints de 2 semanas)

---

## ✅ Checklist de PR Review

Usar este checklist para todos os PRs relacionados a notificações:

- [ ] **Code Quality**
  - [ ] Código segue style guide do projeto
  - [ ] Sem código comentado ou TODOs não resolvidos
  - [ ] Sem hardcoded strings (usar l10n)
  - [ ] Sem magic numbers (usar constantes)
  - [ ] Logs estruturados com níveis corretos

- [ ] **Testing**
  - [ ] Unit tests escritos com cobertura mínima 70%
  - [ ] Integration tests para flows críticos
  - [ ] Manual testing em pelo menos 2 devices (Android + iOS)
  - [ ] Test matrix preenchida

- [ ] **Documentation**
  - [ ] Docstrings em métodos públicos
  - [ ] README atualizado se necessário
  - [ ] CHANGELOG atualizado
  - [ ] Comentários inline onde lógica é complexa

- [ ] **UX/UI**
  - [ ] Strings localizadas (pt_BR)
  - [ ] Rationale claro para permissões
  - [ ] Loading states implementados
  - [ ] Error states implementados
  - [ ] Accessibility labels (VoiceOver/TalkBack)

- [ ] **Performance**
  - [ ] Nenhum blocking call em UI thread
  - [ ] Nenhum memory leak
  - [ ] Battery usage aceitável (<5% em 1h de timer)

- [ ] **Security**
  - [ ] Nenhum dado sensível em logs
  - [ ] Nenhum dado sensível em notificações
  - [ ] Validação de input de usuário

- [ ] **Platform Specific**
  - **Android**:
    - [ ] Permissions declaradas no Manifest
    - [ ] PendingIntent flags corretas (IMMUTABLE)
    - [ ] Foreground service type declarado
  - **iOS**:
    - [ ] NSUserTrackingUsageDescription no Info.plist
    - [ ] UNNotificationCategory configurado

---

## 🔍 Perguntas Abertas (para Product Owner)

### P1: Sincronização multi-device
**Questão**: Devemos implementar sincronização de timer via FCM (T6) no MVP ou em V1.1?

**Contexto**: Implementação adiciona 8-13h de trabalho e depende de backend.

**Recomendação**: Mover para V1.1 se não houver demanda forte de usuários.

---

### P2: Precisão do timer iOS
**Questão**: Qual nível de precisão é aceitável para timer em background no iOS?

**Contexto**: iOS não garante execução em background. Podemos ter drift de 5-10 segundos em timers longos.

**Opções**:
- A) Aceitar drift de até 10s e documentar
- B) Exigir que usuário mantenha app aberto (UX ruim)
- C) Não suportar timers longos no iOS (>15 min)

**Recomendação**: Opção A.

---

### P3: Múltiplos timers simultâneos
**Questão**: Devemos suportar múltiplos timers ao mesmo tempo (T9)?

**Contexto**: Complexidade alta, UX pode ser confusa, battery drain.

**Recomendação**: Validar com usuários via survey antes de implementar.

---

### P4: Notificações de re-engajamento
**Questão**: Qual é a estratégia de re-engajamento? Frequência? Segmentação?

**Contexto**: T10 depende de definição de product.

**Recomendação**: Alinhar com growth team antes de implementar.

---

### P5: Fallback para devices sem suporte
**Questão**: O que fazer em devices que não suportam foreground services ou matam aggressivamente (Huawei sem Google Services)?

**Opções**:
- A) Mostrar warning e permitir uso limitado
- B) Bloquear features de timer nesses devices
- C) Implementar workaround específico (ex: WorkManager)

**Recomendação**: Opção A + telemetria para medir impacto.

---

## 📚 Referências e Recursos

### Documentação Oficial
- [Awesome Notifications](https://pub.dev/packages/awesome_notifications)
- [Android Foreground Services](https://developer.android.com/guide/components/foreground-services)
- [iOS Local Notifications](https://developer.apple.com/documentation/usernotifications)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Android Doze and App Standby](https://developer.android.com/training/monitoring-device-state/doze-standby)

### Artigos Técnicos
- [Don't kill my app!](https://dontkillmyapp.com/) - Lista de OEMs problemáticos
- [Background Work on Android](https://medium.com/androiddevelopers/background-work-on-android)
- [iOS Background Execution](https://developer.apple.com/documentation/backgroundtasks)

### Ferramentas
- [ADB Commands para teste de Doze](https://developer.android.com/training/monitoring-device-state/doze-standby#testing_doze)
- [iOS Simulator Background Fetch](https://developer.apple.com/documentation/xcode/testing-background-updates-in-simulator)

---

## 🎯 Next Steps Imediatos

1. **Review com Product Owner** (1h)
   - Validar prioridades
   - Responder perguntas abertas
   - Aprovar estimativas

2. **Sprint Planning** (2h)
   - Alocar tickets T1-T5 para desenvolvedores
   - Definir sprints (sugerido: 2 sprints de 2 semanas para MVP)

3. **Kickoff Técnico** (1h)
   - Apresentar arquitetura para time
   - Esclarecer dúvidas técnicas
   - Alinhar padrões de código

4. **Setup de Ambiente** (2h)
   - Criar branches: `feature/notifications-mvp`
   - Setup CI/CD para testes automatizados
   - Configurar devices de teste

5. **Início de Desenvolvimento** (Sprint 1)
   - T1 + T2 em paralelo
   - T5 (UX) pode começar design

---

## 📞 Contatos e Responsáveis

| Papel | Nome | Responsabilidade |
|-------|------|------------------|
| Product Owner | [TBD] | Decisões de produto, prioridades |
| Tech Lead | [TBD] | Arquitetura, code review |
| Flutter Dev | [TBD] | T1, T5, T7, T8 |
| Android Dev | [TBD] | T2 |
| iOS Dev | [TBD] | T3 |
| Backend Dev | [TBD] | T6 |
| QA Lead | [TBD] | T4, test execution |
| UX Designer | [TBD] | T5 (UI/UX) |

---

## 📝 Change Log

| Versão | Data | Autor | Mudanças |
|--------|------|-------|----------|
| 1.0 | 2025-12-11 | IA Analyst | Criação inicial do plano técnico |

---

## ✍️ Aprovações

| Papel | Nome | Assinatura | Data |
|-------|------|------------|------|
| Product Owner | | | |
| Tech Lead | | | |
| Engineering Manager | | | |

---

**FIM DO DOCUMENTO**

---

## 📎 Anexos

### A1: Exemplo de Payload FCM para Notificação Remota

```json
{
  "to": "FCM_TOKEN_HERE",
  "notification": {
    "title": "🎭 Lembrete de Humor",
    "body": "Como você está se sentindo agora?"
  },
  "data": {
    "type": "mood_reminder",
    "action": "open_mood",
    "timestamp": "2025-12-11T15:00:00Z"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "reminders_channel",
      "icon": "ic_notification",
      "color": "#7C4DFF"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "alert": {
          "title": "🎭 Lembrete de Humor",
          "body": "Como você está se sentindo agora?"
        },
        "sound": "default",
        "badge": 1,
        "category": "MOOD_REMINDER"
      }
    }
  }
}
```

### A2: Exemplo de UNNotificationCategory (iOS)

```swift
// AppDelegate.swift
let startBreakAction = UNNotificationAction(
    identifier: "START_BREAK",
    title: "Iniciar Pausa",
    options: [.foreground]
)

let startFocusAction = UNNotificationAction(
    identifier: "START_FOCUS",
    title: "Iniciar Foco",
    options: [.foreground]
)

let pomodoroCategory = UNNotificationCategory(
    identifier: "POMODORO_COMPLETE",
    actions: [startBreakAction],
    intentIdentifiers: [],
    options: []
)

let breakCategory = UNNotificationCategory(
    identifier: "BREAK_COMPLETE",
    actions: [startFocusAction],
    intentIdentifiers: [],
    options: []
)

UNUserNotificationCenter.current().setNotificationCategories([
    pomodoroCategory,
    breakCategory
])
```

### A3: Exemplo de SharedPreferences State (Android)

```kotlin
// Salvar estado
val prefs = context.getSharedPreferences("timer_prefs", Context.MODE_PRIVATE)
prefs.edit().apply {
    putBoolean("is_running", true)
    putBoolean("is_paused", false)
    putString("task_name", "Estudar Flutter")
    putInt("elapsed_seconds", 150)
    putLong("start_time", System.currentTimeMillis())
    putInt("duration_seconds", 1500) // 25 min
    putBoolean("is_pomodoro", true)
    apply()
}

// Recuperar estado
val isRunning = prefs.getBoolean("is_running", false)
val taskName = prefs.getString("task_name", "Timer")
val elapsedSeconds = prefs.getInt("elapsed_seconds", 0)
```

### A4: Comandos ADB para Teste de Doze Mode

```bash
# Forçar device entrar em Doze mode
adb shell dumpsys deviceidle force-idle

# Sair de Doze mode
adb shell dumpsys deviceidle unforce

# Verificar status de Doze
adb shell dumpsys deviceidle get

# Desabilitar otimização de bateria para app
adb shell dumpsys deviceidle whitelist +com.example.odyssey

# Simular reboot (teste BootReceiver)
adb reboot
```

### A5: Instruções de Whitelist por OEM

#### Xiaomi (MIUI)
1. Abrir **Configurações**
2. **Aplicativos** → **Gerenciar aplicativos**
3. Encontrar **Odyssey**
4. **Economia de bateria** → Selecionar **Sem restrições**
5. **Inicialização automática** → Habilitar
6. **Bloqueio em segundo plano** → Desabilitar

#### Huawei (EMUI)
1. Abrir **Configurações**
2. **Bateria** → **Inicialização de aplicativos**
3. Encontrar **Odyssey** → Desabilitar **Gerenciar automaticamente**
4. Habilitar **Inicialização automática**, **Executar em segundo plano**, **Executar após fechado**
5. **Aplicativos protegidos** → Habilitar **Odyssey**

#### Samsung (One UI)
1. Abrir **Configurações**
2. **Aplicativos** → **Odyssey**
3. **Bateria** → **Otimizar uso da bateria** → Desabilitar
4. **Apps em suspensão** → Remover Odyssey da lista

---

**Este plano técnico foi gerado por IA Analyst Expert em Flutter/Dart e Android/iOS nativo.**
