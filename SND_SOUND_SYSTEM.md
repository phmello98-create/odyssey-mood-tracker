# Sistema de Sons SND UI/UX - Odyssey

Sistema completo de efeitos sonoros para UI/UX inspirado em [SND.dev](https://snd.dev), implementado com sons profissionais SND01_sine.

## 📦 Arquivos Principais

### Services
- `lib/src/utils/services/sound_service.dart` - Serviço principal de sons (estendido com SND)
- `lib/src/utils/sound_helpers.dart` - Helpers, NavigatorObserver e extensions

### Widgets
- `lib/src/shared/widgets/sound_widgets.dart` - Widgets com sons integrados

### Assets
- `assets/sounds/*.wav` - Sons SND01_sine (29 arquivos)

## 🎵 Sons Disponíveis

### Sons SND01_sine

| Som | Uso | Método |
|-----|-----|--------|
| **button.wav** | Botão com função específica | `playSndButton()` |
| **tap_01-05.wav** | Feedback tátil (5 variações) | `playSndTap()` |
| **select.wav** | Checkbox, radio, form | `playSndSelect()` |
| **disabled.wav** | Botão desabilitado | `playSndDisabled()` |
| **toggle_on.wav** | Switch ativado | `playSndToggleOn()` |
| **toggle_off.wav** | Switch desativado | `playSndToggleOff()` |
| **transition_up.wav** | Abrir modal/dialog | `playSndTransitionUp()` |
| **transition_down.wav** | Fechar modal/dialog | `playSndTransitionDown()` |
| **swipe_01-05.wav** | Transição horizontal (5 var) | `playSndSwipe()` |
| **type_01-05.wav** | 🎹 Digitação (5 variações) | `playSndType()` |
| **notification.wav** | Notificação genérica | `playSndNotification()` |
| **caution.wav** | Aviso negativo | `playSndCaution()` |
| **celebration.wav** | Conquista máxima | `playSndCelebration()` |
| **progress_loop.wav** | Loop de processamento | `startSndProgressLoop()` |
| **ringtone_loop.wav** | Alarme/toque (loop) | `startSndRingtoneLoop()` |

### 🎹 Destaque: Sons de Digitação

Os sons **type_01 a type_05** são especialmente projetados para feedback durante digitação:
- 🎵 **5 variações** diferentes tocam aleatoriamente a cada tecla
- 🔄 Evita fadiga auditiva ao digitar muito texto
- ⌨️ Funciona ao **digitar E ao deletar** (backspace)
- 🎯 Volume otimizado (25%) para não distrair
- ✨ Latência ultra-baixa para resposta instantânea

## 🚀 Uso Básico

### 1. Widgets com Sons Integrados

```dart
import 'package:odyssey/src/shared/widgets/sound_widgets.dart';

// Botão com som
SoundButton(
  onPressed: () => print('clicked'),
  child: Text('Click me'),
)

// TextField com som de digitação (type_01 a type_05 aleatórios)
SoundTextField(
  labelText: 'Nome',
  hintText: 'Digite para ouvir os sons type...',
  onChanged: (value) => print(value),
)

// TextFormField com validação e som de digitação
SoundTextFormField(
  labelText: 'Email',
  validator: (value) {
    if (value?.isEmpty ?? true) return 'Campo obrigatório';
    return null;
  },
  onChanged: (value) => print(value),
)

// Switch com som toggle on/off
SoundSwitch(
  value: isEnabled,
  onChanged: (val) => setState(() => isEnabled = val),
)

// Checkbox com som select
SoundCheckbox(
  value: isChecked,
  onChanged: (val) => setState(() => isChecked = val ?? false),
)

// Card clicável com som tap
SoundCard(
  onTap: () => print('tapped'),
  child: Text('Tap me'),
)
```

### 2. Sons Manuais

```dart
import 'package:odyssey/src/utils/services/sound_service.dart';

// Sons básicos
soundService.playSndButton();      // Botão
soundService.playSndTap();         // Tap aleatório (5 variações)
soundService.playSndSelect();      // Select
soundService.playSndSwipe();       // Swipe aleatório (5 variações)

// Feedback
soundService.playSndNotification(); // Notificação
soundService.playSndCaution();      // Erro/aviso
soundService.playSndCelebration();  // Conquista!

// Loops
await soundService.startSndProgressLoop();  // Inicia loop
await soundService.stopSndProgressLoop();   // Para loop
```

### 3. Helpers para Dialogs/Modals

```dart
import 'package:odyssey/src/utils/sound_helpers.dart';

// Dialog com som automático
showSoundDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Title'),
    content: Text('Content'),
  ),
);

// BottomSheet com som automático
showSoundModalBottomSheet(
  context: context,
  builder: (context) => Container(
    child: Text('Content'),
  ),
);

// SnackBar com som
showSoundSnackBar(context, message: 'Success!');
showErrorSnackBar(context, message: 'Error!');
showSuccessSnackBar(context, message: 'Done!', celebration: true);
```

### 4. Mixin para Facilitar

```dart
class MyWidget extends StatelessWidget with SoundMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => withButtonSound(() {
            // Sua ação aqui
            print('clicked');
          }),
          child: Text('Click'),
        ),
        
        GestureDetector(
          onTap: () => withTapSound(() {
            // Sua ação aqui
          }),
          child: Text('Tap me'),
        ),
      ],
    );
  }
  
  void onSuccess() {
    playSuccessSound();  // Do mixin
  }
  
  void onError() {
    playErrorSound();  // Do mixin
  }
}
```

### 5. Extensions para GestureDetector/InkWell

```dart
import 'package:odyssey/src/utils/sound_helpers.dart';

// GestureDetector com som
SoundGestureDetectorExtension.withTapSound(
  child: Container(child: Text('Tap me')),
  onTap: () => print('tapped'),
)

// InkWell com som
SoundInkWellExtension.withTapSound(
  child: Container(child: Text('Tap me')),
  onTap: () => print('tapped'),
  borderRadius: BorderRadius.circular(8),
)
```

## 🎯 Transições Automáticas

O sistema detecta automaticamente transições de navegação e toca sons apropriados:

### NavigatorObserver
- ✅ **Push/Pop de páginas** → `playSndSwipe()` (transição horizontal)
- ✅ **Abrir Dialog** → `playSndTransitionUp()` (transição hierárquica)
- ✅ **Fechar Dialog** → `playSndTransitionDown()`
- ✅ **Modal Bottom Sheet** → Sons de transição automáticos
- ✅ **Popup Routes** → Sons de transição automáticos

### Como funciona
```dart
// Já configurado no main.dart!
MaterialApp(
  navigatorObservers: [SoundNavigatorObserver()],
  ...
)
```

## 🔧 Configurações

### Ativar/Desativar Sons
```dart
soundService.soundEnabled = false; // Desativa
soundService.soundEnabled = true;  // Ativa
```

### Ajustar Volume
```dart
soundService.volume = 0.5; // 50% (0.0 a 1.0)
```

## 📋 Widgets Disponíveis

### Buttons
- `SoundButton` - ElevatedButton
- `SoundFilledButton` - FilledButton
- `SoundTextButton` - TextButton
- `SoundIconButton` - IconButton
- `SoundFAB` - FloatingActionButton

### Input
- `SoundTextField` - TextField com som de digitação
- `SoundTextFormField` - TextFormField com som de digitação (com validação)
- `SoundCheckbox`, `SoundCheckboxListTile`
- `SoundSwitch`, `SoundSwitchListTile` (toggle on/off)
- `SoundRadio`, `SoundRadioListTile`
- `SoundSlider` - Slider

### Lists & Cards
- `SoundCard` - Card clicável
- `SoundListTile` - ListTile

### Chips
- `SoundChoiceChip` - ChoiceChip
- `SoundFilterChip` - FilterChip

## 🎨 Design Philosophy (SND.dev)

### Sons por Categoria

1. **Button** - Para ações específicas (não feedback genérico)
2. **Tap** - Feedback tátil responsivo (5 variações randômicas)
3. **Select** - Seleção clara (checkbox, radio, form)
4. **Disabled** - Indicador suave de botão inválido
5. **Toggle On/Off** - Grave→Agudo (ON), Agudo→Grave (OFF)
6. **Transition Up/Down** - Transições hierárquicas (modals)
7. **Swipe** - Transições horizontais (páginas)
8. **Type** - Digitação (5 variações randômicas)
9. **Notification** - Notificação genérica
10. **Caution** - Aviso negativo (mais forte que notification)
11. **Celebration** - Momento de conquista máxima
12. **Progress Loop** - Processamento em andamento
13. **Ringtone Loop** - Alarme até ação do usuário

### Variações Aleatórias
Sons repetitivos (tap, swipe, type) têm 5 variações que tocam aleatoriamente para evitar fadiga auditiva.

## 🏗️ Estrutura de Arquivos

```
lib/
├── src/
│   ├── utils/
│   │   ├── services/
│   │   │   └── sound_service.dart       # Service principal (estendido)
│   │   └── sound_helpers.dart           # NavigatorObserver + helpers
│   └── shared/
│       └── widgets/
│           └── sound_widgets.dart       # Widgets com sons
└── main.dart                            # SoundNavigatorObserver configurado

assets/
└── sounds/
    ├── button.wav
    ├── tap_01.wav ... tap_05.wav
    ├── select.wav
    ├── disabled.wav
    ├── toggle_on.wav
    ├── toggle_off.wav
    ├── transition_up.wav
    ├── transition_down.wav
    ├── swipe_01.wav ... swipe_05.wav
    ├── type_01.wav ... type_05.wav
    ├── notification.wav
    ├── caution.wav
    ├── celebration.wav
    ├── progress_loop.wav
    └── ringtone_loop.wav
```

## ✨ Exemplos Práticos

### Exemplo 1: Formulário Completo
```dart
class MyForm extends StatefulWidget {
  @override
  _MyFormState createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> with SoundMixin {
  bool agreedToTerms = false;
  bool enableNotifications = false;
  String selectedOption = 'A';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TextField com som de digitação
        SoundTextField(
          labelText: 'Nome',
          hintText: 'Digite seu nome',
        ),
        
        // Checkbox com som select
        SoundCheckboxListTile(
          value: agreedToTerms,
          onChanged: (val) => setState(() => agreedToTerms = val ?? false),
          title: Text('Aceito os termos'),
        ),
        
        // Switch com toggle on/off
        SoundSwitchListTile(
          value: enableNotifications,
          onChanged: (val) => setState(() => enableNotifications = val),
          title: Text('Notificações'),
        ),
        
        // Radio buttons
        SoundRadioListTile(
          value: 'A',
          groupValue: selectedOption,
          onChanged: (val) => setState(() => selectedOption = val ?? 'A'),
          title: Text('Opção A'),
        ),
        
        // Botão de submit
        SoundFilledButton(
          onPressed: () {
            // Validação...
            playSuccessSound(); // Do mixin
          },
          child: Text('Enviar'),
        ),
      ],
    );
  }
}
```

### Exemplo 2: Lista Interativa
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return SoundCard(
      margin: EdgeInsets.all(8),
      onTap: () {
        // Navegar para detalhe (som de swipe automático)
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DetailPage(),
        ));
      },
      child: ListTile(
        title: Text(items[index].title),
        trailing: SoundIconButton(
          icon: Icon(Icons.delete),
          onPressed: () {
            // Deletar item
            soundService.playSndCaution();
            // ...
          },
        ),
      ),
    );
  },
)
```

### Exemplo 3: Timer com Progress Loop
```dart
class TimerWidget extends StatefulWidget {
  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  bool isRunning = false;

  void startTimer() {
    setState(() => isRunning = true);
    soundService.startSndProgressLoop(); // Inicia loop
    
    Future.delayed(Duration(seconds: 5), () {
      stopTimer();
    });
  }

  void stopTimer() {
    setState(() => isRunning = false);
    soundService.stopSndProgressLoop();  // Para loop
    soundService.playSndCelebration();   // Celebration!
  }

  @override
  Widget build(BuildContext context) {
    return SoundButton(
      onPressed: isRunning ? null : startTimer,
      child: Text(isRunning ? 'Running...' : 'Start'),
    );
  }
  
  @override
  void dispose() {
    soundService.stopSndProgressLoop(); // Cleanup
    super.dispose();
  }
}
```

## 🎯 Benefícios

1. **UX Profissional** - Sons inspirados nos melhores apps (iOS, Material)
2. **Feedback Tátil** - Usuário sente cada interação
3. **Variações Inteligentes** - Evita fadiga auditiva
4. **Fácil Integração** - Widgets drop-in replacement
5. **Transições Automáticas** - NavigatorObserver cuida de tudo
6. **Performance** - Pre-carregamento e cache eficientes
7. **Baixa Latência** - SoLoud garante resposta instantânea

## 📚 Referências

- [SND.dev](https://snd.dev) - Filosofia de design de som UI
- [SND GitHub](https://github.com/snd-lib/snd-lib) - Biblioteca JavaScript original
- SND01_sine - Pack de sons profissionais usado neste projeto

## 🔊 Créditos

Sons: **SND01_sine** (sine wave sound pack)  
Implementação: Sistema Odyssey
Inspiração: [snd.dev](https://snd.dev)

---

**Desenvolvido com ❤️ para proporcionar a melhor experiência UI/UX**
