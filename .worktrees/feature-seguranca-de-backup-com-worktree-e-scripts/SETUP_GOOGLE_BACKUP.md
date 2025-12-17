# 🔐 Configuração do Google Sign In para Backup

## Passo 1: Criar Projeto no Google Cloud Console

1. Acesse [console.cloud.google.com](https://console.cloud.google.com/)
2. No topo, clique no seletor de projeto (pode estar escrito "Selecionar projeto")
3. Clique em **"Novo Projeto"**
4. Nome: `Odyssey App` (ou qualquer nome)
5. Clique em **"Criar"**
6. Aguarde criar e selecione o projeto criado

## Passo 2: Habilitar Google Drive API

1. No menu lateral esquerdo (☰), vá em **"APIs e Serviços"** → **"Biblioteca"**
2. Na busca, digite "Google Drive API"
3. Clique em **"Google Drive API"**
4. Clique no botão azul **"ATIVAR"**

## Passo 3: Configurar Tela de Consentimento OAuth

1. No menu lateral, vá em **"APIs e Serviços"** → **"Tela de permissão OAuth"**
2. Selecione **"Externo"** (permite qualquer conta Google)
3. Clique **"Criar"**
4. Preencha os campos obrigatórios:
   - **Nome do app**: `Odyssey`
   - **E-mail para suporte do usuário**: seu email
   - **Logotipo do app**: (opcional, pode pular)
   - Role até o final e preencha **"E-mails de contato do desenvolvedor"**: seu email
5. Clique **"Salvar e continuar"**

### Escopos (Scopes)
6. Na tela de Escopos, clique em **"Adicionar ou remover escopos"**
7. Na busca, digite `drive.file`
8. Marque a opção: `../auth/drive.file` - "Ver e gerenciar arquivos do Google Drive criados por este app"
9. Clique **"Atualizar"**
10. Clique **"Salvar e continuar"**

### Usuários de Teste
11. Clique em **"Add Users"** (Adicionar usuários)
12. Adicione seu próprio email Google
13. Clique **"Salvar e continuar"**
14. Clique **"Voltar ao painel"**

## Passo 4: Criar Credenciais OAuth (Android)

### 4.1 Obter SHA-1 do certificado de debug

Abra o terminal na pasta do projeto e rode:

```bash
cd android
./gradlew signingReport
```

Procure por `SHA1` na seção `debug`. Vai ser algo tipo:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Copie esse valor!**

### 4.2 Criar OAuth Client ID no Google Cloud

1. No menu lateral, vá em **"APIs e Serviços"** → **"Credenciais"**
2. Clique em **"+ Criar Credenciais"** → **"ID do cliente OAuth"**
3. **Tipo de aplicativo**: selecione **"Android"**
4. **Nome**: `Odyssey Android Debug`
5. **Nome do pacote**: `com.example.odyssey`
   - (Verifique em `android/app/build.gradle` o `applicationId`)
6. **Impressão digital do certificado SHA-1**: Cole o SHA-1 que você copiou
7. Clique **"Criar"**

Pronto! Uma janela vai aparecer com suas credenciais. Pode fechar.

## Passo 5: Testar no App

1. Rode o app no celular/emulador Android:
   ```bash
   flutter run
   ```
2. Vá em **Configurações** → **Backup**
3. Clique em **"Entrar"**
4. Faça login com a conta Google que você adicionou como usuário de teste
5. Teste fazer backup e restaurar!

---

## ⚠️ Importante

- O backup usa o escopo `drive.file` que **só acessa arquivos criados pelo app**
- **Não acessa** outros arquivos do Google Drive do usuário
- É **100% gratuito** (limite de 15GB por conta Google)
- Os dados ficam em uma pasta chamada "Odyssey Backup" no Drive

## 🔧 Problemas Comuns

### Erro "DEVELOPER_ERROR" ou "12500"
- O SHA-1 está errado - verifique se copiou corretamente
- O package name está errado - deve ser exatamente `com.example.odyssey`
- Limpe o cache: `flutter clean && flutter pub get`

### Erro "sign_in_failed" ou "10"
- A conta Google não está nos usuários de teste
- Adicione seu email na seção "Usuários de teste" do OAuth

### Erro "Network error"
- Verifique sua conexão com internet
- Pode ser problema temporário do Google

### Não aparece a tela de login
- No Linux/Desktop o Google Sign In não funciona
- Teste apenas em Android ou iOS

---

## 📱 Para Publicar na Play Store

Quando for publicar o app:

1. Crie uma keystore de release
2. Gere o SHA-1 da keystore de release
3. Crie outro OAuth Client ID com o SHA-1 de release
4. No Google Play Console, adicione os SHA-1 do App Signing
