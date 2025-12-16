# 🔔 GUIA DE NOTIFICAÇÕES MODERNAS - ANDROID

**Sistema completo de notificações redesenhado para Android**

---

## 🎨 Design Moderno

### Aparência das Notificações

As notificações agora seguem o padrão moderno do Material Design 3:

```
┌──────────────────────────────────────────┐
│  [ÍCONE]  Odyssey          (pequeno)     │
│                                          │
│  ✅ Nome da Tarefa        (título)       │
│  Descrição da tarefa      (corpo)        │
│                                          │
│  [Botão 1]  [Botão 2]  [Botão 3]        │
└──────────────────────────────────────────┘
```

**Características:**
- ✅ Ícone do app visível automaticamente (Android usa o launcher icon)
- ✅ Nome do app pequeno no topo ("Odyssey")
- ✅ Título destacado em negrito
- ✅ Corpo da mensagem abaixo
- ✅ Até 3 botões de ação
- ✅ Cores personalizadas por canal
- ✅ LED colorido (se dispositivo suportar)
- ✅ Vibrações customizadas

---

## 📱 Canais de Notificação

### 1. HUMOR (Roxo Violeta - #7C3AED)
**Canal:** `mood_channel`
- Lembretes para registrar humor
- Importância: Alta
- Som: Sim
- Vibração: Sim
- LED: Roxo

**Ações:**
- "Registrar agora"
- "Mais tarde"

### 2. TAREFAS (Azul - #2196F3)
**Canal:** `tasks_channel`
- Lembretes de tarefas pendentes
- Indicador de atraso (⚠️)
- Indicador de prazo (⏰)
- Importância: Alta
- Som: Sim
- Vibração: Sim
- LED: Azul

**Ações:**
- "Marcar como concluída"
- "Abrir"
- "Adiar"

### 3. HÁBITOS (Verde - #4CAF50)
**Canal:** `habits_channel`
- Lembretes de hábitos diários
- Mostra streak atual (🔥)
- Importância: Alta
- Som: Sim
- Vibração: Sim
- LED: Verde

**Ações:**
- "Marcar como feito"
- "Pular por hoje"

### 4. POMODORO (Laranja/Vermelho - #FF5722)
**Canal:** `pomodoro_channel`
- Timer completo
- Pausa completa
- Importância: Máxima
- Som: Sim
- Vibração: Sim
- LED: Laranja
- Wake Screen: Sim

**Ações:**
- "Iniciar pausa"
- "Continuar focando"
- "Iniciar sessão"

### 5. CONQUISTAS (Dourado - #FFB300)
**Canal:** `achievements_channel`
- Conquistas desbloqueadas
- Level Up
- Importância: Alta
- Som: Sim
- Vibração: Sim
- LED: Amarelo

**Ações:**
- "Ver conquistas"
- "Ver perfil"

### 6. LEMBRETES (Roxo Claro - #9C27B0)
**Canal:** `reminders_channel`
- Lembretes gerais
- Importância: Default
- Som: Sim
- Vibração: Não
- LED: Roxo

### 7. MOTIVAÇÃO (Rosa - #E91E63)
**Canal:** `motivation_channel`
- Mensagens motivacionais
- Importância: Default
- Som: Não
- Vibração: Não
- LED: Rosa

---

## 🔧 Como Usar no Código

### Importar o Serviço

```dart
import 'package:odyssey/src/utils/services/modern_notification_service.dart';
import 'package:odyssey/src/providers/modern_notification_provider.dart';
```

### Enviar Notificação de Humor

```dart
await ModernNotificationService.instance.sendMoodReminder(
  title: 'Como você está se sentindo?',
  body: 'Registre seu humor de hoje e ganhe XP!',
  scheduledDate: DateTime.now().add(Duration(hours: 1)), // opcional
);
```

### Enviar Notificação de Tarefa

```dart
await ModernNotificationService.instance.sendTaskReminder(
  taskId: task.id,
  taskTitle: task.title,
  taskDescription: task.description,
  dueDate: task.dueDate,
  scheduledDate: DateTime.now().add(Duration(minutes: 30)), // opcional
);
```

### Enviar Notificação de Hábito

```dart
await ModernNotificationService.instance.sendHabitReminder(
  habitId: habit.id,
  habitName: habit.name,
  habitDescription: habit.description,
  streak: 7, // sequência atual
  scheduledDate: DateTime.now().add(Duration(hours: 2)), // opcional
);
```

### Enviar Notificação de Pomodoro

```dart
// Quando completar sessão
await ModernNotificationService.instance.sendPomodoroComplete(
  sessionNumber: 3,
  totalMinutes: 25,
);

// Quando completar pausa
await ModernNotificationService.instance.sendPomodoroBreakComplete();
```

### Enviar Conquista

```dart
await ModernNotificationService.instance.sendAchievementUnlocked(
  achievementName: 'Primeiro Hábito',
  achievementDescription: 'Você criou seu primeiro hábito!',
  xpReward: 50,
);
```

### Enviar Level Up

```dart
await ModernNotificationService.instance.sendLevelUp(
  newLevel: 5,
  xpToNextLevel: 500,
);
```

### Enviar Mensagem Motivacional

```dart
await ModernNotificationService.instance.sendMotivationalNotification(
  title: '💪 Você consegue!',
  body: 'Cada pequeno passo te leva mais perto do seu objetivo.',
);
```

### Cancelar Notificação

```dart
// Específica
await ModernNotificationService.instance.cancelNotification(notificationId);

// Todas
await ModernNotificationService.instance.cancelAllNotifications();

// Apenas agendadas
await ModernNotificationService.instance.cancelAllScheduledNotifications();
```

---

## ⚙️ Configurações (UI)

### Usando Provider

```dart
// Em um widget
class NotificationSettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return ListView(
      children: [
        SwitchListTile(
          title: Text('Lembretes de Humor'),
          value: settings.moodRemindersEnabled,
          onChanged: (value) {
            notifier.setMoodRemindersEnabled(value);
          },
        ),
        
        if (settings.moodRemindersEnabled)
          ListTile(
            title: Text('Horário do Lembrete'),
            subtitle: Text(settings.moodReminderTime),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: 20, minute: 0),
              );
              if (time != null) {
                await notifier.setMoodReminderTime(time.hour, time.minute);
              }
            },
          ),
        
        SwitchListTile(
          title: Text('Lembretes de Tarefas'),
          value: settings.taskRemindersEnabled,
          onChanged: (value) {
            notifier.setTaskRemindersEnabled(value);
          },
        ),
        
        SwitchListTile(
          title: Text('Lembretes de Hábitos'),
          value: settings.habitRemindersEnabled,
          onChanged: (value) {
            notifier.setHabitRemindersEnabled(value);
          },
        ),
        
        SwitchListTile(
          title: Text('Mensagens Motivacionais'),
          value: settings.motivationEnabled,
          onChanged: (value) {
            notifier.setMotivationEnabled(value);
          },
        ),
      ],
    );
  }
}
```

---

## 🔄 Scheduler Automático

O `ModernNotificationScheduler` cuida de enviar notificações automaticamente:

### Notificações Automáticas

1. **Lembrete de Humor**
   - Horário configurável (padrão: 20:00)
   - Enviado diariamente
   - Pode ser desabilitado

2. **Tarefas Pendentes**
   - Verificação a cada hora
   - Prioriza tarefas de hoje
   - Depois tarefas atrasadas
   - Mostra apenas 1 por vez (não spam)

3. **Hábitos Pendentes**
   - Verificação a cada hora
   - Apenas hábitos do dia de hoje
   - Mostra streak para motivar
   - Não notifica se já foi feito

4. **Mensagens Motivacionais**
   - Frequência configurável (padrão: 2x/dia)
   - Frases aleatórias
   - Não repete no mesmo dia

---

## 🎯 Melhores Práticas

### 1. Não Spam
```dart
// ❌ Evitar
for (var task in tasks) {
  await sendTaskReminder(...);
}

// ✅ Fazer
final importantTask = tasks.first;
await sendTaskReminder(...);
```

### 2. Usar Agendamento
```dart
// ✅ Agendar para futuro
await sendTaskReminder(
  ...
  scheduledDate: task.dueDate.subtract(Duration(hours: 1)),
);
```

### 3. Cancelar ao Concluir
```dart
// Quando marcar tarefa como concluída
await ModernNotificationService.instance.cancelTaskReminder(task.id);
```

### 4. Contexto Relevante
```dart
// ✅ Incluir informação útil
await sendTaskReminder(
  taskTitle: task.title,
  taskDescription: 'Prazo: ${formatDate(task.dueDate)}',
  ...
);
```

---

## 🐛 Debugging

### Verificar se Notificações Estão Ativas

```dart
final allowed = await ModernNotificationService.instance.isNotificationAllowed();
print('Notificações permitidas: $allowed');
```

### Listar Notificações Agendadas

```dart
final scheduled = await ModernNotificationService.instance.getActiveNotifications();
for (var notif in scheduled) {
  print('ID: ${notif.id}, Título: ${notif.title}');
}
```

### Logs

O serviço imprime logs úteis:
```
📱 ModernNotificationService inicializado
📅 ModernNotificationScheduler inicializado
🔔 Verificando notificações pendentes...
📋 Tarefas hoje: 3, Atrasadas: 1
💪 Hábitos pendentes hoje: 2
```

---

## 📱 Testando

### Testar Notificação Imediata

```dart
// No debug screen ou botão de teste
FloatingActionButton(
  onPressed: () async {
    await ModernNotificationService.instance.sendTaskReminder(
      taskId: 999,
      taskTitle: 'Teste de Notificação',
      taskDescription: 'Esta é uma notificação de teste',
    );
  },
  child: Icon(Icons.notifications),
)
```

### Testar Agendamento

```dart
// Agendar para daqui a 10 segundos
await ModernNotificationService.instance.sendMoodReminder(
  title: 'Teste Agendado',
  body: 'Esta notificação foi agendada',
  scheduledDate: DateTime.now().add(Duration(seconds: 10)),
);
```

---

## ⚠️ Troubleshooting

### Notificações Não Aparecem

1. **Verificar Permissões**
```dart
final allowed = await ModernNotificationService.instance.isNotificationAllowed();
if (!allowed) {
  await ModernNotificationService.instance.requestPermissions();
}
```

2. **Verificar AndroidManifest**
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

3. **Verificar Bateria**
- Android pode limitar notificações para economizar bateria
- Ir em Configurações > Bateria > Otimização > Odyssey > Não otimizar

4. **Verificar Canal**
- Android 8+ usa canais
- Se desabilitou um canal, precisa reabilitar nas configurações do sistema

### Notificações Duplicadas

```dart
// Cancelar antes de enviar
await ModernNotificationService.instance.cancelNotification(taskId);
await ModernNotificationService.instance.sendTaskReminder(...);
```

### Ações Não Funcionam

As ações estão prontas mas precisam ser implementadas no callback:

```dart
// Em modern_notification_service.dart
static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
  final action = receivedAction.buttonKeyPressed;
  final payload = receivedAction.payload;
  
  switch (action) {
    case 'TASK_COMPLETE':
      // TODO: Marcar tarefa como concluída
      final taskId = int.parse(payload?['taskId'] ?? '0');
      // Chamar repository...
      break;
    case 'HABIT_COMPLETE':
      // TODO: Marcar hábito como feito
      break;
    // ... outras ações
  }
}
```

---

## 📊 Estatísticas

Após implementação, você poderá rastrear:
- Total de notificações enviadas
- Taxa de interação (cliques)
- Ações mais usadas
- Horários de maior engajamento

---

## 🚀 Próximos Passos

### Implementações Futuras

1. **Notificações Ricas**
   - Imagens inline
   - Progress bars
   - Botões com ícones

2. **Smart Notifications**
   - Machine Learning para melhor timing
   - Personalização por hábito do usuário
   - Conteúdo adaptativo

3. **Notificações Sociais**
   - Se adicionar modo colaborativo
   - Notificações de outros usuários

4. **Integração Wearables**
   - Smartwatch notifications
   - Quick actions no relógio

---

**Última atualização:** 12/12/2024  
**Versão:** 2.0.0 (Sistema Moderno)

---

*Este sistema foi desenvolvido especificamente para Android e segue as últimas guidelines do Material Design 3.*
