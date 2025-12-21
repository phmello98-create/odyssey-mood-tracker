"use strict";
/**
 * Script para inicializar configurações dos bots no Firestore
 * Execute uma vez após deploy: node lib/scripts/seedBotConfig.js
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
exports.seedBotConfig = seedBotConfig;
const admin = __importStar(require("firebase-admin"));
// Inicializar se ainda não foi
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = admin.firestore();
/**
 * Perfis dos 4 bots
 */
const BOT_PROFILES = [
    {
        userId: 'bot_beatnix',
        displayName: 'Beatnix',
        photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=beatnix&backgroundColor=6366f1',
        level: 99,
        totalXP: 999999,
        badges: ['bot_official', 'music_curator'],
        bio: '🎧 Curador musical do Odyssey | Viciado em café e frequências baixas | Bot Oficial',
        isBot: true,
        botType: 'music_curator',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
        userId: 'bot_erro404',
        displayName: 'Erro 404',
        photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=erro404&backgroundColor=10b981',
        level: 99,
        totalXP: 999999,
        badges: ['bot_official', 'comedian'],
        bio: '🤖 Estagiário de Silício | Tentando entender humanos desde 2024 | Bugs existenciais inclusos',
        isBot: true,
        botType: 'humor',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
        userId: 'bot_wiki',
        displayName: 'Wiki',
        photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=wiki&backgroundColor=8b5cf6',
        level: 99,
        totalXP: 999999,
        badges: ['bot_official', 'knowledge_seeker'],
        bio: '🧠 Banco de Dados Vivo | Curiosidades que fazem você parar e pensar | Fatos > Opiniões',
        isBot: true,
        botType: 'curiosities',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
    },
    {
        userId: 'bot_turbo',
        displayName: 'Turbo',
        photoUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=turbo&backgroundColor=f59e0b',
        level: 99,
        totalXP: 999999,
        badges: ['bot_official', 'motivator', 'challenge_master'],
        bio: '⚡ Gerente de Caos | Desafios, XP e muita energia | Se você não tá suando, não tá tentando',
        isBot: true,
        botType: 'gamification',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
    },
];
/**
 * Configurações globais dos bots
 */
const BOT_CONFIG = {
    isActive: true,
    globalResponseRate: 0.3,
    maxBotPostsPerDay: 12,
    maxBotResponsesPerHour: 5,
    inactivityThresholdHours: 6,
    quietHours: {
        start: 3,
        end: 7,
    },
    peakHours: [8, 9, 10, 12, 13, 14, 19, 20, 21, 22],
    botRotation: ['bot_beatnix', 'bot_erro404', 'bot_wiki', 'bot_turbo'],
    currentBotIndex: 0,
    features: {
        autoPost: true,
        autoRespond: true,
        sentimentAnalysis: true,
        geminiEnabled: true,
        huggingfaceEnabled: true,
    },
    stats: {
        totalBotPosts: 0,
        totalBotResponses: 0,
        avgEngagementRate: 0,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
};
/**
 * Executa o seed
 */
async function seedBotConfig() {
    console.log('🤖 Seeding bot configuration...\n');
    // Criar perfis dos bots
    console.log('📝 Creating bot profiles...');
    for (const profile of BOT_PROFILES) {
        await db.collection('users_public').doc(profile.userId).set(profile, { merge: true });
        console.log(`  ✅ ${profile.displayName}`);
    }
    // Criar configurações
    console.log('\n⚙️ Creating bot config...');
    await db.collection('bot_config').doc('settings').set(BOT_CONFIG, { merge: true });
    console.log('  ✅ Settings saved');
    console.log('\n🎉 Bot configuration seeded successfully!');
    console.log('\nNext steps:');
    console.log('1. Set GEMINI_API_KEY in Firebase environment');
    console.log('2. Set HUGGINGFACE_API_KEY in Firebase environment');
    console.log('3. Deploy functions: firebase deploy --only functions');
}
// Executar se chamado diretamente
if (require.main === module) {
    seedBotConfig()
        .then(() => process.exit(0))
        .catch((error) => {
        console.error('Error:', error);
        process.exit(1);
    });
}
//# sourceMappingURL=seedBotConfig.js.map