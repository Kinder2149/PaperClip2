"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.simpleRateLimiter = simpleRateLimiter;
const requestCounts = new Map();
// Nettoyage périodique des anciennes entrées (toutes les 5 minutes)
setInterval(() => {
    const now = Date.now();
    for (const [key, record] of requestCounts.entries()) {
        if (now > record.resetAt) {
            requestCounts.delete(key);
        }
    }
}, 5 * 60 * 1000);
/**
 * Crée un middleware de rate limiting simple
 * @param max Nombre maximum de requêtes
 * @param windowMs Fenêtre de temps en millisecondes
 */
function simpleRateLimiter(max, windowMs) {
    return (req, res, next) => {
        // Skip health check
        if (req.path === '/health') {
            return next();
        }
        const key = req.ip || 'unknown';
        const now = Date.now();
        let record = requestCounts.get(key);
        // Créer ou réinitialiser le compteur
        if (!record || now > record.resetAt) {
            record = { count: 0, resetAt: now + windowMs };
            requestCounts.set(key, record);
        }
        record.count++;
        // Vérifier la limite
        if (record.count > max) {
            const retryAfter = Math.ceil((record.resetAt - now) / 1000);
            res.setHeader('RateLimit-Limit', max.toString());
            res.setHeader('RateLimit-Remaining', '0');
            res.setHeader('RateLimit-Reset', record.resetAt.toString());
            res.setHeader('Retry-After', retryAfter.toString());
            return res.status(429).json({
                error: 'RATE_LIMIT_EXCEEDED',
                message: 'Trop de requêtes. Veuillez réessayer plus tard.',
                retryAfter,
            });
        }
        // Ajouter les headers informatifs
        res.setHeader('RateLimit-Limit', max.toString());
        res.setHeader('RateLimit-Remaining', (max - record.count).toString());
        res.setHeader('RateLimit-Reset', record.resetAt.toString());
        next();
    };
}
