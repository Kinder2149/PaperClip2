# STACK STANDARD — MES CHOIX TECHNOLOGIQUES

> Emplacement : METHODO/STACK_STANDARD.md
> Copié à la racine de chaque projet au démarrage.
> Lu par Claude et Cascade avant toute action.
> Aucune technologie hors de ce cadre sans justification écrite.

---

## QUI JE SUIS (contexte obligatoire pour l'IA)

Je ne suis pas développeur. Je pilote des projets entièrement générés par IA.
Mon rôle : définir la vision, valider les décisions, tester le résultat.
Le rôle de l'IA : traduire ma vision en code propre, simple, maintenable.

**Règle fondamentale :** Si je ne peux pas tester manuellement le résultat, la mission est incomplète.

---

## 📱 APPLICATION MOBILE

| Élément | Choix | Ce que ça fait |
|---|---|---|
| Framework | Flutter | Génère l'appli Android depuis un seul code |
| Langage | Dart | La langue dans laquelle Flutter écrit le code |
| Comptes utilisateurs + données en ligne | Firebase Auth + Firestore | Gère les connexions et sauvegarde les données sur le cloud |
| Stockage de fichiers en ligne | Firebase Storage | Stocke les images et fichiers des utilisateurs |
| Rafraîchissement automatique de l'affichage | Provider | Quand une donnée change, l'écran se met à jour automatiquement |
| Mise en ligne | Google Play Store | Là où les utilisateurs téléchargent l'appli |

---

## 🌐 APPLICATION WEB FULL-STACK

| Élément | Choix | Ce que ça fait |
|---|---|---|
| Ce que l'utilisateur voit (frontend) | Angular | Construit les pages web et leur comportement |
| Langage frontend | TypeScript | JavaScript amélioré — détecte les erreurs avant l'exécution |
| Le moteur invisible (backend) | Express.js | Serveur qui reçoit les demandes de l'appli et répond avec les données |
| Langage backend | TypeScript | Même langage front et back — cohérence |
| Stockage des données | PostgreSQL + Prisma | Base de données structurée. Prisma fait le lien entre le code et la base |
| Comptes utilisateurs | Supabase Auth | Gère les connexions, mots de passe, sessions |
| Stockage images | Cloudinary | Service en ligne pour stocker et afficher les images |
| Mise en ligne | Vercel | Publie l'appli sur internet automatiquement |

---

## 🤖 OUTIL IA / AGENT

| Élément | Choix | Ce que ça fait |
|---|---|---|
| Serveur principal | FastAPI (Python) | Reçoit les demandes et les envoie aux agents IA |
| Langage | Python | Standard pour tout ce qui touche à l'IA |
| IA utilisée | À définir par projet | Claude ou Gemini selon le besoin |
| Stockage | JSON simple ou SQLite | Fichiers simples pour garder l'historique |
| Interface utilisateur | HTML/CSS/JS simple | Page web basique sans framework lourd |

---

## RÈGLES DE CHOIX POUR UN NOUVEAU PROJET

1. **Quel type ?** Mobile / Web / Outil IA → stack correspondante ci-dessus
2. **Projet similaire existant ?** → Oui : copier exactement sa stack
3. **Sortie du cadre standard ?** → Justification écrite obligatoire avant d'accepter

---

## LIMITES DE COMPLEXITÉ (non négociables)

- Maximum **20 services/modules** par projet
- Maximum **5 fichiers de documentation** par projet
- Maximum **3 couches** : UI / Logique / Données
- Zéro structure vide créée "pour le futur"
- Zéro dépendance ajoutée sans demande explicite

---

## CE QUE "MISSION TERMINÉE" VEUT DIRE

✅ Le build passe sans erreur
✅ La fonctionnalité est testable manuellement
✅ PROJET_CONTEXTE.md est mis à jour
✅ Aucun fichier créé hors scope

---

*Emplacement : METHODO/STACK_STANDARD.md*
