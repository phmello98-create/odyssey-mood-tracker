# 🔧 Configuração do Firebase para Novo Package ID

## Resumo da Mudança

O Application ID foi alterado de:
- **Antigo:** `com.example.odyssey`
- **Novo:** `io.odyssey.moodtracker`

## ⚠️ AÇÃO NECESSÁRIA NO FIREBASE CONSOLE

O arquivo `google-services.json` foi atualizado **temporariamente** localmente, mas você precisa **registrar o novo app no Firebase Console** para que tudo funcione corretamente (especialmente Google Sign-In e FCM).

### Passo a Passo:

1. **Acesse o Firebase Console**
   - https://console.firebase.google.com/
   - Selecione o projeto `odyssey-7d931`

2. **Adicione um Novo App Android**
   - Clique em ⚙️ (Configurações do Projeto) → **Configurações do projeto**
   - Vá em **Seus apps** → Clique em **+ Adicionar app** → Escolha **Android**
   - **Package name:** `io.odyssey.moodtracker`
   - **App nickname:** Odyssey
   - Clique em **Registrar app**

3. **Baixe o Novo google-services.json**
   - Após registrar, clique em **Baixar google-services.json**
   - Substitua o arquivo em: `android/app/google-services.json`

4. **Configure o SHA-1 para Google Sign-In**
   - Ainda em Configurações do projeto → Seus apps → Android
   - Clique no app `io.odyssey.moodtracker`
   - Adicione a impressão digital SHA-1:
   
   **SHA-1 da keystore Odyssey:**
   ```
   EC:3C:CA:8B:06:62:CB:BC:FB:3E:C7:4D:8D:00:00:CF:0E:CA:B9:05
   ```
   
   **SHA-256:**
   ```
   0D:25:91:CD:51:58:93:27:1E:18:E9:A2:83:9D:A8:DD:A6:5D:09:D9:19:AF:57:C5:5C:01:3A:C9:71:DE:97:77
   ```

5. **Atualize o OAuth Client ID (se usar Google Sign-In)**
   - Vá para https://console.cloud.google.com/
   - APIs e Serviços → Credenciais
   - Adicione o novo package ID nas credenciais OAuth 2.0

## 📋 Arquivos Alterados

| Arquivo | Alteração |
|---------|-----------|
| `android/app/build.gradle` | `applicationId` e `namespace` → `io.odyssey.moodtracker`, `minifyEnabled` e `shrinkResources` → `true` |
| `android/app/src/main/AndroidManifest.xml` | `package` → `io.odyssey.moodtracker` |
| `android/app/src/debug/AndroidManifest.xml` | `package` → `io.odyssey.moodtracker` |
| `android/app/src/profile/AndroidManifest.xml` | `package` → `io.odyssey.moodtracker` |
| `android/app/proguard-rules.pro` | `-keep class io.odyssey.moodtracker.**` |
| `android/app/google-services.json` | `package_name` → `io.odyssey.moodtracker` (temporário) |
| `lib/src/utils/services/foreground_service.dart` | MethodChannel → `io.odyssey.moodtracker/foreground_service` |
| `android/app/src/main/kotlin/io/odyssey/moodtracker/*.kt` | Novos arquivos com package atualizado |

## ✅ Benefícios da Mudança

1. **Pronto para Play Store** - Package ID profissional aceito pelo Google
2. **Ofuscamento Ativo** - Código protegido em builds de release
3. **Nome Memorável** - `io.odyssey.moodtracker` é limpo e profissional

## 🧪 Testando

Após configurar o Firebase, execute:

```bash
flutter clean
flutter pub get
flutter run
```

Se houver erros de ProGuard durante o build release, adicione regras em `android/app/proguard-rules.pro`.

---
**Data:** 2025-12-21
**Versão:** 1.0.0+2002
