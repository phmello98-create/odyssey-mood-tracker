# Guia de Configuração Manual - Firebase & Notificações Push

Este guia complementa o `plano_notificacoes_ultrathinking.txt` com as **etapas manuais** necessárias no Firebase Console e outras configurações externas.

---

## 📋 CHECKLIST GERAL

### Pré-requisitos
- [ ] Conta Google/Firebase ativa
- [ ] App já registrado no Firebase (Android + iOS)
- [ ] Acesso ao Firebase Console
- [ ] Acesso ao Google Cloud Console
- [ ] Conta Apple Developer (para iOS)
- [ ] Xcode instalado (para configurar iOS)

---

## 🔧 PARTE 1: CONFIGURAÇÃO INICIAL DO FIREBASE

### 1.1 Criar/Verificar Projeto Firebase

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto existente ou crie um novo:
   - Clique em "Adicionar projeto"
   - Nome: `Odyssey` (ou nome do seu app)
   - Ative Google Analytics (recomendado para A/B testing)
   - Selecione ou crie uma conta Analytics

### 1.2 Ativar Serviços Necessários

No menu lateral do Firebase Console, ative:

**Cloud Messaging (FCM)**
- Menu: `Engajamento` → `Cloud Messaging`
- Não requer configuração adicional, já vem ativo

**Analytics**
- Menu: `Engajamento` → `Analytics`
- Já ativado se você escolheu na criação do projeto

**Remote Config**
- Menu: `Engajamento` → `Remote Config`
- Clique em "Começar"
- Aceite os termos

**Cloud Functions** (se for usar backend)
- Menu: `Criar` → `Functions`
- Clique em "Começar"
- Escolha plano Blaze (pago, mas tem free tier generoso)

---

## 🤖 PARTE 2: CONFIGURAÇÃO ANDROID

### 2.1 Obter SHA-1 e SHA-256

Execute no terminal do projeto:

```bash
cd android
./gradlew signingReport
```

Copie os valores de:
- `SHA-1`
- `SHA-256`

### 2.2 Adicionar SHA no Firebase Console

1. Firebase Console → `Configurações do projeto` (ícone de engrenagem)
2. Aba `Seus apps` → Selecione seu app Android
3. Role até "Impressões digitais de certificado SHA"
4. Clique em "Adicionar impressão digital"
5. Cole o SHA-1 e adicione
6. Repita para SHA-256

### 2.3 Baixar google-services.json Atualizado

1. Após adicionar SHA, clique em "Fazer download do google-services.json"
2. Substitua o arquivo em `android/app/google-services.json`

### 2.4 Verificar Package Name

Certifique-se que o package name no Firebase Console coincide com:
- `android/app/build.gradle` → `applicationId`
- Deve ser algo como: `com.yourcompany.odyssey`

---

## 🍎 PARTE 3: CONFIGURAÇÃO iOS

### 3.1 Obter APNs Authentication Key

1. Acesse [Apple Developer Portal](https://developer.apple.com/account/)
2. Menu: `Certificates, Identifiers & Profiles`
3. `Keys` → Clique no botão `+` para criar uma nova key
4. Nome: `Odyssey Push Notifications`
5. Marque: **Apple Push Notifications service (APNs)**
6. Clique em `Continue` → `Register`
7. **IMPORTANTE**: Baixe o arquivo `.p8` (você só pode baixar UMA vez!)
8. Anote o **Key ID** e **Team ID**

### 3.2 Adicionar APNs Key no Firebase Console

1. Firebase Console → `Configurações do projeto`
2. Aba `Cloud Messaging`
3. Role até "APNs Authentication Key"
4. Clique em "Upload"
5. Preencha:
   - Key ID (da etapa 3.1)
   - Team ID (da etapa 3.1)
   - Faça upload do arquivo `.p8`

### 3.3 Configurar Bundle ID

1. Firebase Console → `Seus apps` → Selecione app iOS
2. Verifique que o Bundle ID coincide com:
   - Xcode → Target → `Bundle Identifier`
   - Deve ser: `com.yourcompany.odyssey` (ou similar)

### 3.4 Configurar Capabilities no Xcode

1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione o target `Runner`
3. Aba `Signing & Capabilities`
4. Clique em `+ Capability` e adicione:
   - **Push Notifications**
   - **Background Modes**
5. Em Background Modes, marque:
   - ✅ Remote notifications
   - ✅ Background fetch

### 3.5 Baixar GoogleService-Info.plist Atualizado

1. Firebase Console → Baixe `GoogleService-Info.plist`
2. Substitua em `ios/Runner/GoogleService-Info.plist`
3. No Xcode, verifique que o arquivo está no target Runner

---

## ☁️ PARTE 4: CLOUD FUNCTIONS (BACKEND)

### 4.1 Instalar Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### 4.2 Inicializar Functions no Projeto

```bash
cd /path/to/projeto
firebase init functions
```

Escolha:
- Linguagem: `TypeScript` ou `JavaScript`
- Use ESLint: Sim
- Install dependencies: Sim

### 4.3 Estrutura de Diretórios

Após init, você terá:
```
functions/
├── src/
│   └── index.ts  (ou index.js)
├── package.json
└── tsconfig.json
```

### 4.4 Configurar Service Account (para enviar notificações)

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione seu projeto Firebase
3. Menu: `IAM & Admin` → `Service Accounts`
4. Clique na service account padrão (ou crie uma nova)
5. Aba `Keys` → `Add Key` → `Create new key`
6. Formato: JSON
7. Baixe o arquivo (guarde com segurança!)
8. **NÃO COMITE ESTE ARQUIVO NO GIT**

Para usar nas Functions:
```bash
firebase functions:config:set serviceaccount.key="$(cat path/to/serviceAccountKey.json)"
```

---

## 🔐 PARTE 5: REMOTE CONFIG (A/B TESTING)

### 5.1 Criar Parâmetros

1. Firebase Console → `Remote Config`
2. Clique em "Adicionar parâmetro"

Parâmetros sugeridos:
```
notification_max_per_hour: 3
enable_timer_notifications: true
enable_streak_notifications: true
notification_variant: "A"  (para A/B testing)
```

### 5.2 Criar Condições para A/B

1. Clique em "Adicionar condição"
2. Nome: `variant_A_users`
3. Aplica-se a: `Random percentile` → `0-50%`
4. Salve

Repita para `variant_B_users` (50-100%)

### 5.3 Publicar Configurações

1. Após adicionar todos os parâmetros
2. Clique em "Publicar alterações"

---

## 📊 PARTE 6: ANALYTICS EVENTS

### 6.1 Eventos Personalizados (Custom Events)

No Firebase Analytics, você pode visualizar eventos personalizados. Configure conversões:

1. Firebase Console → `Analytics` → `Events`
2. Clique em "Mark as conversion" para eventos importantes:
   - `notification_opened`
   - `timer_completed_from_notification`
   - `streak_maintained_via_notification`

### 6.2 Criar Públicos (Audiences)

Para segmentação avançada:

1. Firebase Console → `Analytics` → `Audiences`
2. Exemplos de públicos úteis:
   - **Inactive Users**: Último engagement > 7 dias
   - **Timer Power Users**: `timer_started` > 20 vezes
   - **Notification Engagers**: `notification_opened` > 5 vezes

---

## 🧪 PARTE 7: TESTE DE NOTIFICAÇÕES

### 7.1 Enviar Notificação de Teste via Console

1. Firebase Console → `Cloud Messaging`
2. Clique em "Enviar sua primeira mensagem"
3. Preencha:
   - **Título**: "Teste Push"
   - **Texto**: "Notificação de teste"
4. Clique em "Enviar mensagem de teste"
5. Cole o token FCM do dispositivo (obtido no app via `getToken()`)
6. Clique em "Testar"

### 7.2 Testar com Firebase CLI

Instale a extensão para testes:
```bash
firebase ext:install firebase/firestore-send-email
```

Ou envie via curl:
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_TOKEN",
    "notification": {
      "title": "Test",
      "body": "Test notification"
    },
    "data": {
      "type": "test",
      "action": "open_app"
    }
  }'
```

**SERVER_KEY**: Firebase Console → `Configurações do projeto` → `Cloud Messaging` → "Chave do servidor"

---

## 🚨 PARTE 8: MONITORAMENTO E DEBUGGING

### 8.1 Ativar Debug Mode no Analytics

**Android:**
```bash
adb shell setprop debug.firebase.analytics.app <package_name>
```

**iOS:**
Xcode → Edit Scheme → Arguments → `-FIRDebugEnabled`

### 8.2 Verificar Logs no Console

1. Firebase Console → `Cloud Messaging` → `Relatórios`
2. Monitore:
   - Taxa de entrega
   - Taxa de abertura
   - Falhas de envio

### 8.3 Crashlytics para Erros

1. Firebase Console → `Crashlytics`
2. Verifique crashes relacionados a notificações
3. Filtre por thread: "firebase_messaging"

---

## ⚙️ PARTE 9: PERMISSÕES E COMPLIANCE

### 9.1 Android 13+ (API 33) - Runtime Permission

No código já implementado, mas verifique no `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 9.2 LGPD/GDPR Compliance

1. Implemente tela de consentimento antes de solicitar permissões
2. Armazene preferências do usuário (aceite/rejeitou)
3. Forneça opção de opt-out completo em Settings

### 9.3 Documentação de Privacidade

Atualize a Política de Privacidade para incluir:
- Uso de FCM tokens
- Armazenamento de preferências de notificação
- Compartilhamento de dados com Firebase/Google
- Direito de opt-out

---

## 📱 PARTE 10: OTIMIZAÇÕES OEM (XIAOMI, HUAWEI, ETC.)

### 10.1 Criar Guia In-App

Implemente uma tela educativa para usuários de:
- Xiaomi: Desabilitar otimização de bateria
- Huawei: Adicionar app à lista protegida
- Samsung: Desabilitar "Colocar apps não usados em modo de suspensão"

### 10.2 Detectar Fabricante

```dart
import 'package:device_info_plus/device_info_plus.dart';

final deviceInfo = await DeviceInfoPlugin().androidInfo;
final manufacturer = deviceInfo.manufacturer.toLowerCase();

if (manufacturer.contains('xiaomi') || manufacturer.contains('redmi')) {
  // Mostrar guia específico
}
```

### 10.3 Links Úteis para Guias

- **Don't Kill My App**: https://dontkillmyapp.com/
- Guias por fabricante com screenshots

---

## 🚀 PARTE 11: DEPLOY E ROLLOUT

### 11.1 Deploy Cloud Functions

```bash
cd functions
npm run build  # Se TypeScript
firebase deploy --only functions
```

### 11.2 Rollout Gradual com Remote Config

1. Configure feature flag: `notifications_enabled`
2. Crie condições por percentil: 5% → 25% → 50% → 100%
3. Monitore métricas entre cada etapa

### 11.3 Monitoramento Pós-Deploy

Verifique nas primeiras 24h:
- Taxa de crash
- Taxa de entrega de notificações
- Feedback de usuários
- Consumo de bateria (se disponível via Analytics)

---

## 📚 PARTE 12: RECURSOS E DOCUMENTAÇÃO

### Links Importantes

**Firebase:**
- [FCM Docs](https://firebase.google.com/docs/cloud-messaging)
- [Remote Config](https://firebase.google.com/docs/remote-config)
- [Analytics Events](https://firebase.google.com/docs/analytics/events)

**Flutter Packages:**
- [firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [awesome_notifications](https://pub.dev/packages/awesome_notifications)
- [flutter_foreground_task](https://pub.dev/packages/flutter_foreground_task)

**OEM Issues:**
- [Don't Kill My App](https://dontkillmyapp.com/)

---

## ✅ CHECKLIST FINAL PRÉ-PRODUÇÃO

### Firebase Console
- [ ] SHA-1/SHA-256 adicionados (Android)
- [ ] APNs Key configurado (iOS)
- [ ] Remote Config publicado
- [ ] Analytics events configurados como conversões
- [ ] Cloud Functions deployed (se aplicável)

### App
- [ ] google-services.json atualizado
- [ ] GoogleService-Info.plist atualizado
- [ ] Permissões no AndroidManifest.xml
- [ ] Capabilities no Xcode configuradas
- [ ] Tela de consentimento implementada
- [ ] Settings de notificações implementado

### Testes
- [ ] Notificação de teste enviada e recebida (Android)
- [ ] Notificação de teste enviada e recebida (iOS)
- [ ] App em foreground ✓
- [ ] App em background ✓
- [ ] App killed ✓
- [ ] Após reboot ✓
- [ ] Ações interativas funcionando ✓

### Compliance
- [ ] Política de Privacidade atualizada
- [ ] Consentimento LGPD/GDPR implementado
- [ ] Opt-out disponível

### Monitoramento
- [ ] Crashlytics ativo
- [ ] Analytics dashboard criado
- [ ] Alertas configurados para taxas baixas de entrega

---

## 🆘 TROUBLESHOOTING COMUM

### Notificações não chegam no Android

1. Verifique SHA-1 no Firebase Console
2. Confirme package name correto
3. Teste com notificação do tipo "notification" (não data-only)
4. Verifique permissões no AndroidManifest.xml
5. Para Android 13+, confirme que solicitou POST_NOTIFICATIONS

### Notificações não chegam no iOS

1. Verifique APNs Key no Firebase Console
2. Confirme Bundle ID correto
3. Verifique capabilities no Xcode (Push Notifications + Background Modes)
4. Teste em dispositivo real (simulador não recebe push)
5. Confirme que GoogleService-Info.plist está no target

### Token nulo ou não atualiza

1. Aguarde conexão com internet
2. Em iOS, solicite permissão antes de getToken()
3. Verifique logs: `FirebaseMessaging.instance.onTokenRefresh`
4. Reinstale o app para forçar novo token

### Foreground Service não persiste

1. Verifique se startForeground() foi chamado
2. Confirme notification channel com importância HIGH
3. Adicione WAKE_LOCK e FOREGROUND_SERVICE permissions
4. Teste com usuário desabilitando otimização de bateria

---

## 📞 PRÓXIMOS PASSOS

Após configurar manualmente tudo acima, a IA pode implementar:

1. ✅ **Sprint 1** (código)
   - `firebase_service.dart`
   - `notification_manager.dart`
   - Bridge FCM → Awesome Notifications

2. ✅ **Sprint 2** (código)
   - `foreground_service.dart`
   - `ForegroundTimerService.kt` (Android)
   - `BootReceiver.kt`

3. ✅ **Sprint 3** (código)
   - `notification_analytics.dart`
   - `notification_rules.dart`
   - UI de settings

4. ✅ **Sprint 4** (validação)
   - Testes automatizados
   - QA em devices reais

**Importante**: Mantenha este guia atualizado conforme o projeto evolui e documente quaisquer edge cases específicos do Odyssey!

---

**Última atualização**: 2025-12-10
**Versão**: 1.0
**Autor**: Guia complementar ao plano_notificacoes_ultrathinking.txt
