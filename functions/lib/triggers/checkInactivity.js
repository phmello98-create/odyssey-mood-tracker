"use strict";
/**
 * Trigger: Verificar inatividade da comunidade
 * Executa a cada hora
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
exports.checkInactivity = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const aiService_1 = require("../ai/aiService");
const constants_1 = require("../config/constants");
const db = admin.firestore();
const BOT_ROTATION = [
    constants_1.BOT_IDS.BEATNIX,
    constants_1.BOT_IDS.ERRO404,
    constants_1.BOT_IDS.WIKI,
    constants_1.BOT_IDS.TURBO,
];
/**
 * Cron job que executa a cada hora
 * Verifica se a comunidade está inativa e posta para "quebrar o gelo"
 */
exports.checkInactivity = functions.pubsub
    .schedule('0 * * * *') // A cada hora
    .timeZone('America/Sao_Paulo')
    .onRun(async (context) => {
    console.log('🔍 Checking community inactivity...');
    // Verificar horário de silêncio
    const now = new Date();
    const hour = now.getHours();
    if (hour >= constants_1.QUIET_HOURS.START && hour < constants_1.QUIET_HOURS.END) {
        console.log(`😴 Quiet hours - skipping inactivity check`);
        return null;
    }
    // Verificar configurações
    const configDoc = await db.collection('bot_config').doc('settings').get();
    const config = configDoc.data();
    if (!config?.isActive) {
        console.log('❌ Bots disabled');
        return null;
    }
    // Calcular tempo desde último post humano
    const postsQuery = await db.collection('posts')
        .orderBy('createdAt', 'desc')
        .limit(10)
        .get();
    if (postsQuery.empty) {
        console.log('📭 No posts found - triggering inactivity post');
        await createInactivityPost(config);
        return null;
    }
    // Encontrar último post humano (não-bot)
    let lastHumanPostTime = null;
    for (const doc of postsQuery.docs) {
        const post = doc.data();
        if (!post.userId.startsWith('bot_')) {
            lastHumanPostTime = post.createdAt?.toDate();
            break;
        }
    }
    if (!lastHumanPostTime) {
        console.log('📭 No human posts found - triggering inactivity post');
        await createInactivityPost(config);
        return null;
    }
    // Calcular horas desde último post humano
    const hoursSinceLastPost = (Date.now() - lastHumanPostTime.getTime()) / (1000 * 60 * 60);
    console.log(`⏰ Hours since last human post: ${hoursSinceLastPost.toFixed(1)}`);
    if (hoursSinceLastPost < constants_1.RATE_LIMITS.INACTIVITY_THRESHOLD_HOURS) {
        console.log(`✅ Community active (threshold: ${constants_1.RATE_LIMITS.INACTIVITY_THRESHOLD_HOURS}h)`);
        return null;
    }
    // Verificar se bot já postou recentemente (últimas 2h)
    const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
    const recentBotPostsQuery = await db.collection('posts')
        .where('userId', 'in', BOT_ROTATION)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(twoHoursAgo))
        .limit(1)
        .get();
    if (!recentBotPostsQuery.empty) {
        console.log('🤖 Bot already posted recently - skipping');
        return null;
    }
    console.log('🎯 Inactivity detected - creating post');
    await createInactivityPost(config);
    return null;
});
/**
 * Cria um post para quebrar a inatividade
 */
async function createInactivityPost(config) {
    // Selecionar próximo bot na rotação
    const currentIndex = config?.currentBotIndex || 0;
    const botId = BOT_ROTATION[currentIndex % BOT_ROTATION.length];
    const nextIndex = (currentIndex + 1) % BOT_ROTATION.length;
    console.log(`🎯 Selected bot: ${botId}`);
    // Gerar conteúdo específico para quebrar o gelo
    const content = await (0, aiService_1.generateBotContent)(botId, { context: 'inactivity_breaker' });
    if (!content) {
        console.error('❌ Failed to generate inactivity content');
        return;
    }
    // Buscar perfil do bot
    const profileDoc = await db.collection('users_public').doc(botId).get();
    const botProfile = profileDoc.exists
        ? profileDoc.data()
        : {
            displayName: botId.replace('bot_', '').charAt(0).toUpperCase() + botId.replace('bot_', '').slice(1),
            photoUrl: `https://api.dicebear.com/7.x/bottts/png?seed=${botId.replace('bot_', '')}`,
        };
    // Criar post
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
        metadata: { inactivityBreaker: true },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    const postRef = await db.collection('posts').add(postData);
    console.log(`✅ Inactivity post created: ${postRef.id}`);
    // Atualizar config
    await db.collection('bot_config').doc('settings').update({
        currentBotIndex: nextIndex,
        lastBotPost: admin.firestore.FieldValue.serverTimestamp(),
        'stats.totalBotPosts': admin.firestore.FieldValue.increment(1),
    });
    // Log
    await db.collection('bot_activity_log').add({
        botId: botId,
        action: 'post',
        targetId: postRef.id,
        content: content.substring(0, 100),
        context: 'inactivity_breaker',
        success: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
//# sourceMappingURL=checkInactivity.js.map