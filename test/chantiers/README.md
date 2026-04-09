# Tests en Chantier

**Date** : 9 avril 2026

## 📋 Principe

Ce dossier contient les tests **en développement actif** liés aux chantiers en cours.

## 🗂️ Organisation

Chaque chantier a son propre sous-dossier :

```
test/chantiers/
├── README.md (ce fichier)
├── CHANTIER-02-ressources-rares/
├── CHANTIER-03-recherche/
├── CHANTIER-04-agents/
└── CHANTIER-05-reset/
```

## 🎯 Règles

### Tests en Chantier
- 🚧 **En développement** - Peuvent échouer
- ✅ **Modifiables librement** - Itération rapide
- ⚠️ **Non exécutés en CI/CD** - Pas de blocage
- 📝 **Documentés** - README par chantier

### Fin de Chantier
1. ✅ Valider que tous les tests passent
2. 📦 Déplacer vers dossier validé (`test/unit/`, `test/integration/`, etc.)
3. 📝 Mettre à jour README avec lien doc figée
4. 🗑️ Supprimer dossier chantier
5. ✅ Commit

## 📊 État Actuel

| Chantier | Tests | Statut |
|----------|-------|--------|
| CHANTIER-02 (Ressources rares) | 0 | 🚧 À créer |
| CHANTIER-03 (Recherche) | 0 | 🚧 À créer |
| CHANTIER-04 (Agents) | 0 | 🚧 À créer |
| CHANTIER-05 (Reset) | 0 | 🚧 À créer |

## 🚀 Workflow

### Créer tests pour nouveau chantier

```bash
# 1. Créer dossier
mkdir test/chantiers/CHANTIER-XX-[nom]

# 2. Créer README
cat > test/chantiers/CHANTIER-XX-[nom]/README.md << EOF
# Tests CHANTIER-XX : [Nom]

**Statut** : 🚧 En développement
**Doc** : docs/chantiers/CHANTIER-XX-[nom]/

## Tests
- [ ] Test 1
- [ ] Test 2
EOF

# 3. Créer tests
# Développer librement, tests peuvent échouer
```

### Valider et ranger tests

```bash
# 1. Vérifier que tous les tests passent
flutter test test/chantiers/CHANTIER-XX-[nom]/

# 2. Déplacer vers dossier validé
mv test/chantiers/CHANTIER-XX-[nom]/*.dart test/unit/[feature]/

# 3. Mettre à jour README
# Ajouter lien vers doc figée

# 4. Supprimer dossier chantier
rm -rf test/chantiers/CHANTIER-XX-[nom]/

# 5. Commit
git commit -m "test: CHANTIER-XX validé - [description]"
```

---

**Créé le** : 9 avril 2026  
**Statut** : ✅ Structure créée
