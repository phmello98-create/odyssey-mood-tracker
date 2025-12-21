"use strict";
/**
 * Endpoints HTTP para testes
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
exports.testBotPost = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const aiService_1 = require("../ai/aiService");
const constants_1 = require("../config/constants");
const db = admin.firestore();
/**
 * Endpoint para testar geração de post de bot
 * GET /testBotPost?botId=bot_beatnix
 */
exports.testBotPost = functions.https.onRequest(async (req, res) => {
    // CORS
    res.set('Access-Control-Allow-Origin', '*');
    if (req.method === 'OPTIONS') {
        res.set('Access-Control-Allow-Methods', 'GET');
        res.status(204).send('');
        return;
    }
    const botId = req.query.botId || constants_1.BOT_IDS.BEATNIX;
    const context = req.query.context || 'regular';
    const dryRun = req.query.dryRun !== 'false'; // Default: dry run (não posta de verdade)
    console.log(`🧪 Test bot post: ${botId} (context: ${context}, dryRun: ${dryRun})`);
    try {
        // Gerar conteúdo
        const content = await (0, aiService_1.generateBotContent)(botId, {
            context: context
        });
        if (!content) {
            res.status(500).json({
                success: false,
                error: 'Failed to generate content'
            });
            return;
        }
        const result = {
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
                authorFlair: constants_1.BOT_FLAIRS[botId] || '🤖 Bot',
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
    }
    catch (error) {
        console.error('Test error:', error);
        res.status(500).json({
            success: false,
            error: error.message,
        });
    }
});
//# sourceMappingURL=testEndpoints.js.map