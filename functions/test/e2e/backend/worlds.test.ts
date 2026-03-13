import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

function makeSnapshot(id: string) {
  return {
    metadata: { worldId: id },
    core: { v: 1 },
    stats: { xp: 5 },
  };
}

describe('Worlds endpoints (alias)', () => {
  it('PUT /worlds with name and game_version then GET world and list', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174100';
    let res = await request(expressApp)
      .put(`/worlds/${id}`)
      .set(AUTH)
      .send({ snapshot: makeSnapshot(id), name: 'First World', game_version: '1.2.3' });
    expect(res.status).toBe(200);

    res = await request(expressApp).get(`/worlds/${id}`).set(AUTH);
    expect(res.status).toBe(200);
    expect(res.body.world_id).toBe(id);
    expect(res.body.name).toBe('First World');
    expect(res.body.game_version).toBe('1.2.3');

    res = await request(expressApp).get('/worlds').set(AUTH);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
    if (res.body.items.length > 0) {
      const it = res.body.items[0];
      expect(it).toHaveProperty('world_id');
      expect(it).toHaveProperty('updated_at');
      expect(it).toHaveProperty('name');
      expect(it).toHaveProperty('game_version');
    }
  });
});
