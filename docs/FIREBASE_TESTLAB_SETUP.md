# 🧪 Firebase Test Lab & App Distribution - Setup Guide

Este guia explica como configurar o Firebase Test Lab e App Distribution para o Odyssey.

---

## 📋 Pré-requisitos

### CLIs Instalados ✅
- **Firebase CLI 15.1.0** → `~/.local/bin/firebase`
- **Google Cloud CLI 550.0.0** → `~/.local/google-cloud-sdk/bin/gcloud`

### Para adicionar ao PATH (opcional)
```bash
# Adicione ao seu ~/.zshrc ou ~/.bashrc:
export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"
```

---

## 🔐 Step 1: Login e Autenticação

Execute o script de setup:
```bash
./scripts/firebase-setup.sh
```

Ou manualmente:
```bash
# Login Firebase
~/.local/bin/firebase login

# Login Google Cloud
~/.local/google-cloud-sdk/bin/gcloud auth login

# Listar projetos
~/.local/bin/firebase projects:list

# Vincular ao projeto
~/.local/bin/firebase use <PROJECT_ID>
~/.local/google-cloud-sdk/bin/gcloud config set project <PROJECT_ID>
```

---

## 🧪 Step 2: Test Lab - Robo Test

### Rodar manualmente
```bash
# 1. Build APK
flutter build apk --debug

# 2. Rodar Robo Test
~/.local/google-cloud-sdk/bin/gcloud firebase test android run \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --type robo \
  --device model=oriole,version=33,locale=pt_BR \
  --device model=redfin,version=30,locale=pt_BR \
  --timeout 300s
```

### Devices Recomendados
| Device | Model ID | Android | Categoria |
|--------|----------|---------|-----------|
| Pixel 6 | oriole | 33 | High-end |
| Pixel 5 | redfin | 30 | Mid-range |
| Pixel 6a | bluejay | 32 | Mid-range |
| Samsung S21 | x1q | 31 | Popular BR |
| Moto G Power | sofia | 30 | Budget |

### Listar todos os devices disponíveis
```bash
~/.local/google-cloud-sdk/bin/gcloud firebase test android models list
```

---

## 📱 Step 3: App Distribution

### Configurar grupos de testers
1. Acesse: https://console.firebase.google.com/project/YOUR_PROJECT/appdistribution
2. Clique em "Testers & Groups"
3. Crie grupo: `internal-testers`
4. Adicione emails dos beta testers

### Distribuir manualmente
```bash
# 1. Build release APK
flutter build apk --release

# 2. Upload para App Distribution
~/.local/bin/firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups internal-testers \
  --release-notes "Nova versão com correções"
```

---

## 🤖 Step 4: CI/CD com GitHub Actions

### Secrets necessários no GitHub

Vá em: `Settings > Secrets and variables > Actions`

| Secret | Descrição | Como obter |
|--------|-----------|------------|
| `FIREBASE_PROJECT_ID` | ID do projeto Firebase | Console Firebase |
| `FIREBASE_APP_ID` | App ID do Android | Firebase > Project Settings > Your Apps |
| `GCLOUD_SERVICE_ACCOUNT_KEY` | JSON da service account | Ver abaixo |
| `ANDROID_KEYSTORE_BASE64` | Keystore codificado | `base64 -w0 odyssey-key.jks` |
| `KEYSTORE_PASSWORD` | Senha do keystore | Sua senha |
| `KEY_ALIAS` | Alias da key | Geralmente `upload` |
| `KEY_PASSWORD` | Senha da key | Sua senha |

### Criar Service Account
```bash
# 1. Criar service account
gcloud iam service-accounts create odyssey-ci \
  --display-name="Odyssey CI/CD"

# 2. Dar permissões
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:odyssey-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/firebase.sdkAdminServiceAgent"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:odyssey-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/cloudtestservice.testAdmin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:odyssey-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/firebaseappdistro.admin"

# 3. Gerar chave JSON
gcloud iam service-accounts keys create ./service-account.json \
  --iam-account=odyssey-ci@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 4. Copiar conteúdo para secret GCLOUD_SERVICE_ACCOUNT_KEY
cat ./service-account.json
```

---

## 📊 Step 5: Visualizar Resultados

### Test Lab
```
https://console.firebase.google.com/project/YOUR_PROJECT/testlab/histories
```

### App Distribution
```
https://console.firebase.google.com/project/YOUR_PROJECT/appdistribution
```

---

## 💰 Custos

### Test Lab (Plano Gratuito)
- **10 testes/dia** no plano Spark (grátis)
- Dispositivos virtuais: grátis
- Dispositivos físicos: 10/dia grátis

### App Distribution
- **Totalmente grátis**
- Sem limites de downloads
- Até 200 testers por grupo

---

## 🚀 Quick Commands

```bash
# Atalhos úteis (adicione ao ~/.zshrc)
alias firebase='~/.local/bin/firebase'
alias gcloud='~/.local/google-cloud-sdk/bin/gcloud'

# Rodar Robo Test rápido
alias testlab='flutter build apk --debug && gcloud firebase test android run --app build/app/outputs/flutter-apk/app-debug.apk --type robo --device model=oriole,version=33 --timeout 300s'

# Distribuir beta
alias distribute='flutter build apk --release && firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app $FIREBASE_APP_ID --groups internal-testers'
```

---

## 📝 Workflows Criados

| Arquivo | Trigger | Descrição |
|---------|---------|-----------|
| `.github/workflows/test-lab.yml` | Push main/develop, PRs | Robo Test automático |
| `.github/workflows/app-distribution.yml` | Release, Manual | Distribuição para testers |

---

## 🐛 Troubleshooting

### "API not enabled"
```bash
gcloud services enable testing.googleapis.com
gcloud services enable toolresults.googleapis.com
gcloud services enable firebaseappdistribution.googleapis.com
```

### "Permission denied"
Verifique se a service account tem as roles corretas:
- `roles/firebase.sdkAdminServiceAgent`
- `roles/cloudtestservice.testAdmin`
- `roles/firebaseappdistro.admin`

### "No devices available"
```bash
# Listar devices disponíveis
gcloud firebase test android models list --filter="form=PHYSICAL"
```

---

**Última atualização:** 2025-12-22
