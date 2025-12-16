# Configuração do FCM Token para Testes

## ✅ O que foi feito

### 1. Criado `lib/firebase_options.dart`
- Arquivo de configuração do Firebase baseado no `google-services.json`
- Suporta apenas Android (plataforma principal do app)

### 2. Atualizado `FirebaseService`
- Agora usa `DefaultFirebaseOptions.currentPlatform` para inicializar
- Suporte adequado para múltiplas plataformas

### 3. Atualizado `AppInitializer`
- Adicionado `_initFirebase()` para inicializar o Firebase durante o splash
- O FCM Token agora é obtido automaticamente no início do app
- Log com emoji destacado: `✅ FCM Token obtido: ...`

### 4. Criada tela de debug `FCMTokenDebugScreen`
- Interface amigável para visualizar e copiar o FCM Token
- Instruções passo-a-passo de como testar no Firebase Console
- Status visual (inicializado, obtendo token, sucesso)

### 5. Adicionada seção "Debug" nas Configurações
- Nova seção "Debug / Desenvolvimento" (apenas no Android)
- Item "FCM Token Debug" com ícone roxo de desenvolvedor
- Acesso rápido à tela de debug

## 📱 Como usar

### Opção 1: Ver no log do console
1. Execute o app no Android
2. Procure no console por: `✅ FCM Token obtido:`
3. Copie o token que aparece depois

### Opção 2: Via interface gráfica (RECOMENDADO)
1. Execute o app no Android
2. Vá em **Mais** → **Configurações**
3. Role até a seção **Debug / Desenvolvimento**
4. Clique em **FCM Token Debug**
5. Clique no botão **Copiar Token**
6. O token é copiado automaticamente para a área de transferência

## 🧪 Como testar notificações no Firebase Console

1. Acesse: https://console.firebase.google.com/
2. Selecione o projeto: **odyssey-7d931**
3. No menu lateral, clique em **Cloud Messaging**
4. Clique em **Send your first message** ou **New campaign**
5. Escreva o título e a mensagem
6. Clique em **Send test message**
7. Cole o FCM Token no campo **Add an FCM registration token**
8. Clique em **Test**
9. A notificação deve aparecer no seu dispositivo Android!

## ⚠️ Observações

- O Firebase **não funciona no Linux/Desktop** - isso é esperado
- Você deve rodar o app em um **dispositivo Android** ou **emulador Android**
- O erro "Unable to establish connection on channel" no Linux é normal e pode ser ignorado
- O app continua funcionando normalmente no Linux, apenas sem push notifications

## 🔍 Problemas?

Se o token não aparecer:
1. Verifique se está rodando no Android (não Linux)
2. Verifique se o `google-services.json` está em `android/app/`
3. Verifique as permissões de notificação do Android
4. Tente rebuild: `flutter clean && flutter pub get && flutter run`

## 📝 Arquivos modificados

- ✅ `lib/firebase_options.dart` (criado)
- ✅ `lib/src/providers/app_initializer_provider.dart` (adicionado init do Firebase)
- ✅ `lib/src/utils/services/firebase_service.dart` (usa firebase_options)
- ✅ `lib/src/features/settings/presentation/fcm_token_debug_screen.dart` (criado)
- ✅ `lib/src/features/settings/presentation/settings_screen.dart` (adicionada seção debug)
- ✅ `lib/src/utils/widgets/fcm_token_debug_widget.dart` (widget reutilizável)

