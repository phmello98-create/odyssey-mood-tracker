# Localização / Internationalization

Este documento descreve como a localização funciona no app Odyssey.

## Idiomas Suportados

- 🇧🇷 **Português (pt_BR)** - Idioma primário
- 🇺🇸 **English (en_US)** - Inglês americano

## Estrutura de Arquivos

```
lib/src/localization/
├── app_en.arb           # Template - Strings em inglês
├── app_pt.arb           # Traduções em português
├── app_localizations.dart        # Gerado automaticamente
├── app_localizations_en.dart     # Gerado automaticamente
└── app_localizations_pt.dart     # Gerado automaticamente
```

## Configuração

### l10n.yaml

```yaml
arb-dir: lib/src/localization
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/src/localization
```

## Como Usar

### 1. Importar AppLocalizations

```dart
import 'package:odyssey/src/localization/app_localizations.dart';
```

### 2. Usar strings localizadas

```dart
// Em qualquer widget com BuildContext:
Text(AppLocalizations.of(context)!.appTitle)
Text(AppLocalizations.of(context)!.settings)
Text(AppLocalizations.of(context)!.taskCompleted)

// Com placeholders:
Text(AppLocalizations.of(context)!.tasksCompleted(3, 10))
// Output: "3 de 10 tarefas concluídas" (pt) ou "3 of 10 tasks completed" (en)
```

### 3. Adicionar novas strings

1. Adicione a chave no `app_en.arb` (template):
```json
{
  "myNewString": "My new string",
  "@myNewString": {
    "description": "Description of the string"
  }
}
```

2. Adicione a tradução no `app_pt.arb`:
```json
{
  "myNewString": "Minha nova string"
}
```

3. Gere os arquivos:
```bash
flutter gen-l10n
```

### 4. Strings com parâmetros (placeholders)

```json
// app_en.arb
{
  "notifHabitsPendingTitle": "{count} pending habits",
  "@notifHabitsPendingTitle": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
}

// app_pt.arb
{
  "notifHabitsPendingTitle": "{count} hábitos pendentes"
}
```

Uso:
```dart
AppLocalizations.of(context)!.notifHabitsPendingTitle(5)
```

## LocaleProvider

O `LocaleNotifier` gerencia o idioma do app com suporte a:

### Seguir idioma do sistema
```dart
ref.read(localeStateProvider.notifier).setFollowSystem(true);
```

### Definir idioma manualmente
```dart
ref.read(localeStateProvider.notifier).setLocale(const Locale('en', 'US'));
```

### Verificar estado atual
```dart
final state = ref.watch(localeStateProvider);
print(state.followSystem);        // true/false
print(state.currentLocale);       // Locale('pt', 'BR')
```

## Notificações Localizadas

As strings de notificação estão definidas nos ARBs:

- `notifMoodMorningTitle` / `notifMoodMorningBody`
- `notifMoodEveningTitle` / `notifMoodEveningBody`
- `notifHabitsPendingTitle` / `notifHabitsPendingBody`
- `notifTasksPendingTitle` / `notifTasksPendingBody`
- `notifPomodoroCompleteTitle` / `notifPomodoroCompleteBody`
- `notifStreakAlertTitle` / `notifStreakAlertBody`

## Atividades do Timer

IDs estáveis para atividades:

| ID | Chave ARB | PT | EN |
|----|-----------|----|----|
| work | activityWork | Trabalho | Work |
| study | activityStudy | Estudo | Study |
| reading | activityReading | Leitura | Reading |
| exercise | activityExercise | Exercício | Exercise |
| meditation | activityMeditation | Meditação | Meditation |
| creative | activityCreative | Criativo | Creative |
| coding | activityCoding | Programação | Coding |
| writing | activityWriting | Escrita | Writing |
| planning | activityPlanning | Planejamento | Planning |
| meeting | activityMeeting | Reunião | Meeting |
| other | activityOther | Outro | Other |

## Comandos Úteis

```bash
# Gerar arquivos de localização
flutter gen-l10n

# Verificar erros
flutter analyze

# Limpar e regenerar
flutter clean && flutter pub get && flutter gen-l10n
```

## Configuração no Settings

O usuário pode alterar o idioma em:
**Mais → Configurações → Idioma**

Opções:
- ✅ Seguir idioma do sistema
- 🇧🇷 Português (BR)
- 🇺🇸 English (US)

## Troubleshooting

### Strings não atualizando
1. Rode `flutter gen-l10n`
2. Reinicie o app (hot restart não regenera localizações)

### Erro "AppLocalizations.of(context) is null"
- Verifique se o widget está abaixo do MaterialApp
- Use `AppLocalizations.of(context)!` com null-assertion apenas se tiver certeza

### Chave faltando no ARB
- O `app_en.arb` é o template - toda chave DEVE existir lá
- O `app_pt.arb` pode ter chaves faltando (usará o fallback em inglês)
