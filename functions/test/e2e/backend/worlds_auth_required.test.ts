import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

describe('Worlds auth required', () => {
  it('GET /worlds without auth => 401', async () => {
    const res = await request(expressApp).get('/worlds');
    expect(res.status).toBe(401);
  });

  it('GET /worlds/:id without auth => 401', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174110';
    const res = await request(expressApp).get(`/worlds/${id}`);
    expect(res.status).toBe(401);
  });

  it('DELETE /worlds/:id without auth => 401', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174111';
    const res = await request(expressApp).delete(`/worlds/${id}`);
    expect(res.status).toBe(401);
  });

  it('Authorized flow still works for reference', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174112';
    const snapshot = { metadata: { worldId: id }, core: { v: 1 }, stats: { xp: 1 } };
    let res = await request(expressApp).put(`/worlds/${id}`).set(AUTH).send({ snapshot });
    expect(res.status).toBe(200);
    res = await request(expressApp).get(`/worlds/${id}`).set(AUTH);
    expect(res.status).toBe(200);
  });
});
