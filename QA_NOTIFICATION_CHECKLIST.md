# QA Checklist - Notificações e Timer

**Versão:** 1.0  
**Data:** 2025-12-11

---

## Dispositivos para Teste

### Android
| Dispositivo | Versão OS | OEM | Prioridade |
|-------------|-----------|-----|------------|
| Pixel 6/7 | Android 14 | Google (Stock) | P0 |
| Galaxy S21/S22 | Android 13-14 | Samsung | P0 |
| Redmi Note 11/12 | Android 12-13 (MIUI) | Xiaomi | P0 |
| P40/P50 | Android 10-12 (EMUI) | Huawei | P1 |
| OnePlus 9/10 | Android 12-13 (OxygenOS) | OnePlus | P2 |

### iOS
| Dispositivo | Versão iOS | Prioridade |
|-------------|------------|------------|
| iPhone 13/14 | iOS 17 | P0 |
| iPhone 12 | iOS 16 | P1 |
| iPhone 11 | iOS 15 | P2 |

---

## Casos de Teste

### TC1: Timer Pomodoro - Fluxo Normal
**Prioridade:** P0

| # | Passo | Esperado | Android | iOS |
|---|-------|----------|---------|-----|
| 1 | Abrir app → Navegar para Timer | Tela de timer exibida | [ ] | [ ] |
| 2 | Selecionar tarefa "Estudar Flutter" | Tarefa selecionada | [ ] | [ ] |
| 3 | Iniciar Pomodoro (25 min) | Timer iniciado, notificação aparece | [ ] | [ ] |
| 4 | Verificar notificação persistente | Mostra nome da tarefa e tempo restante | [ ] | N/A |
| 5 | Minimizar app (10 min em background) | Timer continua rodando | [ ] | [ ] |
| 6 | Reabrir app | Timer mostra tempo correto (~10 min) | [ ] | [ ] |
| 7 | Aguardar conclusão em background | Notificação de conclusão exibida | [ ] | [ ] |
| 8 | Tap na notificação | App abre na tela de timer | [ ] | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC2: Timer - App Force Stop (Android)
**Prioridade:** P0

| # | Passo | Esperado | Resultado |
|---|-------|----------|-----------|
| 1 | Iniciar timer (10 min) | Timer rodando | [ ] |
| 2 | Verificar notificação persistente | Visível e não-dismissível | [ ] |
| 3 | Force Stop via Settings → Apps → Odyssey → Force Stop | App fechado | [ ] |
| 4 | Verificar notificação | Ainda visível | [ ] |
| 5 | Aguardar 5 min | Notificação atualiza tempo | [ ] |
| 6 | Aguardar até conclusão | Notificação de conclusão | [ ] |
| 7 | Reabrir app | Estado sincronizado | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC3: Timer - Reboot do Dispositivo (Android)
**Prioridade:** P0

| # | Passo | Esperado | Resultado |
|---|-------|----------|-----------|
| 1 | Iniciar timer (30 min) | Timer rodando | [ ] |
| 2 | Aguardar 5 min | Timer em 5:00 | [ ] |
| 3 | Reiniciar dispositivo | Device reinicia | [ ] |
| 4 | Aguardar boot completo | Sistema carregado | [ ] |
| 5 | Verificar notificação | Restaurada com tempo correto (~5 min elapsed) | [ ] |
| 6 | Aguardar conclusão | Notificação de conclusão no tempo correto | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC4: Ações na Notificação - Pause/Resume
**Prioridade:** P0

| # | Passo | Esperado | Android | iOS |
|---|-------|----------|---------|-----|
| 1 | Iniciar timer | Notificação com botões | [ ] | [ ] |
| 2 | Tap "Pausar" na notificação | Timer pausado, notificação atualiza | [ ] | N/A |
| 3 | Aguardar 2 min | Tempo NÃO aumenta | [ ] | [ ] |
| 4 | Abrir app → Verificar estado | Mostra "Pausado" com tempo correto | [ ] | [ ] |
| 5 | Tap "Continuar" na notificação | Timer retomado | [ ] | N/A |
| 6 | Aguardar 1 min | Tempo aumentou 1 min | [ ] | [ ] |
| 7 | Tap "Parar" na notificação | Timer parado, notificação removida | [ ] | N/A |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC5: Lembrete Diário de Humor
**Prioridade:** P0

| # | Passo | Esperado | Android | iOS |
|---|-------|----------|---------|-----|
| 1 | Settings → Notificações → Ativar lembrete de humor | Toggle ativado | [ ] | [ ] |
| 2 | Configurar horário (usar horário próximo para teste) | Horário salvo | [ ] | [ ] |
| 3 | Aguardar até horário configurado | Notificação exibida | [ ] | [ ] |
| 4 | Verificar conteúdo | "Como você está se sentindo?" | [ ] | [ ] |
| 5 | Tap na notificação | App abre | [ ] | [ ] |
| 6 | Verificar repetição no dia seguinte | Notificação repetida | [ ] | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC6: Alerta de Streak
**Prioridade:** P1

| # | Passo | Esperado | Android | iOS |
|---|-------|----------|---------|-----|
| 1 | Ter streak ativo (3+ dias) | Streak visível no perfil | [ ] | [ ] |
| 2 | Não registrar nada até 21:30 | Aguardar | [ ] | [ ] |
| 3 | Verificar notificação de streak | "Streak em risco!" exibido | [ ] | [ ] |
| 4 | Tap na notificação | App abre na tela de mood | [ ] | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC7: Otimização de Bateria - Xiaomi/MIUI
**Prioridade:** P0

| # | Passo | Esperado | Resultado |
|---|-------|----------|-----------|
| 1 | Instalar app em device Xiaomi | App instalado | [ ] |
| 2 | Abrir app primeira vez | Dialog de whitelist exibido | [ ] |
| 3 | Seguir instruções | Configurações abertas | [ ] |
| 4 | Configurar "Sem restrições" e "Inicialização automática" | Configurado | [ ] |
| 5 | Iniciar timer | Timer rodando | [ ] |
| 6 | Aguardar 30 min em background | Timer continua | [ ] |
| 7 | Verificar conclusão | Notificação exibida | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC8: Timer iOS - Background State Recovery
**Prioridade:** P0

| # | Passo | Esperado | Resultado |
|---|-------|----------|-----------|
| 1 | Iniciar timer (5 min) no iOS | Timer rodando | [ ] |
| 2 | Minimizar app imediatamente | App em background | [ ] |
| 3 | Aguardar 2 min | - | [ ] |
| 4 | Reabrir app | Timer mostra ~2 min elapsed | [ ] |
| 5 | Minimizar novamente | - | [ ] |
| 6 | Aguardar até conclusão | Notificação exibida aos 5 min | [ ] |
| 7 | Tap "Iniciar Pausa" na notificação | App abre | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC9: Notificação de Teste
**Prioridade:** P1

| # | Passo | Esperado | Android | iOS |
|---|-------|----------|---------|-----|
| 1 | Settings → Notificações | Tela aberta | [ ] | [ ] |
| 2 | Tap "Testar Notificação" | Notificação exibida | [ ] | [ ] |
| 3 | Verificar conteúdo | "As notificações estão funcionando" | [ ] | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

### TC10: Permissões Negadas
**Prioridade:** P1

| # | Passo | Esperado | Android | iOS |
|---|-------|----------|---------|-----|
| 1 | Negar permissão de notificação | Permissão negada | [ ] | [ ] |
| 2 | Abrir Settings → Notificações | Warning exibido | [ ] | [ ] |
| 3 | Tap "Permitir" | Dialog do sistema | [ ] | [ ] |
| 4 | Permitir notificações | Permissão concedida | [ ] | [ ] |
| 5 | Warning deve desaparecer | UI atualizada | [ ] | [ ] |

**Resultado:** PASS [ ] / FAIL [ ]  
**Notas:**

---

## Matriz de Resultados

### Resumo por Dispositivo

| Dispositivo | TC1 | TC2 | TC3 | TC4 | TC5 | TC6 | TC7 | TC8 | TC9 | TC10 |
|-------------|-----|-----|-----|-----|-----|-----|-----|-----|-----|------|
| Pixel | | | | | | | N/A | N/A | | |
| Samsung | | | | | | | N/A | N/A | | |
| Xiaomi | | | | | | | | N/A | | |
| iPhone 13 | | N/A | N/A | | | | N/A | | | |
| iPhone 12 | | N/A | N/A | | | | N/A | | | |

**Legenda:**
- ✅ Pass
- ❌ Fail
- ⚠️ Pass com limitações
- N/A Não aplicável

---

## Template de Bug Report

```markdown
### Título
[Componente] Breve descrição do problema

### Ambiente
- Dispositivo: 
- Versão OS: 
- Versão App: 
- Caso de Teste: TC#

### Passos para Reproduzir
1. 
2. 
3. 

### Comportamento Esperado


### Comportamento Atual


### Screenshots/Vídeo
[Anexar se aplicável]

### Logs
[Anexar se aplicável]

### Severidade
- [ ] Crítico - App crash ou perda de dados
- [ ] Alto - Feature não funciona
- [ ] Médio - Workaround disponível
- [ ] Baixo - Cosmético

### Frequência
- [ ] Sempre (100%)
- [ ] Frequente (>50%)
- [ ] Ocasional (<50%)
- [ ] Raro (<10%)
```

---

## Critérios de Aprovação

### Must Pass (Blocker se falhar)
- TC1: Timer Pomodoro - Fluxo Normal
- TC2: Timer - App Force Stop (Android)
- TC4: Ações na Notificação
- TC5: Lembrete Diário de Humor
- TC8: Timer iOS - Background State Recovery

### Should Pass (High Priority)
- TC3: Timer - Reboot
- TC6: Alerta de Streak
- TC7: Otimização de Bateria
- TC9: Notificação de Teste
- TC10: Permissões Negadas

### Aceitação
- Todos os Must Pass devem passar em pelo menos 1 device Android + 1 device iOS
- 80% dos Should Pass devem passar
- Nenhum bug crítico aberto

---

## Assinaturas

| Papel | Nome | Data | Assinatura |
|-------|------|------|------------|
| QA Lead | | | |
| Dev Lead | | | |
| Product Owner | | | |
