import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

function snap(id: string) {
  return { metadata: { worldId: id }, core: { v: 1 }, stats: { xp: 1 } };
}

describe('Worlds pagination & params', () => {
  it('GET /worlds returns items array and respects limit bounds', async () => {
    const base = '123e4567-e89b-42d3-a456-42661417';
    // seed a few
    for (let i = 300; i < 305; i++) {
      const id = `${base}${i.toString().padStart(3, '0')}`;
      await request(expressApp).put(`/worlds/${id}`).set(AUTH).send({ snapshot: snap(id) });
    }
    let res = await request(expressApp).get('/worlds?page=1&limit=2').set(AUTH);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
    expect(res.body.items.length).toBeLessThanOrEqual(2);

    // Out of bounds limit should clamp or error; accept 200 or 400
    res = await request(expressApp).get('/worlds?page=1&limit=1000').set(AUTH);
    expect([200,400]).toContain(res.status);
  });

  it('GET /worlds with invalid page returns 400 or clamps to 1', async () => {
    const res = await request(expressApp).get('/worlds?page=0&limit=10').set(AUTH);
    expect([200,400]).toContain(res.status);
  });
});
