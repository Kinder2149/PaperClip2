import * as admin from 'firebase-admin';
import express, { Request, Response, NextFunction } from 'express';
import { onRequest } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import type { Transaction } from 'firebase-admin/firestore';

// Initialize Admin SDK once
try {
  admin.app();
} catch {
  admin.initializeApp();
}

const app = express();
app.use(express.json({ limit: '1mb' }));

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
  const metaPid = metadata.partieId ?? metadata.partie_id;
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
      const nextV = metaSnap.exists ? ((metaSnap.data()!.nextVersion as number) || 1) : 1;

      const versionRef = versionsCol.doc(String(nextV));
      const existing = await tx.get(versionRef);
      if (existing.exists) {
        throw new Error('version_exists');
      }

      const now = admin.firestore.FieldValue.serverTimestamp();

      tx.set(versionRef, {
        version: nextV,
        snapshot,
        createdAt: now,
      });

      tx.set(currentRef, {
        version: nextV,
        snapshot,
        updatedAt: now,
      });

      tx.set(metaRef, {
        lastVersion: nextV,
        nextVersion: nextV + 1,
        updatedAt: now,
      }, { merge: true });
    });

    logger.info('put_save_ok', { uid, partieId, sizeBytes });
    return res.status(200).json({ ok: true, updated_at: new Date().toISOString(), size_bytes: sizeBytes });
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
        version: d.version,
        snapshot: d.snapshot,
        updated_at: (d.createdAt?.toDate?.() ?? new Date()).toISOString(),
      });
    }
    const d = cur.data()!;
    return res.json({
      partie_id: partieId,
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
      items: sliced.map(r => ({ partie_id: r.partie_id, updated_at: r.updated_at ? r.updated_at.toISOString() : null })),
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

    logger.info('restore_ok', { uid, partieId, version: v });
    return res.status(202).json({ ok: true });
  } catch (e: any) {
    logger.error('restore_failed', { uid, partieId, err: String(e?.message || e) });
    return res.status(500).json({ error: 'restore_failed' });
  }
});

export const api = onRequest({ region: 'us-central1' }, app);
