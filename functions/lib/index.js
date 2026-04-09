"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.expressApp = exports.api = void 0;
const admin = __importStar(require("firebase-admin"));
const express_1 = __importDefault(require("express"));
const functions = __importStar(require("firebase-functions"));
const logger = __importStar(require("firebase-functions/logger"));
const simple_rate_limiter_1 = require("./middleware/simple-rate-limiter");
const logger_1 = require("./utils/logger");
// Initialize Admin SDK once
try {
    admin.app();
}
catch {
    admin.initializeApp();
}
const app = (0, express_1.default)();
// CORS middleware - Allow localhost for development
app.use((req, res, next) => {
    const origin = req.headers.origin || '';
    const allowedOrigins = [
        'http://localhost:50652',
        'https://paperclip-98294.web.app',
        'https://paperclip-98294.firebaseapp.com'
    ];
    // Allow all localhost ports
    if (origin.startsWith('http://localhost:') || allowedOrigins.includes(origin)) {
        res.setHeader('Access-Control-Allow-Origin', origin);
        res.setHeader('Access-Control-Allow-Credentials', 'true');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    }
    // Handle preflight
    if (req.method === 'OPTIONS') {
        return res.status(204).end();
    }
    next();
});
app.use(express_1.default.json({ limit: '1mb' }));
// Apply global rate limiting (300 req/min par IP)
app.use((0, simple_rate_limiter_1.simpleRateLimiter)(300, 60 * 1000));
// Middleware de métriques HTTP
app.use((req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        const uid = req.uid || 'anonymous';
        logger_1.StructuredLogger.info('HTTP Request', {
            method: req.method,
            path: req.path,
            status: res.statusCode,
            duration,
            uid,
        });
    });
    next();
});
// Middleware: verify Firebase ID Token
async function verifyFirebaseIdToken(req, res, next) {
    try {
        const h = (req.header('Authorization') || '').trim();
        if (!h.toLowerCase().startsWith('bearer ')) {
            return res.status(401).json({ error: 'missing_or_invalid_authorization' });
        }
        const token = h.split(' ', 2)[1];
        const decoded = await admin.auth().verifyIdToken(token);
        req.uid = decoded.uid;
        return next();
    }
    catch (e) {
        logger.warn('auth_failed', { msg: String(e?.message || e) });
        return res.status(401).json({ error: 'auth_failed' });
    }
}
// Helpers
const UUID_V4_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
function isValidUuidV4(id) {
    return UUID_V4_RE.test(id);
}
function isPlainObject(v) {
    return !!v && typeof v === 'object' && !Array.isArray(v);
}
function isValidISODate(dateStr) {
    try {
        const date = new Date(dateStr);
        return !isNaN(date.getTime()) && date.toISOString() === dateStr;
    }
    catch {
        return false;
    }
}
function validateSnapshotV3(snapshot, enterpriseId) {
    // Vérifier structure de base
    if (!isPlainObject(snapshot.metadata)) {
        return { valid: false, error: 'metadata must be an object' };
    }
    if (!isPlainObject(snapshot.core)) {
        return { valid: false, error: 'core must be an object' };
    }
    if (!isPlainObject(snapshot.stats)) {
        return { valid: false, error: 'stats must be an object and is required' };
    }
    // Vérifier sections optionnelles
    if (snapshot.market !== undefined && !isPlainObject(snapshot.market)) {
        return { valid: false, error: 'market must be an object if present' };
    }
    if (snapshot.production !== undefined && !isPlainObject(snapshot.production)) {
        return { valid: false, error: 'production must be an object if present' };
    }
    // Vérifier metadata obligatoires
    const meta = snapshot.metadata;
    if (typeof meta.version !== 'number' || meta.version !== 3) {
        return { valid: false, error: 'metadata.version must be 3' };
    }
    if (typeof meta.enterpriseId !== 'string' || !meta.enterpriseId.trim()) {
        return { valid: false, error: 'metadata.enterpriseId required and non-empty' };
    }
    // Vérifier cohérence enterpriseId
    if (meta.enterpriseId !== enterpriseId) {
        return { valid: false, error: 'metadata.enterpriseId must match payload enterpriseId' };
    }
    if (typeof meta.createdAt !== 'string' || !isValidISODate(meta.createdAt)) {
        return { valid: false, error: 'metadata.createdAt must be valid ISO date' };
    }
    if (typeof meta.lastModified !== 'string' || !isValidISODate(meta.lastModified)) {
        return { valid: false, error: 'metadata.lastModified must be valid ISO date' };
    }
    return { valid: true };
}
// Routes
// Health (optionnel)
app.get('/health', (_req, res) => res.json({ status: 'ok' }));
// POST /analytics/events
app.post('/analytics/events', verifyFirebaseIdToken, async (req, res) => {
    const uid = req.uid;
    const { name, properties, timestamp } = req.body || {};
    if (!name || typeof name !== 'string') {
        return res.status(400).json({ error: 'invalid_event' });
    }
    const db = admin.firestore();
    try {
        const ref = db.collection('players').doc(uid).collection('analytics').doc();
        await ref.set({
            name,
            properties: properties ?? null,
            timestamp: timestamp ? admin.firestore.Timestamp.fromDate(new Date(timestamp)) : null,
            receivedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info('analytics_event_ok', { uid, name });
        return res.status(202).end();
    }
    catch (e) {
        logger.warn('analytics_event_failed', { uid, err: String(e?.message || e) });
        return res.status(202).end(); // best-effort: ne bloque pas le gameplay
    }
});
// CHANTIER-01 : Nouveaux endpoints pour entreprise unique
// GET /enterprise/:uid - Récupère l'entreprise de l'utilisateur
app.get('/enterprise/:uid', verifyFirebaseIdToken, async (req, res) => {
    const uid = req.uid;
    const requestedUid = String(req.params.uid || '').trim();
    // Vérifier que l'utilisateur demande bien sa propre entreprise
    if (uid !== requestedUid) {
        return res.status(403).json({ error: 'forbidden' });
    }
    try {
        const db = admin.firestore();
        const enterpriseRef = db.collection('enterprises').doc(uid);
        const doc = await enterpriseRef.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'enterprise_not_found' });
        }
        const data = doc.data();
        const snapshot = data?.snapshot;
        const updatedAt = data?.updatedAt?.toDate?.()?.toISOString() ?? null;
        return res.json({
            enterprise_id: data?.enterpriseId,
            version: 1,
            snapshot: snapshot,
            updated_at: updatedAt,
            name: snapshot?.metadata?.enterpriseName ?? null,
            game_version: snapshot?.metadata?.gameVersion ?? null,
            game_mode: snapshot?.metadata?.gameMode ?? null,
        });
    }
    catch (e) {
        logger.error('get_enterprise_failed', { uid, err: String(e?.message || e) });
        return res.status(500).json({ error: 'get_enterprise_failed' });
    }
});
// PUT /enterprise/:uid - Sauvegarde l'entreprise
app.put('/enterprise/:uid', verifyFirebaseIdToken, async (req, res) => {
    const uid = req.uid;
    const requestedUid = String(req.params.uid || '').trim();
    // LOG CRITIQUE: Inspecter le body reçu
    logger.error('DEBUG_PUT_BODY', {
        uid,
        requestedUid,
        bodyType: typeof req.body,
        bodyKeys: req.body ? Object.keys(req.body) : [],
        bodyStringified: JSON.stringify(req.body).substring(0, 200)
    });
    const { enterpriseId, snapshot } = req.body || {};
    if (uid !== requestedUid) {
        return res.status(403).json({ error: 'forbidden' });
    }
    if (!enterpriseId || !snapshot) {
        logger.error('MISSING_DATA', {
            hasEnterpriseId: !!enterpriseId,
            hasSnapshot: !!snapshot
        });
        return res.status(400).json({ error: 'missing_data' });
    }
    if (!isValidUuidV4(enterpriseId)) {
        return res.status(400).json({ error: 'invalid_enterprise_id' });
    }
    // Validation complète du snapshot v3
    const validation = validateSnapshotV3(snapshot, enterpriseId);
    if (!validation.valid) {
        logger.error('snapshot_validation_failed', {
            uid,
            enterpriseId,
            validationError: validation.error,
            snapshotMetadata: snapshot.metadata || 'missing'
        });
        return res.status(400).json({
            error: 'invalid_snapshot',
            details: validation.error
        });
    }
    try {
        const db = admin.firestore();
        const enterpriseRef = db.collection('enterprises').doc(uid);
        await enterpriseRef.set({
            enterpriseId,
            snapshot,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        // Récupérer le document mis à jour pour retourner la réponse complète
        const doc = await enterpriseRef.get();
        const data = doc.data();
        const updatedAt = data?.updatedAt?.toDate?.()?.toISOString() ?? new Date().toISOString();
        logger.info('enterprise_saved', { uid, enterpriseId });
        return res.json({
            enterprise_id: enterpriseId,
            version: 1,
            snapshot: snapshot,
            updated_at: updatedAt,
            name: snapshot.metadata?.enterpriseName ?? null,
            game_version: snapshot.metadata?.gameVersion ?? null,
            game_mode: snapshot.metadata?.gameMode ?? null,
        });
    }
    catch (e) {
        logger.error('save_enterprise_failed', { uid, err: String(e?.message || e) });
        return res.status(500).json({ error: 'save_enterprise_failed' });
    }
});
// DELETE /enterprise/:uid - Supprime l'entreprise (testeurs uniquement)
app.delete('/enterprise/:uid', verifyFirebaseIdToken, async (req, res) => {
    const uid = req.uid;
    const requestedUid = String(req.params.uid || '').trim();
    if (uid !== requestedUid) {
        return res.status(403).json({ error: 'forbidden' });
    }
    try {
        const db = admin.firestore();
        await db.collection('enterprises').doc(uid).delete();
        logger.info('enterprise_deleted', { uid });
        return res.status(204).end();
    }
    catch (e) {
        logger.error('delete_enterprise_failed', { uid, err: String(e?.message || e) });
        return res.status(500).json({ error: 'delete_enterprise_failed' });
    }
});
// Export Firebase Functions (Gen1)
exports.api = functions.https.onRequest(app);
exports.expressApp = app;
