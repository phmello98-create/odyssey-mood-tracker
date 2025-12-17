# 🤖 Como Rodar o App no Android (sem buildar APK)

Você tem **3 opções** para testar o app no Android e ver o FCM Token:

## ✅ Opção 1: Usar ADB + Celular via USB (MAIS RÁPIDO)

### Pré-requisitos:
- Celular Android com **cabo USB**
- **Depuração USB** ativada no celular

### Passos:

1. **Ativar Depuração USB no celular:**
   ```
   Configurações → Sobre o telefone → Toque 7x em "Número da versão"
   Configurações → Opções do desenvolvedor → Ativar "Depuração USB"
   ```

2. **Conectar celular via USB** e aceitar a permissão de depuração

3. **Verificar se o celular está conectado:**
   ```bash
   ~/flutter/bin/flutter devices
   ```
   Você deve ver algo como: `SM-G975F (mobile) • ... • android`

4. **Rodar o app direto no celular:**
   ```bash
   cd "/home/agyspc1/Documentos/app com opus 4.5 copia atual"
   ~/flutter/bin/flutter run
   ```

5. **Ver o FCM Token:**
   - No console, procure: `✅ FCM Token obtido:`
   - Ou no app: Mais → Configurações → Debug → FCM Token Debug

---

## 🌐 Opção 2: Usar ADB + Celular via Wi-Fi (SEM CABO)

### Pré-requisitos:
- Celular e PC na **mesma rede Wi-Fi**
- ADB Wireless ativado (Android 11+)

### Passos:

1. **No celular:**
   ```
   Configurações → Opções do desenvolvedor → Depuração sem fio
   Anote o IP e porta (ex: 192.168.1.100:5555)
   ```

2. **Conectar via Wi-Fi:**
   ```bash
   # Substitua pelo IP do seu celular
   adb connect 192.168.1.100:5555
   
   # Verificar conexão
   ~/flutter/bin/flutter devices
   ```

3. **Rodar o app:**
   ```bash
   cd "/home/agyspc1/Documentos/app com opus 4.5 copia atual"
   ~/flutter/bin/flutter run
   ```

---

## 🖥️ Opção 3: Criar Emulador Android (SEM CELULAR)

### Pré-requisitos:
- Android SDK completo instalado
- Virtualização habilitada no BIOS (Intel VT-x ou AMD-V)
- Pelo menos 8GB de RAM livre

### Passos:

1. **Instalar componentes necessários:**
   ```bash
   export ANDROID_SDK_ROOT=/opt/android-sdk
   
   # Instalar emulator, platform-tools e system image
   sudo $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager \
     "emulator" \
     "platform-tools" \
     "platforms;android-34" \
     "system-images;android-34;google_apis_playstore;x86_64"
   ```

2. **Criar emulador:**
   ```bash
   $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager create avd \
     --name "Pixel_7_API_34" \
     --package "system-images;android-34;google_apis_playstore;x86_64" \
     --device "pixel_7"
   ```

3. **Iniciar emulador:**
   ```bash
   $ANDROID_SDK_ROOT/emulator/emulator -avd Pixel_7_API_34
   ```

4. **Em outro terminal, rodar o app:**
   ```bash
   cd "/home/agyspc1/Documentos/app com opus 4.5 copia atual"
   ~/flutter/bin/flutter run
   ```

---

## 🚀 Recomendação: Use a Opção 1 (USB)

É a **mais rápida e simples**:
- Não precisa instalar nada pesado
- Performance nativa do celular
- Conecta em segundos

### Script rápido para USB:

```bash
#!/bin/bash
cd "/home/agyspc1/Documentos/app com opus 4.5 copia atual"

echo "🔍 Procurando dispositivos..."
~/flutter/bin/flutter devices

echo ""
echo "📱 Se o celular apareceu acima, rodando o app..."
~/flutter/bin/flutter run
```

---

## 🔍 Verificar se está funcionando:

Após rodar `flutter run`, procure no console:

```
✅ FCM Token obtido: dABC123...xyz
🔑 Use este token no Firebase Console para testar notificações!
```

Ou abra no app: **Mais → Configurações → Debug / Desenvolvimento → FCM Token Debug**

---

## ⚠️ Troubleshooting

### "No devices found"
- Verifique se a depuração USB está ativada
- Tente `adb kill-server && adb start-server`
- Desconecte e reconecte o cabo USB
- Tente outro cabo USB (alguns são só para carregamento)

### "Device unauthorized"
- Aceite a permissão de depuração que aparece no celular
- Se não aparecer, desative e reative a depuração USB

### Emulador muito lento
- Certifique-se de que a virtualização está habilitada no BIOS
- Use uma system image x86_64 (não ARM)
- Aumente a RAM do emulador: `emulator -avd Nome_AVD -memory 4096`

---

## 📝 Comandos úteis

```bash
# Ver dispositivos conectados
~/flutter/bin/flutter devices

# Listar emuladores
~/flutter/bin/flutter emulators

# Ver logs em tempo real
~/flutter/bin/flutter logs

# Hot reload (sem reiniciar)
# Dentro do flutter run, pressione 'r'

# Hot restart (reinicia o app)
# Dentro do flutter run, pressione 'R'
```
