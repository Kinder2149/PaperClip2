import request from 'supertest';
import { expressApp } from '../../../src/index';

const AUTH = { Authorization: 'Bearer valid' };

function makeSnapshot(id: string, value: number) {
  return { metadata: { partieId: id }, core: { value }, stats: { score: value * 10 } };
}

describe('Versions & restore', () => {
  it('lists versions, fetches by version, restores older version', async () => {
    const id = '123e4567-e89b-42d3-a456-426614174200';
    // v1
    let res = await request(expressApp).put(`/saves/${id}`).set(AUTH).send({ snapshot: makeSnapshot(id, 1) });
    expect(res.status).toBe(200);
    // v2
    res = await request(expressApp).put(`/saves/${id}`).set(AUTH).send({ snapshot: makeSnapshot(id, 2) });
    expect(res.status).toBe(200);
    // v3
    res = await request(expressApp).put(`/saves/${id}`).set(AUTH).send({ snapshot: makeSnapshot(id, 3) });
    expect(res.status).toBe(200);

    // list versions asc
    res = await request(expressApp).get(`/saves/${id}/versions`).set(AUTH);
    expect(res.status).toBe(200);
    expect(res.body.items.map((it: any) => it.version)).toEqual([1,2,3]);

    // get version 2
    res = await request(expressApp).get(`/saves/${id}/versions/2`).set(AUTH);
    expect(res.status).toBe(200);
    expect(res.body.version).toBe(2);
    expect(res.body.snapshot.core.value).toBe(2);

    // restore version 1
    res = await request(expressApp).post(`/saves/${id}/restore/1`).set(AUTH);
    expect(res.status).toBe(202);

    // latest now equals version 1
    res = await request(expressApp).get(`/saves/${id}/latest`).set(AUTH);
    expect(res.status).toBe(200);
    expect(res.body.version).toBe(1);
    expect(res.body.snapshot.core.value).toBe(1);
  });
});
