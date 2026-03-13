import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

function makeBadSnapshotDifferentId(pathId: string) {
  return { metadata: { worldId: '123e4567-e89b-42d3-a456-426614174abc' }, core: {}, stats: {} };
}

function makeMinimalSnapshot(id: string) {
  return { metadata: { worldId: id }, core: { v: 1 }, stats: { xp: 1 } };
}

describe('Worlds schema validations', () => {
  it('rejects invalid worldId (UUID v4)', async () => {
    const res = await request(expressApp).put('/worlds/not-a-uuid').set(AUTH).send({ snapshot: makeMinimalSnapshot('not-a-uuid') });
    expect([400, 422]).toContain(res.status);
  });

  it('rejects metadata-path mismatch', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174120';
    const res = await request(expressApp).put(`/worlds/${id}`).set(AUTH).send({ snapshot: makeBadSnapshotDifferentId(id) });
    expect(res.status).toBe(422);
  });

  it('accepts minimal valid snapshot', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174121';
    const res = await request(expressApp).put(`/worlds/${id}`).set(AUTH).send({ snapshot: makeMinimalSnapshot(id) });
    expect(res.status).toBe(200);
  });
});
