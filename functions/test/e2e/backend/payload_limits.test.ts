import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

function hugeString(bytes: number) {
  const chunk = 'x'.repeat(1024);
  let s = '';
  while (s.length < bytes) s += chunk;
  return s;
}

function makeLargeSnapshot(id: string, approxBytes: number) {
  const core = { data: hugeString(Math.max(0, approxBytes - 1000)) };
  return { metadata: { worldId: id }, core, stats: { s: 1 } };
}

describe('Payload limits', () => {
  it('rejects very large payloads (~ >1MB)', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174410';
    const big = makeLargeSnapshot(id, 1_200_000);
    const res = await request(expressApp).put(`/worlds/${id}`).set(AUTH).send({ snapshot: big });
    expect([400, 413]).toContain(res.status);
  });
});
