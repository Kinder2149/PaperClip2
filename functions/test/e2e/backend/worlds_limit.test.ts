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

function generateUuid(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

describe('Worlds limit (MAX_WORLDS=10)', () => {
  it('should allow creating up to 10 worlds and reject 11th', async () => {
    const createdWorldIds: string[] = [];

    // Créer 10 mondes
    for (let i = 0; i < 10; i++) {
      const worldId = generateUuid();
      const res = await request(expressApp)
        .put(`/worlds/${worldId}`)
        .set(AUTH)
        .send({
          snapshot: makeSnapshot(worldId),
          name: `World ${i + 1}`,
          game_version: '1.0.0',
        });

      expect(res.status).toBe(200);
      expect(res.body.ok).toBe(true);
      expect(res.body.world_id).toBe(worldId);
      createdWorldIds.push(worldId);
    }

    // Vérifier que les 10 mondes existent
    const listRes = await request(expressApp).get('/worlds').set(AUTH);
    expect(listRes.status).toBe(200);
    expect(listRes.body.items.length).toBe(10);

    // Tenter de créer un 11e monde (devrait échouer avec 429)
    const worldId11 = generateUuid();
    const res11 = await request(expressApp)
      .put(`/worlds/${worldId11}`)
      .set(AUTH)
      .send({
        snapshot: makeSnapshot(worldId11),
        name: 'World 11 (should fail)',
        game_version: '1.0.0',
      });

    expect(res11.status).toBe(429);
    expect(res11.body.error).toBe('max_worlds_exceeded');
    expect(res11.body.limit).toBe(10);
    expect(res11.body.current).toBe(10);

    // Cleanup: supprimer tous les mondes créés
    for (const worldId of createdWorldIds) {
      await request(expressApp).delete(`/worlds/${worldId}`).set(AUTH);
    }
  });

  it('should allow creating new world after deleting one', async () => {
    const createdWorldIds: string[] = [];

    // Créer 10 mondes
    for (let i = 0; i < 10; i++) {
      const worldId = generateUuid();
      await request(expressApp)
        .put(`/worlds/${worldId}`)
        .set(AUTH)
        .send({
          snapshot: makeSnapshot(worldId),
          name: `World ${i + 1}`,
          game_version: '1.0.0',
        });
      createdWorldIds.push(worldId);
    }

    // Supprimer un monde
    const worldToDelete = createdWorldIds[0];
    const delRes = await request(expressApp)
      .delete(`/worlds/${worldToDelete}`)
      .set(AUTH);
    expect(delRes.status).toBe(204);

    // Créer un nouveau monde (devrait réussir maintenant)
    const newWorldId = generateUuid();
    const res = await request(expressApp)
      .put(`/worlds/${newWorldId}`)
      .set(AUTH)
      .send({
        snapshot: makeSnapshot(newWorldId),
        name: 'New World After Delete',
        game_version: '1.0.0',
      });

    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.world_id).toBe(newWorldId);

    // Cleanup
    createdWorldIds.shift(); // Retirer le monde supprimé
    createdWorldIds.push(newWorldId); // Ajouter le nouveau
    for (const worldId of createdWorldIds) {
      await request(expressApp).delete(`/worlds/${worldId}`).set(AUTH);
    }
  });

  it('should allow updating existing world without counting toward limit', async () => {
    const createdWorldIds: string[] = [];

    // Créer 10 mondes
    for (let i = 0; i < 10; i++) {
      const worldId = generateUuid();
      await request(expressApp)
        .put(`/worlds/${worldId}`)
        .set(AUTH)
        .send({
          snapshot: makeSnapshot(worldId),
          name: `World ${i + 1}`,
          game_version: '1.0.0',
        });
      createdWorldIds.push(worldId);
    }

    // Mettre à jour un monde existant (ne devrait pas compter vers la limite)
    const existingWorldId = createdWorldIds[0];
    const res = await request(expressApp)
      .put(`/worlds/${existingWorldId}`)
      .set(AUTH)
      .send({
        snapshot: makeSnapshot(existingWorldId),
        name: 'Updated World',
        game_version: '1.0.1',
      });

    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
    expect(res.body.world_id).toBe(existingWorldId);

    // Cleanup
    for (const worldId of createdWorldIds) {
      await request(expressApp).delete(`/worlds/${worldId}`).set(AUTH);
    }
  });
});
