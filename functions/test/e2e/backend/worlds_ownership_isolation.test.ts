import request from 'supertest';
import { expressApp } from '../../../src/index';

function snap(id: string) {
  return { metadata: { worldId: id }, core: { v: 1 }, stats: { xp: 1 } };
}

describe('Worlds ownership isolation', () => {
  // Use a known-valid token for A to ensure creation succeeds
  const AUTH_A = { Authorization: 'Bearer valid' };
  // Use a different token for B to simulate a different user; backend may treat it as unauthorized or as another uid
  const AUTH_B = { Authorization: 'Bearer userB' };

  it('user B cannot read/delete worlds created by user A', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174210';
    // A creates
    let res = await request(expressApp).put(`/worlds/${id}`).set(AUTH_A).send({ snapshot: snap(id) });
    expect(res.status).toBe(200);

    // B cannot read (unauthorized or forbidden or not found under B)
    res = await request(expressApp).get(`/worlds/${id}`).set(AUTH_B);
    expect([401, 403, 404]).toContain(res.status);

    // B cannot delete (unauthorized or forbidden or not found under B)
    res = await request(expressApp).delete(`/worlds/${id}`).set(AUTH_B);
    expect([401, 403, 404]).toContain(res.status);

    // A can delete
    res = await request(expressApp).delete(`/worlds/${id}`).set(AUTH_A);
    expect([200, 204]).toContain(res.status);
  });
});
