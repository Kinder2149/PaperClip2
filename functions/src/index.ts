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

// Routes
// Health (optionnel)
app.get('/health', (_req: Request, res: Response) => res.json({ status: 'ok' }));

// --- Alias /worlds (API stable produit) ---
// PUT /worlds/:worldId → identique à PUT /saves/:partieId, étendu pour persister name et game_version
app.put('/worlds/:worldId', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const worldId = String(req.params.worldId || '').trim();
  const { snapshot, expected_version } = req.body || {};
  // Champs facultatifs pour compatibilité ascendante: accepter game_version ou gameVersion
  const name: unknown = (req.body || {}).name;
  const gameVersionInput: unknown = (req.body || {}).game_version ?? (req.body || {}).gameVersion;

  if (!isValidUuidV4(worldId)) {
    return res.status(400).json({ error: 'invalid_world_id' });
  }
  if (!snapshot || !isPlainObject(snapshot)) {
    return res.status(400).json({ error: 'invalid_snapshot' });
  }
  const metadata = snapshot.metadata;
  const core = snapshot.core;
  const stats = snapshot.stats;
  if (!isPlainObject(metadata) || !isPlainObject(core) || !isPlainObject(stats)) {
    return res.status(400).json({ error: 'invalid_snapshot_structure' });
  }
  const metaPid = metadata.partieId ?? metadata.partie_id ?? metadata.worldId ?? metadata.world_id;
  if (!metaPid || typeof metaPid !== 'string') {
    return res.status(422).json({ error: 'metadata_world_id_missing' });
  }
  // P0-2: Validation UUID v4 format pour metadata.worldId
  if (!isValidUuidV4(String(metaPid))) {
    return res.status(422).json({ 
      error: 'metadata_world_id_invalid_format',
      details: 'metadata.worldId must be a valid UUID v4',
    });
  }
  if (String(metaPid) !== worldId) {
    return res.status(422).json({ error: 'metadata_world_id_mismatch' });
  }

  const db = admin.firestore();
  const base = db.collection('players').doc(uid).collection('saves').doc(worldId);
  const stateCol = base.collection('state');
  const metaRef = stateCol.doc('meta');
  const currentRef = stateCol.doc('current');
  const versionsCol = base.collection('versions');

  // Vérifier la limite de mondes (10 max) avant création d'un nouveau monde
  try {
    const metaSnap = await metaRef.get();
    if (!metaSnap.exists) {
      // Nouveau monde: vérifier le nombre total de mondes existants
      const existingWorlds = await db.collection('players').doc(uid).collection('saves').listDocuments();
      const MAX_WORLDS = 10;
      if (existingWorlds.length >= MAX_WORLDS) {
        logger.warn('max_worlds_exceeded', { uid, worldId, count: existingWorlds.length, limit: MAX_WORLDS });
        return res.status(429).json({ error: 'max_worlds_exceeded', limit: MAX_WORLDS, current: existingWorlds.length });
      }
    }
  } catch (e: any) {
    logger.error('world_limit_check_failed', { uid, worldId, err: String(e?.message || e) });
    // Continuer malgré l'erreur de vérification (fail-open pour ne pas bloquer les updates)
  }

  try {
    const jsonStr = JSON.stringify(snapshot);
    const sizeBytes = Buffer.byteLength(jsonStr, 'utf8');

    await db.runTransaction(async (tx: Transaction) => {
      const metaSnap = await tx.get(metaRef);
      const currentSnap = await tx.get(currentRef);
      
      // P0-4: VÉRIFIER CONFLIT VERSION
      if (expected_version !== undefined && metaSnap.exists) {
        const actualVersion = (metaSnap.data()!.lastVersion as number) || 0;
        
        if (expected_version !== actualVersion) {
          logger.warn('version_conflict', {
            uid,
            worldId,
            expected: expected_version,
            actual: actualVersion,
          });
          
          // Lever exception spéciale pour sortir de la transaction
          throw new Error(`CONFLICT:${expected_version}:${actualVersion}`);
        }
      }
      
      const nextV = metaSnap.exists ? ((metaSnap.data()!.nextVersion as number) || 1) : 1;

      const versionRef = versionsCol.doc(String(nextV));
      const existing = await tx.get(versionRef);
      if (existing.exists) {
        throw new Error('version_exists');
      }

      const now = admin.firestore.FieldValue.serverTimestamp();
      const isNew = !metaSnap.exists || !currentSnap.exists;

      tx.set(versionRef, {
        version: nextV,
        snapshot,
        createdAt: now,
      });

      const currentPayload: Record<string, any> = {
        version: nextV,
        snapshot,
        updatedAt: now,
      };
      // Persister les métadonnées facultatives seulement si fournies et valides (pas de logique métier)
      if (typeof name === 'string') {
        currentPayload.name = name;
      }
      if (typeof gameVersionInput === 'string') {
        currentPayload.game_version = gameVersionInput;
      }
      if (isNew) {
        currentPayload.createdAt = now;
      }
      tx.set(currentRef, currentPayload, { merge: true });

      const metaPayload: Record<string, any> = {
        lastVersion: nextV,
        nextVersion: nextV + 1,
        updatedAt: now,
      };
      if (!metaSnap.exists) {
        metaPayload.createdAt = now;
      }
      tx.set(metaRef, metaPayload, { merge: true });
    });

    const curAfter = await currentRef.get();
    const upd = curAfter.data()?.updatedAt?.toDate?.() as Date | undefined;
    const updatedIso = (upd ?? new Date()).toISOString();

    logger.info('put_world_ok', { uid, worldId, sizeBytes });
    return res.status(200).json({ ok: true, world_id: worldId, updated_at: updatedIso, size_bytes: sizeBytes });
  } catch (e: any) {
    // P0-4: Gérer erreur conflit
    if (e.message?.startsWith('CONFLICT:')) {
      const parts = e.message.split(':');
      const expectedV = parseInt(parts[1], 10);
      const actualV = parseInt(parts[2], 10);
      
      logger.warn('put_world_conflict', { uid, worldId, expected: expectedV, actual: actualV });
      
      return res.status(409).json({
        error: 'version_conflict',
        message: 'Version conflict detected - another device has modified this world',
        expected_version: expectedV,
        actual_version: actualV,
        world_id: worldId,
      });
    }
    
    logger.error('put_world_failed', { uid, worldId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'save_failed' });
  }
});

// GET /worlds/:worldId → identique à GET /saves/:partieId/latest, étendu pour retourner name et game_version
app.get('/worlds/:worldId', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const worldId = String(req.params.worldId || '').trim();
  if (!isValidUuidV4(worldId)) {
    return res.status(400).json({ error: 'invalid_world_id' });
  }
  const db = admin.firestore();
  try {
    const currentRef = db.collection('players').doc(uid).collection('saves').doc(worldId).collection('state').doc('current');
    const cur = await currentRef.get();
    if (!cur.exists) {
      const versions = await db.collection('players').doc(uid).collection('saves').doc(worldId)
        .collection('versions').orderBy('version', 'desc').limit(1).get();
      if (versions.empty) return res.status(404).json({ error: 'not_found' });
      const d = versions.docs[0].data();
      return res.json({
        world_id: worldId,
        version: d.version,
        snapshot: d.snapshot,
        updated_at: (d.createdAt?.toDate?.() ?? new Date()).toISOString(),
        // Fallback: si current inexistant, les métadonnées peuvent être absentes
        name: null,
        game_version: null,
        game_mode: null,
      });
    }
    const d = cur.data()!;
    return res.json({
      world_id: worldId,
      version: d.version,
      snapshot: d.snapshot,
      updated_at: (d.updatedAt?.toDate?.() ?? new Date()).toISOString(),
      name: d.name ?? null,
      game_version: (d.game_version ?? d.gameVersion ?? null),
      game_mode: (d.game_mode ?? d.gameMode ?? null),
    });
  } catch (e: any) {
    logger.error('get_world_failed', { uid, worldId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'load_failed' });
  }
});

// GET /worlds → identique à GET /saves, étendu pour inclure name et game_version dans la liste
app.get('/worlds', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const page = Math.max(1, parseInt(String(req.query.page || '1'), 10));
  const limit = Math.min(200, Math.max(1, parseInt(String(req.query.limit || '50'), 10)));

  const db = admin.firestore();
  try {
    const base = db.collection('players').doc(uid).collection('saves');
    const partRefs = await base.listDocuments();
    const rows: { id: string; updated_at: Date | null; name: string | null; game_version: string | null }[] = [];
    for (const docRef of partRefs) {
      const currentRef = docRef.collection('state').doc('current');
      const cur = await currentRef.get();
      let include = false;
      let dt: Date | null = null;
      let nm: string | null = null;
      let gv: string | null = null;
      if (cur.exists) {
        const d = cur.data()!;
        const hasSnapshot = d.snapshot && typeof d.snapshot === 'object';
        if (hasSnapshot) {
          dt = d.updatedAt?.toDate?.() ?? null;
          nm = (typeof d.name === 'string') ? d.name : null;
          gv = (typeof d.game_version === 'string') ? d.game_version : (typeof d.gameVersion === 'string' ? d.gameVersion : null);
          include = true;
        }
        logger.info('list_worlds_row', {
          uid,
          worldId: docRef.id,
          hasCurrent: cur.exists,
          hasSnapshot,
          updatedAt: dt ? dt.toISOString() : null,
          name: nm,
          game_version: gv,
        });
      } else {
        logger.info('list_worlds_row', {
          uid,
          worldId: docRef.id,
          hasCurrent: false,
          hasSnapshot: false,
          updatedAt: null,
          name: null,
          game_version: null,
        });
      }
      if (include) {
        rows.push({ id: docRef.id, updated_at: dt, name: nm, game_version: gv });
      }
    }
    rows.sort((a, b) => (b.updated_at?.getTime() || 0) - (a.updated_at?.getTime() || 0));
    const offset = (page - 1) * limit;
    const sliced = rows.slice(offset, offset + limit);

    return res.json({
      items: sliced.map(r => ({ world_id: r.id, updated_at: r.updated_at ? r.updated_at.toISOString() : null, name: r.name ?? null, game_version: r.game_version ?? null })),
      page,
      limit,
      total: null,
    });
  } catch (e: any) {
    logger.error('list_worlds_failed', { uid, err: String(e?.message || e) });
    return res.status(500).json({ error: 'list_failed' });
  }
});

// DELETE /worlds/:worldId → identique à DELETE /saves/:partieId
app.delete('/worlds/:worldId', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const worldId = String(req.params.worldId || '').trim();
  if (!isValidUuidV4(worldId)) {
    return res.status(400).json({ error: 'invalid_world_id' });
  }
  const db = admin.firestore();
  const base = db.collection('players').doc(uid).collection('saves').doc(worldId);
  const stateCol = base.collection('state');
  const versionsCol = base.collection('versions');

  try {
    const [curSnap, metaSnap] = await Promise.all([
      stateCol.doc('current').get(),
      stateCol.doc('meta').get(),
    ]);
    const versionsRefs = await versionsCol.listDocuments();

    if (!curSnap.exists && !metaSnap.exists && versionsRefs.length === 0) {
      return res.status(404).json({ error: 'not_found' });
    }

    const chunks: admin.firestore.DocumentReference[] = versionsRefs;
    const BATCH_LIMIT = 450;
    for (let i = 0; i < chunks.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      for (const ref of chunks.slice(i, i + BATCH_LIMIT)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    const batch2 = db.batch();
    batch2.delete(stateCol.doc('current'));
    batch2.delete(stateCol.doc('meta'));
    await batch2.commit();

    await base.delete({ exists: true } as any).catch(() => undefined);

    return res.status(204).end();
  } catch (e: any) {
    logger.error('delete_world_failed', { uid, worldId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'delete_failed' });
  }
});

// PUT /saves/:partieId
app.put('/saves/:partieId', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const partieId = String(req.params.partieId || '').trim();
  const { snapshot } = req.body || {};

  if (!isValidUuidV4(partieId)) {
    return res.status(400).json({ error: 'invalid_partie_id' });
  }
  // Structure minimale requise: snapshot, metadata, core, stats
  if (!snapshot || !isPlainObject(snapshot)) {
    return res.status(400).json({ error: 'invalid_snapshot' });
  }
  const metadata = snapshot.metadata;
  const core = snapshot.core;
  const stats = snapshot.stats;
  if (!isPlainObject(metadata) || !isPlainObject(core) || !isPlainObject(stats)) {
    return res.status(400).json({ error: 'invalid_snapshot_structure' });
  }
  // Exiger la présence d'un partieId dans metadata et cohérence stricte avec le path
  const metaPid = metadata.partieId ?? metadata.partie_id ?? metadata.worldId ?? metadata.world_id;
  if (!metaPid || typeof metaPid !== 'string') {
    return res.status(422).json({ error: 'metadata_partie_id_missing' });
  }
  if (!isValidUuidV4(String(metaPid))) {
    return res.status(422).json({ error: 'metadata_partie_id_invalid' });
  }
  if (String(metaPid) !== partieId) {
    return res.status(422).json({ error: 'metadata_partie_id_mismatch' });
  }

  const db = admin.firestore();
  const base = db.collection('players').doc(uid).collection('saves').doc(partieId);
  const stateCol = base.collection('state');
  const metaRef = stateCol.doc('meta');
  const currentRef = stateCol.doc('current');
  const versionsCol = base.collection('versions');

  try {
    const jsonStr = JSON.stringify(snapshot);
    const sizeBytes = Buffer.byteLength(jsonStr, 'utf8');

    await db.runTransaction(async (tx: Transaction) => {
      const metaSnap = await tx.get(metaRef);
      const currentSnap = await tx.get(currentRef);
      const nextV = metaSnap.exists ? ((metaSnap.data()!.nextVersion as number) || 1) : 1;

      const versionRef = versionsCol.doc(String(nextV));
      const existing = await tx.get(versionRef);
      if (existing.exists) {
        throw new Error('version_exists');
      }

      const now = admin.firestore.FieldValue.serverTimestamp();
      const isNew = !metaSnap.exists || !currentSnap.exists;

      // Persist version row with server timestamps only
      tx.set(versionRef, {
        version: nextV,
        snapshot,
        createdAt: now,
      });

      // Update current state: always server-sourced updatedAt; set createdAt once at creation
      const currentPayload: Record<string, any> = {
        version: nextV,
        snapshot,
        updatedAt: now,
      };
      if (isNew) {
        currentPayload.createdAt = now;
      }
      tx.set(currentRef, currentPayload, { merge: true });

      // Maintain meta with immutable createdAt on first creation and moving updatedAt
      const metaPayload: Record<string, any> = {
        lastVersion: nextV,
        nextVersion: nextV + 1,
        updatedAt: now,
      };
      if (!metaSnap.exists) {
        metaPayload.createdAt = now;
      }
      tx.set(metaRef, metaPayload, { merge: true });
    });

    // Read back current to return authoritative server updated_at
    const curAfter = await currentRef.get();
    const upd = curAfter.data()?.updatedAt?.toDate?.() as Date | undefined;
    const updatedIso = (upd ?? new Date()).toISOString();

    logger.info('put_save_ok', { uid, partieId, sizeBytes });
    return res.status(200).json({ ok: true, world_id: partieId, updated_at: updatedIso, size_bytes: sizeBytes });
  } catch (e: any) {
    logger.error('put_save_failed', { uid, partieId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'save_failed' });
  }
});

// GET /saves/:partieId/latest
app.get('/saves/:partieId/latest', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const partieId = String(req.params.partieId || '').trim();
  if (!isValidUuidV4(partieId)) {
    return res.status(400).json({ error: 'invalid_partie_id' });
  }
  const db = admin.firestore();
  try {
    const currentRef = db.collection('players').doc(uid).collection('saves').doc(partieId).collection('state').doc('current');
    const cur = await currentRef.get();
    if (!cur.exists) {
      // Fallback: chercher dernière version
      const versions = await db.collection('players').doc(uid).collection('saves').doc(partieId)
        .collection('versions').orderBy('version', 'desc').limit(1).get();
      if (versions.empty) return res.status(404).json({ error: 'not_found' });
      const d = versions.docs[0].data();
      return res.json({
        partie_id: partieId,
        world_id: partieId,
        version: d.version,
        snapshot: d.snapshot,
        updated_at: (d.createdAt?.toDate?.() ?? new Date()).toISOString(),
      });
    }
    const d = cur.data()!;
    return res.json({
      partie_id: partieId,
      world_id: partieId,
      version: d.version,
      snapshot: d.snapshot,
      updated_at: (d.updatedAt?.toDate?.() ?? new Date()).toISOString(),
    });
  } catch (e: any) {
    logger.error('get_latest_failed', { uid, partieId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'load_failed' });
  }
});

// GET /saves?page=&limit=
app.get('/saves', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const page = Math.max(1, parseInt(String(req.query.page || '1'), 10));
  const limit = Math.min(200, Math.max(1, parseInt(String(req.query.limit || '50'), 10)));

  const db = admin.firestore();
  try {
    const base = db.collection('players').doc(uid).collection('saves');
    const partRefs = await base.listDocuments();
    const rows: { partie_id: string; updated_at: Date | null }[] = [];
    for (const docRef of partRefs) {
      const currentRef = docRef.collection('state').doc('current');
      const cur = await currentRef.get();
      let include = false;
      let dt: Date | null = null;
      if (cur.exists) {
        const d = cur.data()!;
        const hasSnapshot = d.snapshot && typeof d.snapshot === 'object';
        if (hasSnapshot) {
          dt = d.updatedAt?.toDate?.() ?? null;
          include = true;
        }
        // Audit par entrée
        logger.info('list_saves_row', {
          uid,
          partieId: docRef.id,
          hasCurrent: cur.exists,
          hasSnapshot,
          updatedAt: dt ? dt.toISOString() : null,
        });
      } else {
        // Audit absence de current
        logger.info('list_saves_row', {
          uid,
          partieId: docRef.id,
          hasCurrent: false,
          hasSnapshot: false,
          updatedAt: null,
        });
      }
      if (include) {
        rows.push({ partie_id: docRef.id, updated_at: dt });
      }
    }
    rows.sort((a, b) => (b.updated_at?.getTime() || 0) - (a.updated_at?.getTime() || 0));
    const offset = (page - 1) * limit;
    const sliced = rows.slice(offset, offset + limit);

    return res.json({
      items: sliced.map(r => ({ partie_id: r.partie_id, world_id: r.partie_id, updated_at: r.updated_at ? r.updated_at.toISOString() : null })),
      page,
      limit,
      total: null,
    });
  } catch (e: any) {
    logger.error('list_saves_failed', { uid, err: String(e?.message || e) });
    return res.status(500).json({ error: 'list_failed' });
  }
});

// DELETE /saves/:partieId
app.delete('/saves/:partieId', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const partieId = String(req.params.partieId || '').trim();
  if (!isValidUuidV4(partieId)) {
    return res.status(400).json({ error: 'invalid_partie_id' });
  }
  const db = admin.firestore();
  const base = db.collection('players').doc(uid).collection('saves').doc(partieId);
  const stateCol = base.collection('state');
  const versionsCol = base.collection('versions');

  try {
    // Vérifier s'il existe quelque chose à supprimer
    const [curSnap, metaSnap] = await Promise.all([
      stateCol.doc('current').get(),
      stateCol.doc('meta').get(),
    ]);
    const versionsRefs = await versionsCol.listDocuments();

    if (!curSnap.exists && !metaSnap.exists && versionsRefs.length === 0) {
      // Rien à supprimer → 404 (côté client traité comme succès idempotent)
      return res.status(404).json({ error: 'not_found' });
    }

    // Supprimer en lots (limite 500 par batch)
    const chunks: admin.firestore.DocumentReference[] = versionsRefs;
    const BATCH_LIMIT = 450;
    for (let i = 0; i < chunks.length; i += BATCH_LIMIT) {
      const batch = db.batch();
      for (const ref of chunks.slice(i, i + BATCH_LIMIT)) {
        batch.delete(ref);
      }
      await batch.commit();
    }

    // Supprimer state/current et state/meta
    const batch2 = db.batch();
    batch2.delete(stateCol.doc('current'));
    batch2.delete(stateCol.doc('meta'));
    await batch2.commit();

    // Supprimer le doc racine (facultatif) après vidage des sous-collections
    await base.delete({ exists: true } as any).catch(() => undefined);

    return res.status(204).end();
  } catch (e: any) {
    logger.error('delete_save_failed', { uid, partieId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'delete_failed' });
  }
});

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

// --- Versions APIs (Option C minimal) ---
// GET /saves/:partieId/versions
app.get('/saves/:partieId/versions', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const partieId = String(req.params.partieId || '').trim();
  if (!isValidUuidV4(partieId)) {
    return res.status(400).json({ error: 'invalid_partie_id' });
  }
  try {
    const db = admin.firestore();
    const versionsSnap = await db
      .collection('players').doc(uid)
      .collection('saves').doc(partieId)
      .collection('versions')
      .orderBy('version', 'asc')
      .get();
    const items = versionsSnap.docs.map(d => {
      const data = d.data();
      return {
        version: data.version,
        created_at: (data.createdAt?.toDate?.() ?? null)?.toISOString?.() ?? null,
        world_id: partieId,
      };
    });
    return res.json({ items });
  } catch (e: any) {
    logger.error('list_versions_failed', { uid, partieId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'list_versions_failed' });
  }
});

// GET /saves/:partieId/versions/:version
app.get('/saves/:partieId/versions/:version', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const partieId = String(req.params.partieId || '').trim();
  const versionStr = String(req.params.version || '').trim();
  if (!isValidUuidV4(partieId)) {
    return res.status(400).json({ error: 'invalid_partie_id' });
  }
  const v = parseInt(versionStr, 10);
  if (!Number.isFinite(v) || v <= 0) {
    return res.status(400).json({ error: 'invalid_version' });
  }
  try {
    const db = admin.firestore();
    const ref = db
      .collection('players').doc(uid)
      .collection('saves').doc(partieId)
      .collection('versions').doc(String(v));
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'not_found' });
    const d = snap.data()!;
    return res.json({
      partie_id: partieId,
      world_id: partieId,
      version: d.version,
      snapshot: d.snapshot,
      created_at: (d.createdAt?.toDate?.() ?? new Date()).toISOString(),
    });
  } catch (e: any) {
    logger.error('get_version_failed', { uid, partieId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'get_version_failed' });
  }
});

// POST /saves/:partieId/restore/:version
// Restore re-writes state/current with the selected version's snapshot and version
app.post('/saves/:partieId/restore/:version', verifyFirebaseIdToken, async (req: Request, res: Response) => {
  const uid = (req as any).uid as string;
  const partieId = String(req.params.partieId || '').trim();
  const versionStr = String(req.params.version || '').trim();
  if (!isValidUuidV4(partieId)) {
    return res.status(400).json({ error: 'invalid_partie_id' });
  }
  const v = parseInt(versionStr, 10);
  if (!Number.isFinite(v) || v <= 0) {
    return res.status(400).json({ error: 'invalid_version' });
  }
  try {
    const db = admin.firestore();
    const base = db.collection('players').doc(uid).collection('saves').doc(partieId);
    const versionRef = base.collection('versions').doc(String(v));
    const currentRef = base.collection('state').doc('current');

    const verSnap = await versionRef.get();
    if (!verSnap.exists) return res.status(404).json({ error: 'not_found' });
    const d = verSnap.data()!;

    await currentRef.set({
      version: d.version,
      snapshot: d.snapshot,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    // Read back authoritative updatedAt for response
    const curAfter = await currentRef.get();
    const upd = curAfter.data()?.updatedAt?.toDate?.() as Date | undefined;
    const updatedIso = (upd ?? new Date()).toISOString();

    logger.info('restore_ok', { uid, partieId, version: v });
    return res.status(202).json({ ok: true, world_id: partieId, updated_at: updatedIso });
  } catch (e: any) {
    logger.error('restore_failed', { uid, partieId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'restore_failed' });
  }
});

// Export Firebase Functions (Gen1)
export const api = functions.https.onRequest(app);

export const expressApp = app;
