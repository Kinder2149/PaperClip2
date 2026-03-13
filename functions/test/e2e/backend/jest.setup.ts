/**
 * Jest setup: mock Firebase Admin (auth + Firestore) et logger
 */

import type { Request } from 'express';

// Simple timestamp wrappers pour coller aux usages .toDate()?.
class ServerTimestamp {
  private d: Date;
  constructor() { this.d = new Date(); }
  toDate() { return this.d; }
}
class WrappedTimestamp {
  private d: Date;
  constructor(d: Date) { this.d = d; }
  toDate() { return this.d; }
}

// In-memory Firestore minimaliste
type DocData = Record<string, any> | undefined;

class InMemoryDocRef {
  private store: InMemoryFirestore;
  public path: string[];
  constructor(store: InMemoryFirestore, path: string[]) {
    this.store = store; this.path = path;
  }
  get id() { return this.path[this.path.length - 1]; }
  collection(name: string) { return new InMemoryCollectionRef(this.store, [...this.path, name]); }
  async get() { return new InMemoryDocSnap(this.store, this.path); }
  async set(data: Record<string, any>, opts?: { merge?: boolean }) {
    const key = this.store.key(this.path);
    const existing = this.store.docs.get(key) || {};
    const toWrite = opts?.merge ? { ...existing, ...data } : { ...data };
    this.store.docs.set(key, toWrite);
    // Assurer l'existence du document parent players/{uid}/saves/{partieId}
    // pour que listDocuments() le trouve
    if (this.path.length >= 6 && this.path[0] === 'players' && this.path[2] === 'saves') {
      const topDocPath = this.path.slice(0, 4); // ['players', uid, 'saves', partieId]
      const topKey = this.store.key(topDocPath);
      if (!this.store.docs.has(topKey)) {
        this.store.docs.set(topKey, { _placeholder: true });
      }
    }
  }
  async delete() {
    const key = this.store.key(this.path);
    this.store.docs.delete(key);
  }
}
class InMemoryCollectionRef {
  private store: InMemoryFirestore;
  private path: string[];
  constructor(store: InMemoryFirestore, path: string[]) { this.store = store; this.path = path; }
  doc(id?: string) { return new InMemoryDocRef(this.store, [...this.path, id || this.store.autoId()]); }
  async listDocuments() {
    // Retourne tous les documents enfants directs de cette collection
    // y compris ceux qui n'ont que des sous-collections (sans set direct du doc parent)
    const prefix = this.store.key(this.path) + '/';
    const depth = this.path.length + 1; // collection path + docId
    const idSet = new Set<string>();
    for (const k of this.store.docs.keys()) {
      if (!k.startsWith(prefix)) continue;
      const parts = k.split('/');
      if (parts.length >= depth) {
        idSet.add(parts[depth - 1]);
      }
    }
    return Array.from(idSet).map(id => this.doc(id));
  }
  orderBy(field: string, dir: 'asc' | 'desc' = 'asc') {
    return new InMemoryQuery(this.store, this.path, field, dir);
  }
}
class InMemoryQuery {
  private store: InMemoryFirestore;
  private path: string[];
  private field: string;
  private dir: 'asc' | 'desc';
  private _limit?: number;
  constructor(store: InMemoryFirestore, path: string[], field: string, dir: 'asc' | 'desc') {
    this.store = store; this.path = path; this.field = field; this.dir = dir;
  }
  limit(n: number) { this._limit = n; return this; }
  async get() {
    const coll = new InMemoryCollectionRef(this.store, this.path);
    const docs = await coll.listDocuments();
    const rows = await Promise.all(docs.map(async dref => ({ ref: dref, snap: await dref.get() })));
    const withField = rows
      .map(r => ({ ref: r.ref, data: r.snap.data() }))
      .filter(r => r.data !== undefined)
      .sort((a: any, b: any) => {
        const av = a.data[this.field];
        const bv = b.data[this.field];
        const aval = typeof av === 'object' && av?.toDate ? av.toDate().getTime() : av;
        const bval = typeof bv === 'object' && bv?.toDate ? bv.toDate().getTime() : bv;
        return (this.dir === 'asc' ? 1 : -1) * ((aval ?? 0) - (bval ?? 0));
      });
    const sliced = typeof this._limit === 'number' ? withField.slice(0, this._limit) : withField;
    return {
      empty: sliced.length === 0,
      docs: sliced.map((r: any) => new InMemoryDocSnap(this.store, (r.ref as any).path)),
    };
  }
}
class InMemoryDocSnap {
  private store: InMemoryFirestore;
  public path: string[];
  constructor(store: InMemoryFirestore, path: string[]) { this.store = store; this.path = path; }
  get exists() { return this.store.docs.has(this.store.key(this.path)); }
  data() { return this.store.docs.get(this.store.key(this.path)); }
}
class InMemoryBatch {
  private store: InMemoryFirestore; private ops: Array<() => void> = [];
  constructor(store: InMemoryFirestore) { this.store = store; }
  delete(ref: InMemoryDocRef) { this.ops.push(() => ref.delete()); }
  async commit() { for (const op of this.ops) await op(); this.ops = []; }
}
class InMemoryFirestore {
  public docs: Map<string, DocData> = new Map();
  private _id = 0;
  key(path: string[]) { return path.join('/'); }
  autoId() { this._id++; return `auto_${this._id}`; }
  collection(name: string) { return new InMemoryCollectionRef(this, [name]); }
  batch() { return new InMemoryBatch(this); }
  async runTransaction<T>(cb: (tx: any) => Promise<T>) {
    const tx = {
      get: async (ref: InMemoryDocRef) => ref.get(),
      set: async (ref: InMemoryDocRef, data: any, opts?: any) => ref.set(data, opts),
    };
    return cb(tx);
  }
  _reset() { this.docs.clear(); this._id = 0; }
  static FieldValue = { serverTimestamp: () => new ServerTimestamp() };
  static Timestamp = { fromDate: (d: Date) => new WrappedTimestamp(d) };
}

// Mock du module firebase-admin
jest.mock('firebase-admin', () => {
  const store = new InMemoryFirestore();
  const auth = () => ({
    async verifyIdToken(token: string) {
      const t = String(token || '');
      if (t === 'valid' || t === 'VALID') return { uid: 'user1' } as any;
      if (t.startsWith('uid:')) return { uid: t.slice(4) } as any;
      throw new Error('invalid token');
    },
  });
  const firestore = () => store as any;
  (firestore as any).FieldValue = InMemoryFirestore.FieldValue as any;
  (firestore as any).Timestamp = InMemoryFirestore.Timestamp as any;
  return {
    initializeApp: () => ({}),
    app: () => ({}),
    auth,
    firestore,
  } as any;
});

// Mock logger pour réduire le bruit
jest.mock('firebase-functions/logger', () => ({
  info: jest.fn(), warn: jest.fn(), error: jest.fn(),
}));

// Expose un reset helper global pour les tests
const admin = require('firebase-admin');
beforeEach(() => {
  const db = admin.firestore();
  db._reset?.();
});
