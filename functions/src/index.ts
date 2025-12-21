/**
 * ODYSSEY BOT FUNCTIONS
 * 
 * Sistema de bots inteligentes para a comunidade Odyssey
 * Usa Gemini + HuggingFace com fallback automático
 */

import * as admin from 'firebase-admin';

// Inicializar Firebase Admin
admin.initializeApp();

// Exportar triggers
export { scheduledBotPost } from './triggers/scheduledPosts';
export { onNewPost } from './triggers/onNewPost';
export { checkInactivity } from './triggers/checkInactivity';

// Exportar funções HTTP (para testes)
export { testBotPost } from './http/testEndpoints';
