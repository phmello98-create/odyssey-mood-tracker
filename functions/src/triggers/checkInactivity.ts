/**
 * Trigger: Verificar inatividade da comunidade
 * Executa a cada hora
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { generateBotContent } from '../ai/aiService';
import { BOT_IDS, QUIET_HOURS, RATE_LIMITS, BOT_FLAIRS } from '../config/constants';

const db = admin.firestore();

const BOT_ROTATION = [
    BOT_IDS.BEATNIX,
    BOT_IDS.ERRO404,
    BOT_IDS.WIKI,
    BOT_IDS.TURBO,
];

/**
 * Cron job que executa a cada hora
 * Verifica se a comunidade está inativa e posta para "quebrar o gelo"
 */
export const checkInactivity = functions.pubsub
    .schedule('0 * * * *') // A cada hora
    .timeZone('America/Sao_Paulo')
    .onRun(async (context) => {
        console.log('🔍 Checking community inactivity...');

        // Verificar horário de silêncio
        const now = new Date();
        const hour = now.getHours();

        if (hour >= QUIET_HOURS.START && hour < QUIET_HOURS.END) {
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
        let lastHumanPostTime: Date | null = null;

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

        if (hoursSinceLastPost < RATE_LIMITS.INACTIVITY_THRESHOLD_HOURS) {
            console.log(`✅ Community active (threshold: ${RATE_LIMITS.INACTIVITY_THRESHOLD_HOURS}h)`);
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
async function createInactivityPost(config: any): Promise<void> {
    // Selecionar próximo bot na rotação
    const currentIndex = config?.currentBotIndex || 0;
    const botId = BOT_ROTATION[currentIndex % BOT_ROTATION.length];
    const nextIndex = (currentIndex + 1) % BOT_ROTATION.length;

    console.log(`🎯 Selected bot: ${botId}`);

    // Gerar conteúdo específico para quebrar o gelo
    const content = await generateBotContent(botId, { context: 'inactivity_breaker' });

    if (!content) {
        console.error('❌ Failed to generate inactivity content');
        return;
    }

    // Buscar perfil do bot
    const profileDoc = await db.collection('users_public').doc(botId).get();
    const botProfile = profileDoc.exists
        ? profileDoc.data()!
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
        authorFlair: BOT_FLAIRS[botId],
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
