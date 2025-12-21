/**
 * Endpoints HTTP para testes
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { generateBotContent } from '../ai/aiService';
import { BOT_IDS, BOT_FLAIRS } from '../config/constants';

const db = admin.firestore();

/**
 * Endpoint para testar geração de post de bot
 * GET /testBotPost?botId=bot_beatnix
 */
export const testBotPost = functions.https.onRequest(async (req, res) => {
    // CORS
    res.set('Access-Control-Allow-Origin', '*');

    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'GET');
        res.status(204).send('');
        return;
    }

    const botId = req.query.botId as string || BOT_IDS.BEATNIX;
    const context = req.query.context as string || 'regular';
    const dryRun = req.query.dryRun !== 'false'; // Default: dry run (não posta de verdade)

    console.log(`🧪 Test bot post: ${botId} (context: ${context}, dryRun: ${dryRun})`);

    try {
        // Gerar conteúdo
        const content = await generateBotContent(botId, {
            context: context as any
        });

        if (!content) {
            res.status(500).json({
                success: false,
                error: 'Failed to generate content'
            });
            return;
        }

        const result: any = {
            success: true,
            botId: botId,
            content: content,
            context: context,
            dryRun: dryRun,
            timestamp: new Date().toISOString(),
        };

        // Se não for dry run, criar post de verdade
        if (!dryRun) {
            const postData = {
                userId: botId,
                userName: botId.replace('bot_', '').charAt(0).toUpperCase() + botId.replace('bot_', '').slice(1),
                userPhotoUrl: `https://api.dicebear.com/7.x/bottts/png?seed=${botId.replace('bot_', '')}`,
                userLevel: 99,
                authorFlair: (BOT_FLAIRS as Record<string, string>)[botId] || '🤖 Bot',
                content: content,
                type: 'text',
                upvotes: 0,
                downvotes: 0,
                upvotedBy: [],
                downvotedBy: [],
                commentCount: 0,
                viewCount: 0,
                tags: ['test'],
                categories: ['general'],
                metadata: { test: true },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            };

            const postRef = await db.collection('posts').add(postData);
            result.postId = postRef.id;
            result.message = 'Post created successfully';
        }

        res.json(result);
    } catch (error: any) {
        console.error('Test error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
        });
    }
});
