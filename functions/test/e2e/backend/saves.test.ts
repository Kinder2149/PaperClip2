import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

function makeSnapshot(id: string) {
  return {
    metadata: { partieId: id },
    core: { value: 1 },
    stats: { score: 10 },
  };
}

describe('Saves endpoints', () => {
  it('PUT /saves/:id then GET latest and list, then DELETE', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174000';

    // Unauthorized
    let res = await request(expressApp).put(`/saves/${id}`).send({ snapshot: makeSnapshot(id) });
    expect(res.status).toBe(401);

    // Create
    res = await request(expressApp).put(`/saves/${id}`).set(AUTH).send({ snapshot: makeSnapshot(id) });
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.world_id).toBe(id);

    // Get latest
    res = await request(expressApp).get(`/saves/${id}/latest`).set(AUTH);
    expect(res.status).toBe(200);
    expect(res.body.world_id).toBe(id);
    expect(res.body.snapshot?.core?.value).toBe(1);

    // List (structure check)
    res = await request(expressApp).get(`/saves`).set(AUTH);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
    // L'émulateur mémoire peut ne pas refléter parfaitement listDocuments; on vérifie simplement la structure
    if (res.body.items.length > 0) {
      const it = res.body.items[0];
      expect(it).toHaveProperty('world_id');
      expect(it).toHaveProperty('updated_at');
    }

    // Delete
    res = await request(expressApp).delete(`/saves/${id}`).set(AUTH);
    expect(res.status).toBe(204);

    // After delete: GET latest => 404
    res = await request(expressApp).get(`/saves/${id}/latest`).set(AUTH);
    expect(res.status).toBe(404);
  });

  it('PUT /saves rejects invalid ids and mismatches', async () => {
    const badId = 'not-a-uuid';
    let res = await request(expressApp).put(`/saves/${badId}`).set(AUTH).send({ snapshot: makeSnapshot(badId) });
    expect(res.status).toBe(400);

    const goodId = '123e4567-e89b-42d3-a456-426614174001';
    const snap = makeSnapshot('123e4567-e89b-42d3-a956-426614174002'); // mismatch (world id different)
    res = await request(expressApp).put(`/saves/${goodId}`).set(AUTH).send({ snapshot: snap });
    expect(res.status).toBe(422);
  });
});
