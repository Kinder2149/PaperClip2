import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };
function snap(id: string) { return { metadata: { worldId: id }, core: { v: 1 }, stats: { xp: 1 } }; }

describe('Worlds delete idempotency', () => {
  it('DELETE twice returns 204 then 404 (or 204 if idempotent)', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174310';
    await request(expressApp).put(`/worlds/${id}`).set(AUTH).send({ snapshot: snap(id) }).expect(200);
    const first = await request(expressApp).delete(`/worlds/${id}`).set(AUTH);
    expect([204,200]).toContain(first.status);
    const second = await request(expressApp).delete(`/worlds/${id}`).set(AUTH);
    expect([204,404]).toContain(second.status);
  });
});
