import request from 'supertest';
import { expressApp } from '../../../src/index';

describe('Health', () => {
  it('GET /health => 200 ok', async () => {
    const res = await request(expressApp).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });
});
