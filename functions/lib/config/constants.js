"use strict";
/**
 * Configurações e constantes do sistema de bots
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.BOT_FLAIRS = exports.BOT_COLORS = exports.CRISIS_RESPONSE = exports.CRISIS_KEYWORDS = exports.DELAYS = exports.PEAK_HOURS = exports.QUIET_HOURS = exports.RATE_LIMITS = exports.BOT_IDS = void 0;
// IDs dos bots
exports.BOT_IDS = {
    BEATNIX: 'bot_beatnix',
    ERRO404: 'bot_erro404',
    WIKI: 'bot_wiki',
    TURBO: 'bot_turbo',
};
// Configurações de rate limiting
exports.RATE_LIMITS = {
    MAX_BOT_POSTS_PER_DAY: 12,
    MAX_BOT_RESPONSES_PER_HOUR: 5,
    GLOBAL_RESPONSE_RATE: 0.3, // 30% chance de responder
    INACTIVITY_THRESHOLD_HOURS: 6,
};
// Horários de silêncio (não postar)
exports.QUIET_HOURS = {
    START: 3, // 3:00 AM
    END: 7, // 7:00 AM
};
// Horários de pico (maior atividade)
exports.PEAK_HOURS = [8, 9, 10, 12, 13, 14, 19, 20, 21, 22];
// Delays para parecer natural
exports.DELAYS = {
    MIN_RESPONSE_MINUTES: 2,
    MAX_RESPONSE_MINUTES: 10,
    MIN_POST_VARIATION_MINUTES: 0,
    MAX_POST_VARIATION_MINUTES: 30,
};
// Palavras-chave de crise (não responder, mostrar recursos)
exports.CRISIS_KEYWORDS = [
    'suicídio', 'suicidio', 'me matar', 'não aguento mais',
    'quero morrer', 'acabar com tudo', 'não vejo saída',
    'automutilação', 'automutilaçao', 'cutting', 'self-harm',
    'vou me matar', 'desisto de tudo', 'não aguento',
];
// Mensagem de recursos de crise
exports.CRISIS_RESPONSE = `💙 Você não está sozinho.

Se você está passando por um momento difícil, ligue para:
📞 CVV: 188 (24h, gratuito)
💬 Chat: www.cvv.org.br

Profissionais estão prontos para ouvir você. ❤️`;
// Cores temáticas dos bots
exports.BOT_COLORS = {
    [exports.BOT_IDS.BEATNIX]: '#6366F1', // Indigo
    [exports.BOT_IDS.ERRO404]: '#10B981', // Emerald
    [exports.BOT_IDS.WIKI]: '#8B5CF6', // Violet
    [exports.BOT_IDS.TURBO]: '#F59E0B', // Amber
};
// Flairs dos bots
exports.BOT_FLAIRS = {
    [exports.BOT_IDS.BEATNIX]: '🎧 Robô Residente',
    [exports.BOT_IDS.ERRO404]: '🤖 Estagiário de Silício',
    [exports.BOT_IDS.WIKI]: '🧠 Banco de Dados Vivo',
    [exports.BOT_IDS.TURBO]: '⚡ Gerente de Caos',
};
//# sourceMappingURL=constants.js.map