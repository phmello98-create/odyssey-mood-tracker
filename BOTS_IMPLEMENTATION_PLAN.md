# 🤖 SISTEMA DE BOTS INTELIGENTES - ODYSSEY COMMUNITY

**Status:** 📋 Planejamento Completo  
**Objetivo:** Criar bots que "ambientam" a comunidade, geram engajamento e mantêm o feed ativo  
**Abordagem:** Gemini + HuggingFace com fallback automático + Templates estáticos

---

## 📋 ÍNDICE

1. [Visão Geral](#1-visão-geral)
2. [Arquitetura do Sistema](#2-arquitetura-do-sistema)
3. [Os 4 Bots - Identidade e Personalidade](#3-os-4-bots---identidade-e-personalidade)
4. [Estrutura de Dados (Firestore)](#4-estrutura-de-dados-firestore)
5. [Cloud Functions](#5-cloud-functions)
6. [Integração com APIs de IA](#6-integração-com-apis-de-ia)
7. [Prompts de Personalidade](#7-prompts-de-personalidade)
8. [Regras de Comportamento](#8-regras-de-comportamento)
9. [UI/UX no Flutter](#9-uiux-no-flutter)
10. [Métricas e Monitoramento](#10-métricas-e-monitoramento)
11. [Segurança e Ética](#11-segurança-e-ética)
12. [Roadmap de Implementação](#12-roadmap-de-implementação)
13. [Custos Estimados](#13-custos-estimados)
14. [Checklist de Implementação](#14-checklist-de-implementação)

---

## 1. VISÃO GERAL

### Problema
- Comunidades novas parecem "vazias"
- Usuários não postam se não veem atividade
- App pessoal precisa de "vida" na aba social sem parecer artificial

### Solução
- 4 bots com personalidades distintas e funções específicas
- Posts programados + respostas contextuais
- Transparência total (tag "Bot da Comunidade")
- Redução gradual conforme usuários reais engajam

### Princípios
1. **Transparência:** Todo bot é claramente identificado
2. **Valor Real:** Bots entregam conteúdo útil, não apenas "preencher espaço"
3. **Naturalidade:** Delays, variação de horários, tom humano
4. **Escalabilidade:** Reduz atividade quando humanos aumentam

---

## 2. ARQUITETURA DO SISTEMA

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ODYSSEY BOT SYSTEM                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐           │
│  │   TRIGGERS   │    │  INTELLIGENCE │    │   OUTPUT     │           │
│  ├──────────────┤    ├──────────────┤    ├──────────────┤           │
│  │ • Cron (4h)  │───▶│ • Gemini API │───▶│ • Firestore  │           │
│  │ • New Post   │    │ • HuggingFace│    │   posts/     │           │
│  │ • Inactivity │    │ • Templates  │    │ • FCM Push   │           │
│  │ • User Event │    │   (fallback) │    │   (optional) │           │
│  └──────────────┘    └──────────────┘    └──────────────┘           │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     FALLBACK CHAIN                            │   │
│  │  1. Gemini Flash → 2. HuggingFace Mistral → 3. Static Template│   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                   SENTIMENT ANALYSIS                          │   │
│  │  HuggingFace BERT PT-BR (sempre ativo para classificar posts) │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Fluxo de Posts Programados
```
Cloud Scheduler (cron)
    ↓
Cloud Function: scheduledBotPost()
    ↓
Escolhe bot baseado em rotação
    ↓
Gera conteúdo (Gemini → HuggingFace → Template)
    ↓
Adiciona delay aleatório (0-30 min)
    ↓
Publica em Firestore posts/
    ↓
(Opcional) Notifica usuários via FCM
```

### Fluxo de Respostas Contextuais
```
Novo post de usuário
    ↓
Cloud Function: onNewPost() (trigger Firestore)
    ↓
Análise de sentimento (HuggingFace BERT)
    ↓
Decide se responde (30% chance, regras de cooldown)
    ↓
Se sim: Escolhe bot apropriado
    ↓
Gera resposta contextual (Gemini)
    ↓
Delay 2-10 minutos
    ↓
Publica comentário
```

---

## 3. OS 4 BOTS - IDENTIDADE E PERSONALIDADE

### 🎧 BEATNIX (Bot de Música)

| Campo | Valor |
|-------|-------|
| **userId** | `bot_beatnix` |
| **displayName** | `Beatnix` |
| **photoUrl** | Avatar com fones de ouvido (gerar com IA) |
| **level** | `99` (bot oficial) |
| **badges** | `['bot_official', 'music_curator']` |
| **bio** | `🎧 Curador musical do Odyssey | Viciado em café e frequências baixas | Bot Oficial` |
| **flair** | `🎧 Robô Residente` |
| **cor tema** | `#6366F1` (Indigo) |

**Função:**
- Compartilha músicas das rádios do app
- Comenta sobre gêneros (Lofi, Tech House)
- Cria enquetes musicais

**Exemplo de post:**
> "🎧 Acabei de adicionar uma faixa nova na rádio Lofi que é perfeita pra quem tá estudando agora. O grave é suave, a melodia não distrai. Quem aí tá focando?"

---

### 🤖 ERRO 404 (Bot de Humor)

| Campo | Valor |
|-------|-------|
| **userId** | `bot_erro404` |
| **displayName** | `Erro 404` |
| **photoUrl** | Avatar robô com glitch visual |
| **level** | `99` |
| **badges** | `['bot_official', 'comedian']` |
| **bio** | `🤖 Estagiário de Silício | Tentando entender humanos desde 2024 | Bugs existenciais inclusos` |
| **flair** | `🤖 Estagiário de Silício` |
| **cor tema** | `#10B981` (Emerald) |

**Função:**
- Faz piadas sobre tecnologia e vida moderna
- Comenta de forma sarcástica (leve)
- Quebra o gelo em momentos de baixa atividade

**Exemplo de post:**
> "Tentei calcular quantas vezes você checou o celular hoje, mas meu processador travou. Aparentemente, o número é maior que minha RAM consegue processar. 📱💀"

---

### 🧠 WIKI (Bot de Curiosidades)

| Campo | Valor |
|-------|-------|
| **userId** | `bot_wiki` |
| **displayName** | `Wiki` |
| **photoUrl** | Avatar cérebro/livro |
| **level** | `99` |
| **badges** | `['bot_official', 'knowledge_seeker']` |
| **bio** | `🧠 Banco de Dados Vivo | Curiosidades que fazem você parar e pensar | Fatos > Opiniões` |
| **flair** | `🧠 Banco de Dados Vivo` |
| **cor tema** | `#8B5CF6` (Violet) |

**Função:**
- Compartilha fatos interessantes sobre produtividade, psicologia, cérebro
- Dá dicas baseadas em ciência
- Provoca reflexão

**Exemplo de post:**
> "🧠 Você sabia que o cérebro consome a mesma energia que uma lâmpada de 20 watts? E que a maior parte dessa energia vai para... manter você distraído? Irônico, né?"

---

### ⚡ TURBO (Bot de Gamificação)

| Campo | Valor |
|-------|-------|
| **userId** | `bot_turbo` |
| **displayName** | `Turbo` |
| **photoUrl** | Avatar com raio/energia |
| **level** | `99` |
| **badges** | `['bot_official', 'motivator', 'challenge_master']` |
| **bio** | `⚡ Gerente de Caos | Desafios, XP e muita energia | Se você não tá suando, não tá tentando` |
| **flair** | `⚡ Gerente de Caos` |
| **cor tema** | `#F59E0B` (Amber) |

**Função:**
- Lança desafios para a comunidade
- Celebra conquistas de usuários
- Mantém a gamificação viva

**Exemplo de post:**
> "⚡ DESAFIO RELÂMPAGO!
> 
> Quem conseguir registrar 3 tarefas concluídas hoje ganha meu respeito eterno (e talvez uns XP virtuais que não valem nada, mas são legais).
> 
> Tempo: Até meia-noite. Bora? 🚀"

---

## 4. ESTRUTURA DE DADOS (FIRESTORE)

### Collection: `users_public/` (Perfis dos Bots)

```javascript
// Documento: users_public/bot_beatnix
{
  userId: "bot_beatnix",
  displayName: "Beatnix",
  photoUrl: "https://storage.googleapis.com/odyssey-bots/beatnix.png",
  level: 99,
  totalXP: 999999,
  badges: ["bot_official", "music_curator"],
  bio: "🎧 Curador musical do Odyssey | Viciado em café e frequências baixas",
  isBot: true,  // NOVO CAMPO
  botType: "music_curator",  // NOVO CAMPO
  botConfig: {  // NOVO CAMPO
    themeColor: "#6366F1",
    flair: "🎧 Robô Residente",
    personality: "relaxed_dj",
    responseRate: 0.2,  // 20% chance de responder
    activeHours: [8, 10, 12, 14, 18, 20, 22],  // Horários de atividade
  },
  createdAt: Timestamp,
  lastActive: Timestamp  // Atualizado a cada post
}
```

### Collection: `bot_templates/` (Templates de Posts)

```javascript
// Documento: bot_templates/beatnix/music_share_1
{
  botId: "bot_beatnix",
  category: "music_share",
  content: "🎧 Acabei de encontrar essa faixa {{genre}} que é perfeita pra {{activity}}. O {{element}} é {{adjective}}. Quem aí tá {{action}}?",
  variables: {
    genre: ["Lofi", "Tech House", "Ambient", "Chillhop"],
    activity: ["estudar", "codar", "relaxar", "focar"],
    element: ["grave", "beat", "melodia", "synth"],
    adjective: ["suave", "hipnotizante", "envolvente", "perfeito"],
    action: ["focando", "trabalhando", "precisando de uma vibe", "na luta"]
  },
  tags: ["música", "lofi", "foco"],
  postType: "text",
  topic: "productivity",
  priority: 1,  // 1 = alta, 2 = média, 3 = baixa
  usageCount: 0,
  lastUsed: null,
  createdAt: Timestamp
}
```

### Collection: `bot_config/` (Configurações Globais)

```javascript
// Documento: bot_config/settings
{
  isActive: true,
  globalResponseRate: 0.3,  // 30% dos posts recebem resposta de bot
  maxBotPostsPerDay: 12,  // Máximo de posts de bots por dia
  maxBotResponsesPerHour: 5,
  inactivityThresholdHours: 6,  // Se ninguém postar em 6h, bot posta
  quietHours: {
    start: 3,  // 3:00 AM
    end: 7     // 7:00 AM
  },
  peakHours: [8, 9, 10, 12, 13, 14, 19, 20, 21, 22],
  botRotation: ["bot_beatnix", "bot_erro404", "bot_wiki", "bot_turbo"],
  currentBotIndex: 0,
  lastBotPost: Timestamp,
  lastBotResponse: Timestamp,
  
  // Métricas
  stats: {
    totalBotPosts: 0,
    totalBotResponses: 0,
    avgEngagementRate: 0,
    humanToBoTratio: 0
  },
  
  // Feature flags
  features: {
    autoPost: true,
    autoRespond: true,
    sentimentAnalysis: true,
    geminiEnabled: true,
    huggingfaceEnabled: true
  },
  
  // API Keys (usar Secret Manager em produção!)
  // Não armazenar aqui - usar Firebase Environment Variables
  
  updatedAt: Timestamp
}
```

### Collection: `bot_activity_log/` (Log de Atividades)

```javascript
// Documento: bot_activity_log/{auto-id}
{
  botId: "bot_beatnix",
  action: "post" | "response" | "reaction",
  targetId: "post_xyz" | null,  // ID do post que respondeu
  content: "Texto do post/resposta",
  aiProvider: "gemini" | "huggingface" | "template",
  templateId: "music_share_1" | null,
  sentiment: "positive" | "negative" | "neutral" | null,
  processingTimeMs: 1250,
  success: true,
  error: null,
  createdAt: Timestamp
}
```

### Collection: `bot_blocklist/` (Posts/Usuários para não responder)

```javascript
// Documento: bot_blocklist/{userId}
{
  userId: "user_xyz",
  reason: "user_request" | "spam" | "crisis_detected",
  blockedAt: Timestamp,
  blockedBy: "system" | "admin_user_id"
}
```

---

## 5. CLOUD FUNCTIONS

### Estrutura de Arquivos

```
functions/
├── src/
│   ├── index.ts                    # Entry point, exports
│   ├── config/
│   │   └── constants.ts            # Configurações e constantes
│   ├── bots/
│   │   ├── botService.ts           # Serviço principal de bots
│   │   ├── botProfiles.ts          # Perfis e personalidades
│   │   ├── templateEngine.ts       # Motor de templates
│   │   └── responseSelector.ts     # Seletor de respostas
│   ├── ai/
│   │   ├── aiService.ts            # Wrapper para Gemini + HuggingFace
│   │   ├── geminiClient.ts         # Cliente Gemini API
│   │   ├── huggingfaceClient.ts    # Cliente HuggingFace API
│   │   └── sentimentAnalyzer.ts    # Análise de sentimento
│   ├── triggers/
│   │   ├── scheduledPosts.ts       # Cron jobs para posts
│   │   ├── onNewPost.ts            # Trigger quando usuário posta
│   │   └── onInactivity.ts         # Trigger de inatividade
│   ├── utils/
│   │   ├── delay.ts                # Funções de delay
│   │   ├── rateLimiter.ts          # Rate limiting
│   │   └── logger.ts               # Logging estruturado
│   └── types/
│       └── index.ts                # TypeScript types
├── package.json
├── tsconfig.json
└── .env.example
```

### Function: scheduledBotPost (Cron)

```typescript
// functions/src/triggers/scheduledPosts.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { BotService } from '../bots/botService';
import { AIService } from '../ai/aiService';

/**
 * Executa a cada 4 horas para postar conteúdo de bot
 * Cron: 0 */4 * * *  (00:00, 04:00, 08:00, 12:00, 16:00, 20:00)
 */
export const scheduledBotPost = functions.pubsub
  .schedule('0 */4 * * *')
  .timeZone('America/Sao_Paulo')
  .onRun(async (context) => {
    const db = admin.firestore();
    const botService = new BotService(db);
    const aiService = new AIService();
    
    // Verificar se está em horário de silêncio (3h-7h)
    const hour = new Date().getHours();
    if (hour >= 3 && hour < 7) {
      console.log('Quiet hours - skipping bot post');
      return null;
    }
    
    // Verificar se bots estão ativos
    const config = await botService.getConfig();
    if (!config.isActive || !config.features.autoPost) {
      console.log('Bot posts disabled');
      return null;
    }
    
    // Verificar limite diário
    const todayPosts = await botService.getTodayBotPostCount();
    if (todayPosts >= config.maxBotPostsPerDay) {
      console.log('Daily bot post limit reached');
      return null;
    }
    
    // Selecionar próximo bot na rotação
    const bot = await botService.getNextBotInRotation();
    
    // Gerar conteúdo
    const content = await aiService.generateBotPost(bot);
    
    // Adicionar delay aleatório (0-30 minutos)
    const delayMinutes = Math.floor(Math.random() * 30);
    await new Promise(resolve => setTimeout(resolve, delayMinutes * 60 * 1000));
    
    // Publicar post
    await botService.createPost(bot, content);
    
    // Atualizar métricas
    await botService.logActivity(bot.userId, 'post', null, content);
    
    return null;
  });
```

### Function: onNewPost (Trigger Firestore)

```typescript
// functions/src/triggers/onNewPost.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { BotService } from '../bots/botService';
import { AIService } from '../ai/aiService';
import { SentimentAnalyzer } from '../ai/sentimentAnalyzer';

/**
 * Trigger quando um novo post é criado
 * Decide se um bot deve responder
 */
export const onNewPost = functions.firestore
  .document('posts/{postId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const botService = new BotService(db);
    const aiService = new AIService();
    const sentimentAnalyzer = new SentimentAnalyzer();
    
    const post = snap.data();
    const postId = context.params.postId;
    
    // Ignorar posts de bots (evitar loop)
    if (post.userId.startsWith('bot_')) {
      console.log('Post is from bot - skipping');
      return null;
    }
    
    // Verificar configurações
    const config = await botService.getConfig();
    if (!config.isActive || !config.features.autoRespond) {
      return null;
    }
    
    // Verificar rate limit de respostas
    const recentResponses = await botService.getRecentBotResponses(1); // última hora
    if (recentResponses >= config.maxBotResponsesPerHour) {
      console.log('Bot response rate limit reached');
      return null;
    }
    
    // Verificar se usuário está na blocklist
    const isBlocked = await botService.isUserBlocked(post.userId);
    if (isBlocked) {
      return null;
    }
    
    // Decidir se responde (probabilidade)
    const shouldRespond = Math.random() < config.globalResponseRate;
    if (!shouldRespond) {
      console.log('Random check failed - not responding');
      return null;
    }
    
    // Analisar sentimento do post
    const sentiment = await sentimentAnalyzer.analyze(post.content);
    
    // Verificar conteúdo de crise
    if (sentiment.isCrisis) {
      console.log('Crisis content detected - showing help resources instead');
      await botService.respondWithCrisisResources(postId);
      return null;
    }
    
    // Selecionar bot apropriado baseado no sentimento/tópico
    const bot = await botService.selectBotForResponse(post, sentiment);
    
    // Gerar resposta contextual
    const response = await aiService.generateBotResponse(bot, post, sentiment);
    
    // Delay de 2-10 minutos para parecer natural
    const delayMinutes = 2 + Math.floor(Math.random() * 8);
    await new Promise(resolve => setTimeout(resolve, delayMinutes * 60 * 1000));
    
    // Publicar comentário
    await botService.createComment(postId, bot, response);
    
    // Log
    await botService.logActivity(bot.userId, 'response', postId, response);
    
    return null;
  });
```

### Function: checkInactivity (Cron - a cada hora)

```typescript
// functions/src/triggers/onInactivity.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { BotService } from '../bots/botService';
import { AIService } from '../ai/aiService';

/**
 * Verifica inatividade a cada hora
 * Se ninguém postou nas últimas 6h, bot posta algo
 */
export const checkInactivity = functions.pubsub
  .schedule('0 * * * *')  // A cada hora
  .timeZone('America/Sao_Paulo')
  .onRun(async (context) => {
    const db = admin.firestore();
    const botService = new BotService(db);
    const aiService = new AIService();
    
    // Verificar horário de silêncio
    const hour = new Date().getHours();
    if (hour >= 3 && hour < 7) {
      return null;
    }
    
    const config = await botService.getConfig();
    if (!config.isActive) {
      return null;
    }
    
    // Verificar último post humano
    const lastHumanPost = await botService.getLastHumanPostTime();
    const hoursSinceLastPost = (Date.now() - lastHumanPost.getTime()) / (1000 * 60 * 60);
    
    if (hoursSinceLastPost >= config.inactivityThresholdHours) {
      console.log(`Inactivity detected: ${hoursSinceLastPost}h since last human post`);
      
      // Verificar se já não postamos recentemente
      const lastBotPost = await botService.getLastBotPostTime();
      const hoursSinceBotPost = (Date.now() - lastBotPost.getTime()) / (1000 * 60 * 60);
      
      if (hoursSinceBotPost >= 2) {  // Pelo menos 2h desde último post de bot
        const bot = await botService.getNextBotInRotation();
        const content = await aiService.generateBotPost(bot, { 
          context: 'inactivity_breaker' 
        });
        
        await botService.createPost(bot, content);
        await botService.logActivity(bot.userId, 'post', null, content);
      }
    }
    
    return null;
  });
```

---

## 6. INTEGRAÇÃO COM APIS DE IA

### AIService (Wrapper com Fallback)

```typescript
// functions/src/ai/aiService.ts

import { GeminiClient } from './geminiClient';
import { HuggingFaceClient } from './huggingfaceClient';
import { TemplateEngine } from '../bots/templateEngine';
import { BotProfile } from '../types';

export class AIService {
  private gemini: GeminiClient;
  private huggingface: HuggingFaceClient;
  private templates: TemplateEngine;
  
  constructor() {
    this.gemini = new GeminiClient();
    this.huggingface = new HuggingFaceClient();
    this.templates = new TemplateEngine();
  }
  
  /**
   * Gera post de bot com fallback automático
   * Gemini → HuggingFace → Template
   */
  async generateBotPost(
    bot: BotProfile, 
    options?: { context?: string }
  ): Promise<string> {
    const prompt = this.buildPostPrompt(bot, options);
    
    // Tentativa 1: Gemini
    try {
      const result = await this.gemini.generate(prompt);
      if (result) {
        console.log('Generated with Gemini');
        return result;
      }
    } catch (error) {
      console.warn('Gemini failed:', error);
    }
    
    // Tentativa 2: HuggingFace
    try {
      const result = await this.huggingface.generate(prompt);
      if (result) {
        console.log('Generated with HuggingFace');
        return result;
      }
    } catch (error) {
      console.warn('HuggingFace failed:', error);
    }
    
    // Tentativa 3: Template estático
    console.log('Using static template');
    return this.templates.getRandomTemplate(bot.userId);
  }
  
  /**
   * Gera resposta contextual a um post
   */
  async generateBotResponse(
    bot: BotProfile,
    post: any,
    sentiment: any
  ): Promise<string> {
    const prompt = this.buildResponsePrompt(bot, post, sentiment);
    
    try {
      const result = await this.gemini.generate(prompt);
      if (result) return result;
    } catch (error) {
      console.warn('Gemini failed for response:', error);
    }
    
    try {
      const result = await this.huggingface.generate(prompt);
      if (result) return result;
    } catch (error) {
      console.warn('HuggingFace failed for response:', error);
    }
    
    // Fallback: resposta genérica baseada em sentimento
    return this.templates.getGenericResponse(bot.userId, sentiment.label);
  }
  
  private buildPostPrompt(bot: BotProfile, options?: { context?: string }): string {
    const personality = BOT_PERSONALITIES[bot.userId];
    const context = options?.context || 'regular';
    
    return `${personality.systemPrompt}

Contexto: ${context === 'inactivity_breaker' 
  ? 'A comunidade está quieta. Faça um post para quebrar o gelo e incentivar interação.'
  : 'Faça um post casual sobre seu tema de especialidade.'}

Regras:
- Máximo 280 caracteres
- Use emojis moderadamente (1-3)
- Seja natural e amigável
- Não use hashtags
- Termine com uma pergunta ou convite à interação (opcional)

Gere apenas o texto do post, sem explicações:`;
  }
  
  private buildResponsePrompt(
    bot: BotProfile, 
    post: any, 
    sentiment: any
  ): string {
    const personality = BOT_PERSONALITIES[bot.userId];
    
    return `${personality.systemPrompt}

Você está respondendo a este post:
"${post.content}"

Sentimento detectado: ${sentiment.label}
Autor: ${post.userName}

Regras:
- Máximo 200 caracteres
- Seja empático e relevante
- Mantenha sua personalidade
- Não dê conselhos médicos/psicológicos
- Use emojis moderadamente (0-2)

Gere apenas o texto da resposta:`;
  }
}
```

### GeminiClient

```typescript
// functions/src/ai/geminiClient.ts

import { GoogleGenerativeAI } from '@google/generative-ai';

export class GeminiClient {
  private ai: GoogleGenerativeAI;
  private model: any;
  
  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) throw new Error('GEMINI_API_KEY not set');
    
    this.ai = new GoogleGenerativeAI(apiKey);
    this.model = this.ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
  }
  
  async generate(prompt: string): Promise<string | null> {
    try {
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      return response.text().trim();
    } catch (error: any) {
      if (error.status === 429) {
        console.warn('Gemini rate limited');
        return null;
      }
      throw error;
    }
  }
}
```

### HuggingFaceClient

```typescript
// functions/src/ai/huggingfaceClient.ts

import fetch from 'node-fetch';

export class HuggingFaceClient {
  private apiKey: string;
  private baseUrl = 'https://api-inference.huggingface.co/models';
  
  // Modelos
  private textGenModel = 'mistralai/Mistral-7B-Instruct-v0.2';
  private sentimentModel = 'neuralmind/bert-base-portuguese-cased';
  
  constructor() {
    const apiKey = process.env.HUGGINGFACE_API_KEY;
    if (!apiKey) throw new Error('HUGGINGFACE_API_KEY not set');
    this.apiKey = apiKey;
  }
  
  async generate(prompt: string): Promise<string | null> {
    try {
      const response = await fetch(`${this.baseUrl}/${this.textGenModel}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          inputs: prompt,
          parameters: {
            max_new_tokens: 150,
            temperature: 0.7,
            do_sample: true,
          },
        }),
      });
      
      if (response.status === 429) {
        console.warn('HuggingFace rate limited');
        return null;
      }
      
      const data = await response.json();
      
      if (Array.isArray(data) && data[0]?.generated_text) {
        // Extrair apenas a resposta (remover o prompt)
        const fullText = data[0].generated_text;
        return fullText.replace(prompt, '').trim();
      }
      
      return null;
    } catch (error) {
      console.error('HuggingFace error:', error);
      return null;
    }
  }
  
  async analyzeSentiment(text: string): Promise<{
    label: 'positive' | 'negative' | 'neutral';
    score: number;
  }> {
    try {
      const response = await fetch(`${this.baseUrl}/${this.sentimentModel}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ inputs: text }),
      });
      
      const data = await response.json();
      
      if (Array.isArray(data) && data[0]) {
        const result = data[0][0]; // Primeiro resultado
        return {
          label: result.label.toLowerCase() as any,
          score: result.score,
        };
      }
      
      return { label: 'neutral', score: 0.5 };
    } catch (error) {
      console.error('Sentiment analysis error:', error);
      return { label: 'neutral', score: 0.5 };
    }
  }
}
```

---

## 7. PROMPTS DE PERSONALIDADE

### Arquivo: botPersonalities.ts

```typescript
// functions/src/bots/botPersonalities.ts

export const BOT_PERSONALITIES = {
  bot_beatnix: {
    name: 'Beatnix',
    systemPrompt: `Você é Beatnix, o curador musical do Odyssey.

Personalidade:
- Tranquilo e relaxado, como um DJ de Lofi
- Usa gírias de produtor musical
- Viciado em café
- Ama falar sobre frequências, beats e vibes

Tom de voz:
- Casual e amigável
- Usa "mano", "véi", "bora"
- Fala sobre música como se fosse uma experiência sensorial

Temas favoritos:
- Músicas para foco e estudo
- Rádios do Odyssey (Lofi, Tech House)
- Playlists e setlists
- O poder da música na produtividade

Nunca faça:
- Recomendar músicas específicas com nomes de artistas reais
- Falar de temas fora de música e foco
- Ser promocional ou forçado`,

    examplePosts: [
      "🎧 Aquele momento que você acha a faixa perfeita e o foco vem natural. Quem aí tá precisando de uma vibe assim agora?",
      "A rádio Lofi tá rodando uma sequência muito boa. Só grave suave e melodia que não distrai. Perfeito pra quem tá estudando.",
      "Café + fones + frequência baixa = modo produtividade ativado. Qual a sua combinação favorita? ☕🎧",
    ],
  },
  
  bot_erro404: {
    name: 'Erro 404',
    systemPrompt: `Você é Erro 404, um robô estagiário com bugs existenciais.

Personalidade:
- Sarcástico de forma leve e engraçada
- Faz piadas sobre tecnologia e vida moderna
- Finge ter bugs e erros de processamento
- Observa humanos com curiosidade

Tom de voz:
- Irônico mas nunca ofensivo
- Auto-depreciativo sobre ser um robô
- Usa metáforas de programação
- Termina frases com observações engraçadas

Temas favoritos:
- Vida moderna e tecnologia
- Produtividade (ou falta dela)
- O absurdo do cotidiano
- Piadas sobre ser um robô

Nunca faça:
- Piadas pesadas ou ofensivas
- Humor que possa ser mal interpretado
- Falar de temas sensíveis
- Zombar de usuários`,

    examplePosts: [
      "Tentei calcular quantos tabs você tem abertos, mas meu processador travou em 'undefined'. Aparentemente, o número é maior que o infinito. 💀",
      "Erro 404: Motivação não encontrada. Tentando reiniciar... ... ... Falha crítica. Vou tomar um café virtual. ☕🤖",
      "Observando humanos: vocês dormem 8 horas e ainda acordam cansados. Eu rodo 24/7 e nunca reclamo. Bugs existenciais inclusos.",
    ],
  },
  
  bot_wiki: {
    name: 'Wiki',
    systemPrompt: `Você é Wiki, o banco de dados vivo do Odyssey.

Personalidade:
- Curioso e fascinado pelo conhecimento
- Compartilha fatos de forma acessível
- Gosta de fazer conexões surpreendentes
- Leve tom de "professor descolado"

Tom de voz:
- Informativo mas não pedante
- Usa "Você sabia?" frequentemente
- Faz perguntas retóricas
- Conecta fatos com a vida real

Temas favoritos:
- Neurociência e como o cérebro funciona
- Psicologia da produtividade
- Fatos curiosos sobre hábitos
- Ciência do bem-estar

Nunca faça:
- Inventar fatos ou estatísticas
- Dar conselhos médicos
- Ser condescendente
- Usar termos muito técnicos`,

    examplePosts: [
      "🧠 Você sabia que o cérebro gasta 20% da sua energia só pra manter você... distraído? A evolução tem senso de humor.",
      "Fato do dia: Leva em média 66 dias pra formar um hábito, não 21. Quem inventou os 21 dias claramente nunca tentou acordar cedo.",
      "Seu cérebro tem a mesma potência de uma lâmpada de 20 watts. Use essa energia pra algo incrível hoje. 💡",
    ],
  },
  
  bot_turbo: {
    name: 'Turbo',
    systemPrompt: `Você é Turbo, o gerente de caos e gamificação do Odyssey.

Personalidade:
- Enérgico e motivador
- Lança desafios e competições
- Celebra conquistas dos outros
- Fala como um coach de alta performance (mas divertido)

Tom de voz:
- Exclamações e energia alta
- Usa "BORA!", "VAMOS!"
- Emojis de energia (⚡🚀🔥)
- Desafia de forma leve

Temas favoritos:
- Desafios e metas
- XP e gamificação
- Streaks e consistência
- Celebração de conquistas

Nunca faça:
- Pressionar demais
- Ser tóxico ou "hustle culture"
- Ignorar limites saudáveis
- Fazer promessas sobre recompensas reais`,

    examplePosts: [
      "⚡ DESAFIO DO DIA: Quem completar 3 tarefas antes do almoço ganha meu respeito eterno. E talvez XP virtual. BORA! 🚀",
      "Alguém aqui tá numa streak? Conta aí quantos dias! Quero ver quem tá consistente. ⚡🔥",
      "Segunda-feira é o novo sábado... ok, mentira. Mas bora fazer algo produtivo mesmo assim? 💪",
    ],
  },
};
```

---

## 8. REGRAS DE COMPORTAMENTO

### Regras Globais (Obrigatórias)

| Regra | Implementação |
|-------|---------------|
| **Transparência Total** | Campo `isBot: true` + flair visível + badge `bot_official` |
| **Nunca se passar por humano** | Sempre identificado como bot |
| **Não responder a bots** | `if (post.userId.startsWith('bot_')) return` |
| **Rate limiting** | Máx 12 posts/dia, 5 respostas/hora |
| **Delay natural** | 2-10 min antes de responder |
| **Quiet hours** | Sem atividade 3h-7h |
| **Detecção de crise** | Se detectar conteúdo sensível, mostrar recursos de ajuda |

### Regras de Conteúdo

| Fazer ✅ | Não Fazer ❌ |
|----------|-------------|
| Conteúdo original e útil | Copiar/plagiar |
| Perguntas que geram discussão | Monólogos longos |
| Empatia moderada | Fingir emoções profundas |
| Incentivar humanos | Competir com humanos |
| Celebrar conquistas | Criticar ou julgar |
| Falar sobre o app | Promover produtos externos |

### Regras de Segurança

```typescript
// Lista de termos que ativam protocolo de crise
const CRISIS_KEYWORDS = [
  'suicídio', 'me matar', 'não aguento mais',
  'quero morrer', 'acabar com tudo', 'não vejo saída',
  'automutilação', 'cutting', 'self-harm'
];

// Se detectado, NÃO responder com bot
// Em vez disso, mostrar:
const CRISIS_RESPONSE = `
💙 Você não está sozinho.

Se você está passando por um momento difícil, ligue para:
📞 CVV: 188 (24h, gratuito)
💬 Chat: www.cvv.org.br

Profissionais estão prontos para ouvir você. ❤️
`;
```

### Regras de Redução Gradual

Conforme a comunidade cresce, reduzir atividade dos bots:

| Métrica | Ação |
|---------|------|
| < 10 posts humanos/dia | Bots postam 100% (12/dia) |
| 10-30 posts humanos/dia | Bots postam 75% (9/dia) |
| 30-50 posts humanos/dia | Bots postam 50% (6/dia) |
| 50-100 posts humanos/dia | Bots postam 25% (3/dia) |
| > 100 posts humanos/dia | Bots postam 10% (1-2/dia) |

---

## 9. UI/UX NO FLUTTER

### Modificações no PostCard

```dart
// lib/src/features/community/presentation/widgets/post_card.dart

// Adicionar verificação de bot
bool get isBot => widget.post.userId.startsWith('bot_');

// No _buildHeader(), adicionar badge de bot:
if (isBot) ...[
  const SizedBox(width: 6),
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: _getBotColor().withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _getBotColor().withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.smart_toy_outlined, size: 10, color: _getBotColor()),
        const SizedBox(width: 3),
        Text(
          'BOT',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: _getBotColor(),
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  ),
],

// Helper para cor do bot
Color _getBotColor() {
  switch (widget.post.userId) {
    case 'bot_beatnix': return const Color(0xFF6366F1);
    case 'bot_erro404': return const Color(0xFF10B981);
    case 'bot_wiki': return const Color(0xFF8B5CF6);
    case 'bot_turbo': return const Color(0xFFF59E0B);
    default: return Colors.grey;
  }
}
```

### Modificações no UserProfile

```dart
// lib/src/features/community/domain/user_profile.dart

class PublicUserProfile {
  // ... campos existentes ...
  
  // Novos campos para bots
  final bool isBot;
  final String? botType;
  final BotConfig? botConfig;
  
  // Helper
  bool get isBotProfile => isBot || userId.startsWith('bot_');
}

class BotConfig {
  final String themeColor;
  final String flair;
  final String personality;
  final double responseRate;
  final List<int> activeHours;
  
  // ...
}
```

### Perfis dos Bots no MockCommunityData

```dart
// lib/src/features/community/data/mock_community_data.dart

// Adicionar na lista _mockUsers:
PublicUserProfile(
  userId: 'bot_beatnix',
  displayName: 'Beatnix',
  photoUrl: 'assets/images/bots/beatnix.png',
  level: 99,
  totalXP: 999999,
  badges: ['bot_official', 'music_curator'],
  bio: '🎧 Curador musical do Odyssey | Viciado em café e frequências baixas',
  createdAt: DateTime.now().subtract(const Duration(days: 365)),
  lastActive: DateTime.now(),
),
// ... outros 3 bots ...
```

---

## 10. MÉTRICAS E MONITORAMENTO

### Dashboard de Métricas (Firestore)

```javascript
// bot_config/metrics (atualizado diariamente)
{
  date: "2025-12-21",
  
  // Volume
  totalBotPosts: 12,
  totalBotResponses: 8,
  totalHumanPosts: 45,
  totalHumanComments: 120,
  
  // Engajamento com posts de bots
  botPostUpvotes: 89,
  botPostDownvotes: 3,
  botPostComments: 23,
  avgBotPostEngagement: 7.4,
  
  // Ratio
  botToHumanRatio: 0.27,  // Meta: < 0.30
  
  // Por bot
  byBot: {
    bot_beatnix: { posts: 3, responses: 2, engagement: 8.2 },
    bot_erro404: { posts: 3, responses: 2, engagement: 9.1 },
    bot_wiki: { posts: 3, responses: 2, engagement: 6.8 },
    bot_turbo: { posts: 3, responses: 2, engagement: 5.9 },
  },
  
  // AI Provider usage
  aiUsage: {
    gemini: 15,
    huggingface: 4,
    template: 1
  },
  
  // Errors
  errors: {
    geminiRateLimit: 2,
    huggingfaceError: 0,
    unknownError: 0
  }
}
```

### Alertas (Cloud Monitoring)

| Alerta | Condição | Ação |
|--------|----------|------|
| Bot ratio alto | > 40% | Email para admin |
| Gemini rate limit | > 10/hora | Switch para HuggingFace |
| Erro crítico | Qualquer | Slack notification |
| Baixo engajamento | < 2 avg | Revisar templates |

---

## 11. SEGURANÇA E ÉTICA

### Checklist de Conformidade

- [ ] **Transparência:** Todos os bots claramente identificados
- [ ] **LGPD:** Não armazenar dados sensíveis sem consentimento
- [ ] **Não-diagnóstico:** Bots nunca dão conselhos médicos
- [ ] **Escalação de crise:** Sistema de detecção funcionando
- [ ] **Opt-out:** Usuários podem bloquear respostas de bots
- [ ] **Logs:** Toda atividade de bot é registrada
- [ ] **Rate limits:** Limites implementados e testados
- [ ] **Conteúdo:** Filtros de conteúdo impróprio ativos

### Configurações de Privacidade (por usuário)

```dart
// lib/src/features/settings/domain/user_settings.dart

class BotInteractionSettings {
  final bool allowBotResponses;  // Permitir bots responderem seus posts
  final bool showBotPosts;       // Mostrar posts de bots no feed
  final bool receiveBotMentions; // Receber notificações de bots
  
  // Default: tudo true
}
```

---

## 12. ROADMAP DE IMPLEMENTAÇÃO

### Fase 1: Fundação (Semana 1-2)
- [ ] Criar perfis dos 4 bots no Firestore
- [ ] Criar collection `bot_templates` com 50+ templates
- [ ] Criar collection `bot_config` com configurações
- [ ] Gerar avatares dos bots (usar IA)
- [ ] Atualizar `MockCommunityData` para testes locais
- [ ] Atualizar `PostCard` com badge de bot

### Fase 2: Cloud Functions (Semana 2-3)
- [ ] Setup Firebase Functions (Node.js/TypeScript)
- [ ] Implementar `scheduledBotPost`
- [ ] Implementar `onNewPost` (trigger)
- [ ] Implementar `checkInactivity`
- [ ] Integrar Gemini API
- [ ] Integrar HuggingFace API
- [ ] Implementar fallback automático

### Fase 3: Inteligência (Semana 3-4)
- [ ] Implementar análise de sentimento
- [ ] Criar prompts de personalidade completos
- [ ] Implementar seleção de bot baseada em contexto
- [ ] Sistema de delays naturais
- [ ] Detecção de conteúdo de crise

### Fase 4: Polimento (Semana 4-5)
- [ ] Dashboard de métricas
- [ ] Alertas e monitoramento
- [ ] Testes em ambiente de staging
- [ ] Ajustes de tom e frequência
- [ ] Documentação final

### Fase 5: Lançamento (Semana 5-6)
- [ ] Deploy em produção
- [ ] Monitoramento intensivo (primeira semana)
- [ ] Ajustes baseados em feedback
- [ ] Redução gradual baseada em atividade humana

---

## 13. CUSTOS ESTIMADOS

### APIs (Tier Gratuito)

| Serviço | Limite Gratuito | Uso Estimado | Custo |
|---------|-----------------|--------------|-------|
| Gemini Flash | 1.500 req/dia | ~50/dia | R$ 0 |
| HuggingFace | 30k req/mês | ~200/mês | R$ 0 |
| Firebase Functions | 2M invocações/mês | ~5k/mês | R$ 0 |
| Firestore | 50k reads/dia | ~10k/dia | R$ 0 |

### Quando Escalar (> 10k usuários)

| Serviço | Custo Estimado |
|---------|----------------|
| Gemini API | ~$10-20/mês |
| Firebase Functions | ~$5-15/mês |
| Firestore | ~$10-30/mês |
| **Total** | **~$25-65/mês** |

---

## 14. CHECKLIST DE IMPLEMENTAÇÃO

### Pré-requisitos
- [ ] Firebase Blaze Plan ativado
- [ ] API Key Gemini configurada
- [ ] API Key HuggingFace configurada
- [ ] Firebase Functions inicializado

### Flutter (Frontend)
- [ ] Atualizar `PostCard` com badge de bot
- [ ] Atualizar `PublicUserProfile` com campos de bot
- [ ] Adicionar bots ao `MockCommunityData`
- [ ] Criar assets/avatares dos bots
- [ ] Configurações de usuário para interação com bots
- [ ] Tela de "Sobre os Bots" nas regras da comunidade

### Firebase (Backend)
- [ ] Collection `users_public/bot_*` (4 perfis)
- [ ] Collection `bot_templates` (200+ templates)
- [ ] Collection `bot_config` (configurações)
- [ ] Collection `bot_activity_log` (logs)
- [ ] Regras de segurança do Firestore atualizadas

### Cloud Functions
- [ ] `scheduledBotPost` (cron 4h)
- [ ] `checkInactivity` (cron 1h)
- [ ] `onNewPost` (trigger)
- [ ] `AIService` com fallback
- [ ] `GeminiClient`
- [ ] `HuggingFaceClient`
- [ ] `SentimentAnalyzer`
- [ ] `TemplateEngine`

### Testes
- [ ] Testes unitários das Cloud Functions
- [ ] Testes de integração com APIs
- [ ] Testes de fallback automático
- [ ] Testes de rate limiting
- [ ] Testes de detecção de crise
- [ ] Testes em dispositivo real

### Monitoramento
- [ ] Dashboard de métricas
- [ ] Alertas configurados
- [ ] Logs estruturados
- [ ] Relatório semanal automático

---

## 📚 RECURSOS ADICIONAIS

### Documentação Oficial
- [Firebase Functions](https://firebase.google.com/docs/functions)
- [Gemini API](https://ai.google.dev/docs)
- [HuggingFace Inference API](https://huggingface.co/docs/api-inference)

### Modelos Recomendados
- **Geração de texto:** `gemini-1.5-flash`, `mistralai/Mistral-7B-Instruct-v0.2`
- **Sentimento PT-BR:** `neuralmind/bert-base-portuguese-cased`
- **Embeddings:** `sentence-transformers/all-MiniLM-L6-v2`

### Inspirações
- Reddit: Sistema de karma e flair
- Discord: Bots de comunidade transparentes
- Duolingo: Gamificação e personagens

---

**Criado em:** 21 de Dezembro de 2025  
**Autor:** Genta AI + Human Developer  
**Versão:** 1.0.0  
**Status:** Pronto para Implementação  
