"use strict";
/**
 * Serviço de IA com fallback automático
 * Gemini → HuggingFace → Templates
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateBotContent = generateBotContent;
exports.analyzeSentiment = analyzeSentiment;
const generative_ai_1 = require("@google/generative-ai");
const botPersonalities_1 = require("../bots/botPersonalities");
// Inicializar Gemini (API Key via environment variable)
const genAI = new generative_ai_1.GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');
/**
 * Gera conteúdo usando Gemini com fallback para templates
 */
async function generateBotContent(botId, options = {}) {
    const personality = (0, botPersonalities_1.getBotPersonality)(botId);
    if (!personality) {
        console.error(`Bot personality not found: ${botId}`);
        return '';
    }
    // Tentar Gemini primeiro
    try {
        const content = await generateWithGemini(botId, personality.systemPrompt, options);
        if (content) {
            console.log(`✅ Generated with Gemini for ${botId}`);
            return content;
        }
    }
    catch (error) {
        console.warn(`⚠️ Gemini failed for ${botId}:`, error);
    }
    // Tentar HuggingFace como fallback
    try {
        const content = await generateWithHuggingFace(botId, personality.systemPrompt, options);
        if (content) {
            console.log(`✅ Generated with HuggingFace for ${botId}`);
            return content;
        }
    }
    catch (error) {
        console.warn(`⚠️ HuggingFace failed for ${botId}:`, error);
    }
    // Fallback final: usar exemplo estático
    console.log(`📝 Using static template for ${botId}`);
    return (0, botPersonalities_1.getRandomExamplePost)(botId);
}
/**
 * Gera conteúdo usando Gemini API
 */
async function generateWithGemini(botId, systemPrompt, options) {
    if (!process.env.GEMINI_API_KEY) {
        console.warn('GEMINI_API_KEY not configured');
        return null;
    }
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    let userPrompt = '';
    if (options.context === 'inactivity_breaker') {
        userPrompt = 'A comunidade está quieta há algumas horas. Faça um post para quebrar o gelo e incentivar interação.';
    }
    else if (options.context === 'response' && options.targetPost) {
        userPrompt = `Você está respondendo a este post de ${options.targetPost.userName}:
"${options.targetPost.content}"

Sentimento detectado: ${options.targetPost.sentiment || 'neutro'}

Gere uma resposta empática e relevante (máximo 200 caracteres).`;
    }
    else {
        userPrompt = 'Faça um post casual sobre seu tema de especialidade. Seja natural e engaje a comunidade.';
    }
    const fullPrompt = `${systemPrompt}

${userPrompt}

Gere apenas o texto, sem explicações ou formatação extra:`;
    try {
        const result = await model.generateContent(fullPrompt);
        const response = await result.response;
        const text = response.text().trim();
        // Validar tamanho
        if (text.length > 300) {
            return text.substring(0, 280) + '...';
        }
        return text;
    }
    catch (error) {
        if (error?.status === 429) {
            console.warn('Gemini rate limited');
        }
        throw error;
    }
}
/**
 * Gera conteúdo usando HuggingFace API
 */
async function generateWithHuggingFace(botId, systemPrompt, options) {
    const apiKey = process.env.HUGGINGFACE_API_KEY;
    if (!apiKey) {
        console.warn('HUGGINGFACE_API_KEY not configured');
        return null;
    }
    // Usar modelo Tucano (nativo PT-BR)
    const model = 'TucanoBR/Tucano-2b4';
    const url = `https://api-inference.huggingface.co/models/${model}`;
    const prompt = options.context === 'response' && options.targetPost
        ? `Responda como ${botId.replace('bot_', '')}: "${options.targetPost.content}"\nResposta:`
        : `${systemPrompt}\n\nGere um post curto:\n`;
    try {
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                inputs: prompt,
                parameters: {
                    max_new_tokens: 100,
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
            const fullText = data[0].generated_text;
            // Extrair apenas a resposta (remover prompt)
            const generatedPart = fullText.replace(prompt, '').trim();
            return generatedPart.substring(0, 280);
        }
        return null;
    }
    catch (error) {
        console.error('HuggingFace error:', error);
        throw error;
    }
}
/**
 * Analisa sentimento de um texto usando HuggingFace
 */
async function analyzeSentiment(text) {
    const apiKey = process.env.HUGGINGFACE_API_KEY;
    // Verificar palavras de crise primeiro
    const { CRISIS_KEYWORDS } = await Promise.resolve().then(() => __importStar(require('../config/constants')));
    const lowerText = text.toLowerCase();
    const isCrisis = CRISIS_KEYWORDS.some(keyword => lowerText.includes(keyword));
    if (isCrisis) {
        return { label: 'negative', score: 1.0, isCrisis: true };
    }
    if (!apiKey) {
        // Fallback: análise simples baseada em palavras
        return simpleAnalysis(text);
    }
    try {
        // Usar modelo PT-BR para sentimento
        const model = 'pysentimiento/bertweet-pt-sentiment';
        const url = `https://api-inference.huggingface.co/models/${model}`;
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ inputs: text }),
        });
        const data = await response.json();
        if (Array.isArray(data) && data[0]) {
            const result = data[0][0];
            return {
                label: mapSentimentLabel(result.label),
                score: result.score,
                isCrisis: false,
            };
        }
    }
    catch (error) {
        console.error('Sentiment analysis error:', error);
    }
    return simpleAnalysis(text);
}
function mapSentimentLabel(label) {
    const lower = label.toLowerCase();
    if (lower.includes('pos') || lower.includes('positiv'))
        return 'positive';
    if (lower.includes('neg') || lower.includes('negativ'))
        return 'negative';
    return 'neutral';
}
function simpleAnalysis(text) {
    const positiveWords = ['feliz', 'ótimo', 'incrível', 'legal', 'amei', 'parabéns', 'obrigado', '❤️', '🎉', '😊'];
    const negativeWords = ['triste', 'difícil', 'ruim', 'mal', 'cansado', 'frustrado', 'ansioso', '😢', '😔'];
    const lower = text.toLowerCase();
    const posCount = positiveWords.filter(w => lower.includes(w)).length;
    const negCount = negativeWords.filter(w => lower.includes(w)).length;
    if (posCount > negCount)
        return { label: 'positive', score: 0.7, isCrisis: false };
    if (negCount > posCount)
        return { label: 'negative', score: 0.7, isCrisis: false };
    return { label: 'neutral', score: 0.5, isCrisis: false };
}
//# sourceMappingURL=aiService.js.map