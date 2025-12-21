"use strict";
/**
 * Trigger: Post programado de bot (Cron)
 * Executa a cada 4 horas
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
exports.scheduledBotPost = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const aiService_1 = require("../ai/aiService");
const constants_1 = require("../config/constants");
const db = admin.firestore();
// Rotação de bots
const BOT_ROTATION = [
    constants_1.BOT_IDS.BEATNIX,
    constants_1.BOT_IDS.ERRO404,
    constants_1.BOT_IDS.WIKI,
    constants_1.BOT_IDS.TURBO,
];
/**
 * Cron job que executa a cada 4 horas
 * Schedule: 0 (asterisk)/4 (asterisk) (asterisk) (asterisk) = 00:00, 04:00, 08:00, 12:00, 16:00, 20:00
 */
exports.scheduledBotPost = functions.pubsub
    .schedule('0 */4 * * *')
    .timeZone('America/Sao_Paulo')
    .onRun(async (context) => {
    console.log('🤖 Running scheduled bot post...');
    // Verificar horário de silêncio
    const now = new Date();
    const hour = now.getHours();
    if (hour >= constants_1.QUIET_HOURS.START && hour < constants_1.QUIET_HOURS.END) {
        console.log(`😴 Quiet hours (${constants_1.QUIET_HOURS.START}h-${constants_1.QUIET_HOURS.END}h) - skipping`);
        return null;
    }
    // Verificar configurações
    const configDoc = await db.collection('bot_config').doc('settings').get();
    const config = configDoc.data();
    if (!config?.isActive || !config?.features?.autoPost) {
        console.log('❌ Bot posts disabled in config');
        return null;
    }
    // Verificar limite diário
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayPostsQuery = await db.collection('posts')
        .where('userId', 'in', BOT_ROTATION)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(todayStart))
        .get();
    if (todayPostsQuery.size >= constants_1.RATE_LIMITS.MAX_BOT_POSTS_PER_DAY) {
        console.log(`📊 Daily limit reached (${todayPostsQuery.size}/${constants_1.RATE_LIMITS.MAX_BOT_POSTS_PER_DAY})`);
        return null;
    }
    // Selecionar próximo bot na rotação
    const currentIndex = config.currentBotIndex || 0;
    const botId = BOT_ROTATION[currentIndex % BOT_ROTATION.length];
    const nextIndex = (currentIndex + 1) % BOT_ROTATION.length;
    console.log(`🎯 Selected bot: ${botId}`);
    // Gerar conteúdo
    const content = await (0, aiService_1.generateBotContent)(botId, { context: 'regular' });
    if (!content) {
        console.error('❌ Failed to generate content');
        return null;
    }
    // Adicionar delay aleatório (0-30 min) para parecer natural
    const delayMs = Math.floor(Math.random() * 30 * 60 * 1000);
    await new Promise(resolve => setTimeout(resolve, Math.min(delayMs, 5000))); // Max 5s em dev
    // Criar post
    const botProfile = await getBotProfile(botId);
    const postData = {
        userId: botId,
        userName: botProfile.displayName,
        userPhotoUrl: botProfile.photoUrl,
        userLevel: 99,
        authorFlair: constants_1.BOT_FLAIRS[botId],
        content: content,
        type: 'text',
        upvotes: 0,
        downvotes: 0,
        upvotedBy: [],
        downvotedBy: [],
        commentCount: 0,
        viewCount: 0,
        tags: [],
        categories: ['general'],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const postRef = await db.collection('posts').add(postData);
    console.log(`✅ Bot post created: ${postRef.id}`);
    // Atualizar config
    await db.collection('bot_config').doc('settings').update({
        currentBotIndex: nextIndex,
        lastBotPost: admin.firestore.FieldValue.serverTimestamp(),
        'stats.totalBotPosts': admin.firestore.FieldValue.increment(1),
    });
    // Log de atividade
    await db.collection('bot_activity_log').add({
        botId: botId,
        action: 'post',
        targetId: postRef.id,
        content: content.substring(0, 100),
        aiProvider: content.includes('Gemini') ? 'gemini' : 'template',
        success: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return null;
});
/**
 * Busca perfil do bot
 */
async function getBotProfile(botId) {
    const profileDoc = await db.collection('users_public').doc(botId).get();
    if (profileDoc.exists) {
        return profileDoc.data();
    }
    // Perfil padrão
    const botName = botId.replace('bot_', '');
    return {
        displayName: botName.charAt(0).toUpperCase() + botName.slice(1),
        photoUrl: `https://api.dicebear.com/7.x/bottts/png?seed=${botName}`,
        level: 99,
    };
}
//# sourceMappingURL=scheduledPosts.js.map