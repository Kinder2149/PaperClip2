/**
 * Script de nettoyage Firestore pour migration Multi→Unique
 * ATTENTION : Supprime TOUTES les données utilisateurs
 * À exécuter UNE SEULE FOIS avant déploiement
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function cleanupMultiWorldsData() {
  console.log('🧹 DÉBUT NETTOYAGE FIRESTORE');
  console.log('⚠️  ATTENTION : Suppression de TOUTES les données multi-mondes');
  
  const stats = {
    usersProcessed: 0,
    worldsDeleted: 0,
    versionsDeleted: 0,
    errors: 0
  };

  try {
    const playersSnapshot = await db.collection('players').get();
    console.log(`📊 ${playersSnapshot.size} utilisateurs trouvés`);

    for (const playerDoc of playersSnapshot.docs) {
      const uid = playerDoc.id;
      console.log(`\n👤 Traitement utilisateur: ${uid}`);
      
      try {
        const savesSnapshot = await db.collection('players')
          .doc(uid)
          .collection('saves')
          .get();
        
        console.log(`  📁 ${savesSnapshot.size} mondes trouvés`);
        
        for (const saveDoc of savesSnapshot.docs) {
          const worldId = saveDoc.id;
          console.log(`    🗑️  Suppression monde: ${worldId}`);
          
          // Supprimer sous-collections
          const stateSnapshot = await saveDoc.ref.collection('state').get();
          const versionsSnapshot = await saveDoc.ref.collection('versions').get();
          
          const stateBatch = db.batch();
          stateSnapshot.docs.forEach(doc => stateBatch.delete(doc.ref));
          await stateBatch.commit();
          
          const versionsBatch = db.batch();
          versionsSnapshot.docs.forEach(doc => versionsBatch.delete(doc.ref));
          await versionsBatch.commit();
          
          stats.versionsDeleted += versionsSnapshot.size;
          await saveDoc.ref.delete();
          stats.worldsDeleted++;
        }
        
        stats.usersProcessed++;
        console.log(`  ✅ Utilisateur ${uid} nettoyé`);
        
      } catch (error) {
        console.error(`  ❌ Erreur utilisateur ${uid}:`, error);
        stats.errors++;
      }
    }
    
    console.log('\n📊 STATISTIQUES FINALES:');
    console.log(`  Utilisateurs traités: ${stats.usersProcessed}`);
    console.log(`  Mondes supprimés: ${stats.worldsDeleted}`);
    console.log(`  Versions supprimées: ${stats.versionsDeleted}`);
    console.log(`  Erreurs: ${stats.errors}`);
    console.log('\n✅ NETTOYAGE TERMINÉ');
    
  } catch (error) {
    console.error('❌ ERREUR FATALE:', error);
    throw error;
  }
}

// Exécution avec confirmation
const readline = require('readline').createInterface({
  input: process.stdin,
  output: process.stdout
});

readline.question('⚠️  CONFIRMER SUPPRESSION DE TOUTES LES DONNÉES ? (oui/non): ', (answer) => {
  if (answer.toLowerCase() === 'oui') {
    cleanupMultiWorldsData()
      .then(() => process.exit(0))
      .catch(() => process.exit(1));
  } else {
    console.log('❌ Annulé');
    process.exit(0);
  }
});
