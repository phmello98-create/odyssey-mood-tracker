"use strict";
/**
 * Trigger: Quando um novo post é criado
 * Decide se um bot deve responder
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
exports.onNewPost = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const aiService_1 = require("../ai/aiService");
const constants_1 = require("../config/constants");
const db = admin.firestore();
/**
 * Trigger Firestore: quando um post é criado
 */
exports.onNewPost = functions.firestore
    .document('posts/{postId}')
    .onCreate(async (snap, context) => {
    const postId = context.params.postId;
    const post = snap.data();
    console.log(`📝 New post detected: ${postId}`);
    // Ignorar posts de bots (evitar loop)
    if (post.userId.startsWith('bot_')) {
        console.log('🤖 Post is from bot - skipping');
        return null;
    }
    // Verificar configurações
    const configDoc = await db.collection('bot_config').doc('settings').get();
    const config = configDoc.data();
    if (!config?.isActive || !config?.features?.autoRespond) {
        console.log('❌ Bot responses disabled');
        return null;
    }
    // Verificar rate limit de respostas (última hora)
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentResponsesQuery = await db.collection('bot_activity_log')
        .where('action', '==', 'response')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneHourAgo))
        .get();
    if (recentResponsesQuery.size >= constants_1.RATE_LIMITS.MAX_BOT_RESPONSES_PER_HOUR) {
        console.log(`📊 Response rate limit reached (${recentResponsesQuery.size}/${constants_1.RATE_LIMITS.MAX_BOT_RESPONSES_PER_HOUR})`);
        return null;
    }
    // Verificar se usuário está na blocklist
    const blockDoc = await db.collection('bot_blocklist').doc(post.userId).get();
    if (blockDoc.exists) {
        console.log('🚫 User is blocked from bot interactions');
        return null;
    }
    // Decidir se responde (probabilidade)
    const shouldRespond = Math.random() < constants_1.RATE_LIMITS.GLOBAL_RESPONSE_RATE;
    if (!shouldRespond) {
        console.log(`🎲 Random check failed (${constants_1.RATE_LIMITS.GLOBAL_RESPONSE_RATE * 100}% chance)`);
        return null;
    }
    // Analisar sentimento do post
    const sentiment = await (0, aiService_1.analyzeSentiment)(post.content);
    console.log(`💭 Sentiment: ${sentiment.label} (crisis: ${sentiment.isCrisis})`);
    // Verificar conteúdo de crise
    if (sentiment.isCrisis) {
        console.log('🆘 Crisis content detected - posting help resources');
        await postCrisisResponse(postId, post.userId);
        return null;
    }
    // Selecionar bot apropriado baseado no sentimento
    const botId = selectBotForResponse(post, sentiment);
    console.log(`🎯 Selected bot for response: ${botId}`);
    // Gerar resposta contextual
    const response = await (0, aiService_1.generateBotContent)(botId, {
        context: 'response',
        targetPost: {
            content: post.content,
            userName: post.userName,
            sentiment: sentiment.label,
        },
    });
    if (!response) {
        console.error('❌ Failed to generate response');
        return null;
    }
    // Delay de 2-10 minutos para parecer natural
    const delayMs = (constants_1.DELAYS.MIN_RESPONSE_MINUTES +
        Math.random() * (constants_1.DELAYS.MAX_RESPONSE_MINUTES - constants_1.DELAYS.MIN_RESPONSE_MINUTES)) * 60 * 1000;
    // Em produção, usar Cloud Tasks para delay real
    // Por agora, limitamos a 5s para dev
    await new Promise(resolve => setTimeout(resolve, Math.min(delayMs, 5000)));
    // Publicar comentário
    const botProfile = await getBotProfile(botId);
    const commentData = {
        postId: postId,
        userId: botId,
        userName: botProfile.displayName,
        userPhotoUrl: botProfile.photoUrl,
        content: response,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const commentRef = await db.collection('posts').doc(postId)
        .collection('comments').add(commentData);
    // Incrementar contador de comentários
    await db.collection('posts').doc(postId).update({
        commentCount: admin.firestore.FieldValue.increment(1),
    });
    console.log(`✅ Bot response posted: ${commentRef.id}`);
    // Log de atividade
    await db.collection('bot_activity_log').add({
        botId: botId,
        action: 'response',
        targetId: postId,
        content: response.substring(0, 100),
        sentiment: sentiment.label,
        success: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Atualizar stats
    await db.collection('bot_config').doc('settings').update({
        lastBotResponse: admin.firestore.FieldValue.serverTimestamp(),
        'stats.totalBotResponses': admin.firestore.FieldValue.increment(1),
    });
    return null;
});
/**
 * Seleciona o bot mais apropriado para responder
 */
function selectBotForResponse(post, sentiment) {
    const content = post.content.toLowerCase();
    const categories = post.categories || [];
    // Regras de seleção baseadas em contexto
    // Música/foco → Beatnix
    if (content.includes('música') || content.includes('lofi') ||
        content.includes('foco') || content.includes('estudando')) {
        return constants_1.BOT_IDS.BEATNIX;
    }
    // Conquistas/metas → Turbo
    if (categories.includes('achievements') ||
        content.includes('consegui') || content.includes('completei') ||
        content.includes('streak') || content.includes('meta')) {
        return constants_1.BOT_IDS.TURBO;
    }
    // Perguntas/curiosidades → Wiki
    if (content.includes('?') || content.includes('como') ||
        content.includes('por que') || content.includes('sabia')) {
        return constants_1.BOT_IDS.WIKI;
    }
    // Sentimento negativo → Beatnix (mais empático)
    if (sentiment.label === 'negative') {
        return constants_1.BOT_IDS.BEATNIX;
    }
    // Sentimento positivo → Turbo (celebrar)
    if (sentiment.label === 'positive') {
        return constants_1.BOT_IDS.TURBO;
    }
    // Default: Erro 404 (humor leve quebra gelo)
    return constants_1.BOT_IDS.ERRO404;
}
/**
 * Posta resposta de crise com recursos de ajuda
 */
async function postCrisisResponse(postId, userId) {
    // Não usar bot, usar conta oficial
    const commentData = {
        postId: postId,
        userId: 'user_admin',
        userName: 'Odyssey Team',
        userPhotoUrl: 'https://i.pravatar.cc/150?u=odyssey',
        content: constants_1.CRISIS_RESPONSE,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await db.collection('posts').doc(postId)
        .collection('comments').add(commentData);
    await db.collection('posts').doc(postId).update({
        commentCount: admin.firestore.FieldValue.increment(1),
    });
    // Adicionar usuário à lista de atenção (não blocklist)
    await db.collection('crisis_alerts').add({
        userId: userId,
        postId: postId,
        detectedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending_review',
    });
    console.log('🆘 Crisis response posted and alert created');
}
/**
 * Busca perfil do bot
 */
async function getBotProfile(botId) {
    const profileDoc = await db.collection('users_public').doc(botId).get();
    if (profileDoc.exists) {
        return profileDoc.data();
    }
    const botName = botId.replace('bot_', '');
    return {
        displayName: botName.charAt(0).toUpperCase() + botName.slice(1),
        photoUrl: `https://api.dicebear.com/7.x/bottts/png?seed=${botName}`,
    };
}
//# sourceMappingURL=onNewPost.js.map