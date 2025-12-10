# PaperClip2 - Dossier Widgets

## Objectif

Le dossier `widgets` contient tous les composants d'interface utilisateur réutilisables de l'application. Ces widgets sont organisés en sous-dossiers selon leur fonction ou catégorie.

## Structure

- **charts/** : Widgets pour l'affichage de graphiques et visualisations des données du jeu.
  - `chart_widgets.dart` : Graphiques pour les ventes, la production, et autres statistiques.

- **dialogs/** : Boîtes de dialogue et popups utilisés à travers l'application.
  - Confirmations, alertes, et interfaces modales.

- **indicators/** : Widgets qui affichent les indicateurs de progression et de statut.
  - `level_widgets.dart` : Affichage du niveau et de l'expérience.
  - Barres de progression, indicateurs de charge, etc.

- **resources/** : Widgets pour l'affichage et la gestion des ressources du jeu.
  - `resource_widgets.dart` : Affichage des ressources (argent, trombones, métal).
  - Compteurs, interfaces d'achat/vente, etc.

- **ui_elements/** : Éléments d'interface utilisateur de base personnalisés.
  - Boutons, champs de texte, cartes, etc. avec le style propre à PaperClip2.

## Convention de Nommage

- Les widgets sont nommés de manière descriptive avec le suffixe correspondant à leur type (ex: `MoneyDisplay`, `SalesChart`, `UpgradeButton`).
- Les widgets sont regroupés par fonctionnalité plutôt que par type de widget.

## Bonnes Pratiques

- Privilégier les widgets paramétrables et réutilisables.
- Utiliser Provider/Consumer pour accéder aux données du GameState de manière efficace.
- Séparer la logique métier (dans les managers) de la logique d'affichage (dans les widgets).
- Documenter les paramètres et comportements attendus de chaque widget.
- Utiliser des constantes pour les valeurs de style et d'affichage.
