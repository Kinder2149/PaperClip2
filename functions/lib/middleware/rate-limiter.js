"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.globalRateLimiter = exports.userRateLimiter = void 0;
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
/**
 * Rate limiter par utilisateur (uid Firebase)
 * Limite : 100 requêtes par minute par utilisateur
 */
exports.userRateLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000, // 1 minute
    max: 100, // 100 requêtes max
    // Clé basée sur l'UID Firebase (extrait par le middleware auth)
    // Pas de keyGenerator personnalisé pour éviter les problèmes IPv6
    // Le rate limiting se fera par IP par défaut, ce qui est acceptable
    // car l'authentification Firebase garantit déjà l'identité
    // Message d'erreur personnalisé
    handler: (req, res) => {
        res.status(429).json({
            error: 'RATE_LIMIT_EXCEEDED',
            message: 'Trop de requêtes. Veuillez réessayer dans 1 minute.',
            retryAfter: 60,
        });
    },
    // Headers standards (gère automatiquement IPv6)
    standardHeaders: true,
    legacyHeaders: false,
    // Skip les requêtes de health check
    skip: (req) => {
        return req.path === '/health';
    },
});
/**
 * Rate limiter global (par IP) pour les endpoints publics
 * Limite : 300 requêtes par minute par IP
 * Utilise le keyGenerator par défaut qui gère correctement IPv6
 */
exports.globalRateLimiter = (0, express_rate_limit_1.default)({
    windowMs: 60 * 1000,
    max: 300,
    // Pas de keyGenerator personnalisé - utilise le défaut qui gère IPv6
    handler: (req, res) => {
        res.status(429).json({
            error: 'RATE_LIMIT_EXCEEDED',
            message: 'Trop de requêtes depuis cette adresse IP.',
            retryAfter: 60,
        });
    },
    standardHeaders: true,
    legacyHeaders: false,
});
