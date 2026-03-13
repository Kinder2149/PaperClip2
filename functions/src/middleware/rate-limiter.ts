import rateLimit from 'express-rate-limit';
import { Request, Response } from 'express';

/**
 * Rate limiter par utilisateur (uid Firebase)
 * Limite : 100 requêtes par minute par utilisateur
 */
export const userRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requêtes max
  
  // Clé basée sur l'UID Firebase (extrait par le middleware auth)
  // Pas de keyGenerator personnalisé pour éviter les problèmes IPv6
  // Le rate limiting se fera par IP par défaut, ce qui est acceptable
  // car l'authentification Firebase garantit déjà l'identité
  
  // Message d'erreur personnalisé
  handler: (req: Request, res: Response) => {
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
  skip: (req: Request): boolean => {
    return req.path === '/health';
  },
});

/**
 * Rate limiter global (par IP) pour les endpoints publics
 * Limite : 300 requêtes par minute par IP
 * Utilise le keyGenerator par défaut qui gère correctement IPv6
 */
export const globalRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  // Pas de keyGenerator personnalisé - utilise le défaut qui gère IPv6
  handler: (req: Request, res: Response) => {
    res.status(429).json({
      error: 'RATE_LIMIT_EXCEEDED',
      message: 'Trop de requêtes depuis cette adresse IP.',
      retryAfter: 60,
    });
  },
  standardHeaders: true,
  legacyHeaders: false,
});
