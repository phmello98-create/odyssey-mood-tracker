# 🔧 Como Consertar o Erro "Erro ao login com Google"

## 🔍 Problema Identificado

O arquivo `google-services.json` está sem as configurações OAuth necessárias. O campo `oauth_client` está vazio:

```json
"oauth_client": [],  // ❌ VAZIO - Falta configuração!
```

---

## ✅ Solução Passo a Passo

### 1️⃣ Acesse o Firebase Console

1. Vá para: https://console.firebase.google.com/
2. Selecione o projeto **odyssey-7d931**
3. No menu lateral, vá em **Autenticação** (Authentication)

### 2️⃣ Ative o Google Sign-In no Firebase

1. Na aba **Sign-in method** (Método de login)
2. Clique em **Google** na lista de provedores
3. Ative o switch **Ativar/Habilitar**
4. Preencha:
   - **Nome público do projeto**: Odyssey (ou o nome que preferir)
   - **Email de suporte**: seu email
5. Clique em **Salvar**

### 3️⃣ Configure o SHA-1 do seu App

O Google Sign-In precisa do SHA-1 fingerprint da sua chave de assinatura.

**No terminal, execute:**

```bash
cd android
./gradlew signingReport
```

Você verá algo assim:

```
Variant: debug
Config: debug
Store: /caminho/android/app/odyssey-key.jks
Alias: odyssey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA-256: ...
```

**Copie o valor do SHA1** (os 20 pares de caracteres separados por `:`)

### 4️⃣ Adicione o SHA-1 no Firebase

1. No Firebase Console, vá em **Configurações do projeto** (⚙️ no canto superior esquerdo)
2. Role até a seção **Seus apps**
3. Clique no app Android **com.example.odyssey**
4. Em **SHA certificate fingerprints**, clique em **Add fingerprint**
5. Cole o **SHA-1** que você copiou
6. Clique em **Salvar**

### 5️⃣ Baixe o novo google-services.json

1. Ainda nas **Configurações do projeto**
2. No card do seu app Android, clique em **google-services.json** para baixar
3. **Substitua** o arquivo em: `android/app/google-services.json`

O novo arquivo deve conter algo assim:

```json
{
  "oauth_client": [
    {
      "client_id": "742719498764-XXXXXXXXXX.apps.googleusercontent.com",
      "client_type": 3
    }
  ],
  ...
}
```

✅ Agora o campo `oauth_client` **NÃO** está mais vazio!

### 6️⃣ Limpe o build e rode novamente

```bash
flutter clean
flutter pub get
flutter run
```

---

## 🔍 Verificação Adicional

### Confira o AndroidManifest.xml

Certifique-se que o arquivo `android/app/src/main/AndroidManifest.xml` tem as permissões de internet:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Confira o build.gradle

O arquivo `android/build.gradle` deve ter:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

E o `android/app/build.gradle` deve ter no topo:

```gradle
plugins {
    id "com.google.gms.google-services"
}
```

✅ Esses já estão configurados no seu projeto!

---

## 🎯 Teste Final

Depois de seguir todos os passos:

1. Rode o app: `flutter run`
2. Clique em **Continuar com Google**
3. O seletor de contas do Google deve aparecer
4. Selecione sua conta
5. ✅ Login bem-sucedido!

---

## ❓ Problemas Comuns

### "PlatformException(sign_in_failed)"

- Verifique se adicionou o SHA-1 correto
- Aguarde 5-10 minutos após adicionar o SHA-1 (propagação do Google)
- Baixe novamente o `google-services.json` atualizado

### "ApiException: 10"

- SHA-1 não configurado ou incorreto
- Baixe novamente o `google-services.json` após adicionar SHA-1

### "Erro ao login com Google" (genérico)

- Verifique logs detalhados com: `flutter run --verbose`
- Certifique-se que ativou o Google Sign-In no Firebase Authentication

---

## 📱 Testando em Dispositivo Real vs Emulador

- **Emulador**: Use o SHA-1 da chave de **debug**
- **Dispositivo físico**: Pode precisar do SHA-1 da chave de **release**
- Se for publicar na Play Store, adicione também o SHA-1 da Play Store (disponível no Play Console)

---

## 🛠️ Comandos Úteis

```bash
# Ver SHA-1 de todas as variantes
cd android && ./gradlew signingReport

# Limpar build
flutter clean

# Rodar com logs detalhados
flutter run --verbose

# Ver logs do Android
flutter logs
```

---

**Após seguir esses passos, o login com Google deve funcionar perfeitamente! 🎉**
