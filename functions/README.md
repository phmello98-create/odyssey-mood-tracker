# 🤖 Odyssey Bot Functions

Sistema de bots inteligentes para a comunidade Odyssey.

## Setup Rápido

### 1. Instalar dependências
```bash
cd functions
npm install
```

### 2. Configurar API Keys

**Gemini (gratuito):**
1. Acesse https://aistudio.google.com/app/apikey
2. Crie uma API Key
3. Configure no Firebase:
```bash
firebase functions:config:set gemini.api_key="YOUR_KEY"
```

**HuggingFace (gratuito):**
1. Acesse https://huggingface.co/settings/tokens
2. Crie um token (Read)
3. Configure:
```bash
firebase functions:config:set huggingface.api_key="YOUR_TOKEN"
```

### 3. Build e Deploy
```bash
npm run build
firebase deploy --only functions
```

### 4. Seed inicial (uma vez)
```bash
npx ts-node src/scripts/seedBotConfig.ts
```

## Estrutura

```
functions/
├── src/
│   ├── index.ts              # Entry point
│   ├── config/
│   │   └── constants.ts      # Configurações e rate limits
│   ├── bots/
│   │   └── botPersonalities.ts  # Personalidades dos 4 bots
│   ├── ai/
│   │   └── aiService.ts      # Gemini + HuggingFace + fallback
│   ├── triggers/
│   │   ├── scheduledPosts.ts # Cron a cada 4h
│   │   ├── onNewPost.ts      # Responder a posts
│   │   └── checkInactivity.ts # Quebrar gelo
│   ├── http/
│   │   └── testEndpoints.ts  # Testes manuais
│   └── scripts/
│       └── seedBotConfig.ts  # Setup inicial
├── package.json
├── tsconfig.json
└── .env.example
```

## Os 4 Bots

| Bot | Emoji | Função | Personalidade |
|-----|-------|--------|---------------|
| **Beatnix** | 🎧 | Música | Tranquilo, DJ de Lofi |
| **Erro 404** | 🤖 | Humor | Sarcástico, bugs existenciais |
| **Wiki** | 🧠 | Curiosidades | Curioso, professor descolado |
| **Turbo** | ⚡ | Gamificação | Enérgico, coach divertido |

## Testar localmente

```bash
# Emular functions
npm run serve

# Testar endpoint
curl "http://localhost:5001/PROJECT/us-central1/testBotPost?botId=bot_beatnix&dryRun=true"
```

## Limites (Free Tier)

| Serviço | Limite |
|---------|--------|
| Gemini Flash | 1.500 req/dia |
| HuggingFace | 300 req/hora |
| Firebase Functions | 2M invocações/mês |

## Logs

```bash
firebase functions:log
```
