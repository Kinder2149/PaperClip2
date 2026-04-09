import * as admin from 'firebase-admin';
import express, { Request, Response, NextFunction } from 'express';
import * as functions from 'firebase-functions';
import * as logger from 'firebase-functions/logger';
import type { Transaction } from 'firebase-admin/firestore';
import { simpleRateLimiter } from './middleware/simple-rate-limiter';
import { StructuredLogger } from './utils/logger';

// Initialize Admin SDK once
try {
  admin.app();
} catch {
  admin.initializeApp();
}

const app = express();

// CORS middleware - Allow localhost for development
app.use((req: Request, res: Response, next: NextFunction) => {
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

app.use(express.json({ limit: '1mb' }));

// Apply global rate limiting (300 req/min par IP)
app.use(simpleRateLimiter(300, 60 * 1000));

// Middleware de métriques HTTP
app.use((req: Request, res: Response, next: NextFunction) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const uid = (req as any).uid || 'anonymous';
    
    StructuredLogger.info('HTTP Request', {
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
async function verifyFirebaseIdToken(req: Request, res: Response, next: NextFunction) {
  try {
    const h = (req.header('Authorization') || '').trim();
    if (!h.toLowerCase().startsWith('bearer ')) {
      return res.status(401).json({ error: 'missing_or_invalid_authorization' });
    }
    const token = h.split(' ', 2)[1];
    const decoded = await admin.auth().verifyIdToken(token);
    (req as any).uid = decoded.uid;
    return next();
  } catch (e: any) {
    logger.warn('auth_failed', { msg: String(e?.message || e) });
    return res.status(401).json({ error: 'auth_failed' });
  }
}

// Helpers
const UUID_V4_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isValidUuidV4(id: string): boolean {
  return UUID_V4_RE.test(id);
}

function isPlainObject(v: any): v is Record<string, any> {
  return !!v && typeof v === 'object' && !Array.isArray(v);
}

function isValidISODate(dateStr: string): boolean {
  try {
    const date = new Date(dateStr);
    return !isNaN(date.getTime()) && date.toISOString() === dateStr;
  } catch {
    return false;
  }
}

function validateSnapshotV3(snapshot: any, enterpriseId: string): { valid: boolean; error?: string } {
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
app.get('/health', (_req: Request, res: Response) => res.json({ status: 'ok' }));

// POST /analytics/events
app.post('/analytics/events', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
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
  } catch (e: any) {
    logger.warn('analytics_event_failed', { uid, err: String(e?.message || e) });
    return res.status(202).end(); // best-effort: ne bloque pas le gameplay
  }
});

// CHANTIER-01 : Nouveaux endpoints pour entreprise unique

// GET /enterprise/:uid - Récupère l'entreprise de l'utilisateur
app.get('/enterprise/:uid', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
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
      name: (snapshot?.metadata?.enterpriseName as string) ?? null,
      game_version: (snapshot?.metadata?.gameVersion as string) ?? null,
      game_mode: (snapshot?.metadata?.gameMode as string) ?? null,
    });
  } catch (e: any) {
    logger.error('get_enterprise_failed', { uid, err: String(e?.message || e) });
    return res.status(500).json({ error: 'get_enterprise_failed' });
  }
});

// PUT /enterprise/:uid - Sauvegarde l'entreprise
app.put('/enterprise/:uid', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
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
      name: (snapshot.metadata?.enterpriseName as string) ?? null,
      game_version: (snapshot.metadata?.gameVersion as string) ?? null,
      game_mode: (snapshot.metadata?.gameMode as string) ?? null,
    });
  } catch (e: any) {
    logger.error('save_enterprise_failed', { uid, err: String(e?.message || e) });
    return res.status(500).json({ error: 'save_enterprise_failed' });
  }
});

// DELETE /enterprise/:uid - Supprime l'entreprise (testeurs uniquement)
app.delete('/enterprise/:uid', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const requestedUid = String(req.params.uid || '').trim();
  
  if (uid !== requestedUid) {
    return res.status(403).json({ error: 'forbidden' });
  }
  
  try {
    const db = admin.firestore();
    await db.collection('enterprises').doc(uid).delete();
    
    logger.info('enterprise_deleted', { uid });
    return res.status(204).end();
  } catch (e: any) {
    logger.error('delete_enterprise_failed', { uid, err: String(e?.message || e) });
    return res.status(500).json({ error: 'delete_enterprise_failed' });
  }
});

// Export Firebase Functions (Gen1)
export const api = functions.https.onRequest(app);

export const expressApp = app;
