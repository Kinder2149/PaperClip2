import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

describe('Analytics', () => {
  it('POST /analytics/events accepts valid event', async () => {
    const res = await request(expressApp).post('/analytics/events').set(AUTH).send({ name: 'level_up', properties: { level: 2 } });
    expect(res.status).toBe(202);
  });
  it('POST /analytics/events rejects invalid event', async () => {
    const res = await request(expressApp).post('/analytics/events').set(AUTH).send({ name: 123 });
    expect(res.status).toBe(400);
  });
});
