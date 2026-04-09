# Widgets Agents IA

Widgets réutilisables pour l'interface de gestion des agents autonomes.

## Composants

### AgentCard
Carte principale affichant un agent avec son état, ses actions et ses statistiques.

**Props :**
- `Agent agent` : Modèle de l'agent à afficher
- `VoidCallback? onActivate` : Callback pour activer l'agent
- `VoidCallback? onDeactivate` : Callback pour désactiver l'agent
- `bool canActivate` : Indique si l'agent peut être activé

**États visuels :**
- **LOCKED** : Gris, icône cadenas, message "Recherche requise"
- **UNLOCKED** : Couleur selon type, bouton "Activer" (si conditions remplies)
- **ACTIVE** : Bordure verte, timer countdown, bouton "Désactiver"

**Couleurs par type :**
- PRODUCTION : Bleu (`Colors.blue`)
- MARKET : Vert (`Colors.green`)
- RESOURCE : Ambre (`Colors.amber`)
- INNOVATION : Violet (`Colors.purple`)

### AgentTimerDisplay
Widget affichant un timer countdown temps réel pour un agent actif.

**Props :**
- `DateTime expiresAt` : Date/heure d'expiration de l'agent
- `bool compact` : Mode compact pour affichage dans card (défaut: false)

**Fonctionnalités :**
- Mise à jour automatique chaque seconde
- Format "XXh XXm XXs restant"
- Barre de progression linéaire
- Couleur dynamique selon temps restant :
  - Vert : > 30 minutes
  - Orange : 10-30 minutes
  - Rouge : < 10 minutes

### AgentActivationDialog
Dialog de confirmation pour l'activation d'un agent.

**Props :**
- `Agent agent` : Agent à activer
- `int availableQuantum` : Quantum disponible
- `int availableSlots` : Slots disponibles

**Méthode statique :**
```dart
Future<bool> show(
  BuildContext context, {
  required Agent agent,
  required int availableQuantum,
  required int availableSlots,
})
```

**Validations :**
- Vérifie Quantum suffisant
- Vérifie slots disponibles
- Affiche warnings si conditions non remplies
- Bouton Confirmer désactivé si impossible

### AgentStatsCard
Widget affichant les statistiques d'un agent.

**Props :**
- `Agent agent` : Agent dont afficher les stats

**Affichage :**
- Nombre total d'actions effectuées
- Dernière action (format "Il y a X min/h/j")
- Icône analytics

## Usage

### Exemple basique

```dart
import 'package:paperclip2/widgets/agents/agent_card.dart';

AgentCard(
  agent: myAgent,
  onActivate: () => _activateAgent(myAgent),
  onDeactivate: () => _deactivateAgent(myAgent),
  canActivate: hasQuantum && hasSlots,
)
```

### Exemple avec dialog

```dart
import 'package:paperclip2/widgets/agents/agent_activation_dialog.dart';

final confirmed = await AgentActivationDialog.show(
  context,
  agent: myAgent,
  availableQuantum: gameState.quantum,
  availableSlots: agentManager.availableSlots,
);

if (confirmed) {
  agentManager.activateAgent(myAgent.id);
}
```

### Exemple timer standalone

```dart
import 'package:paperclip2/widgets/agents/agent_timer_display.dart';

AgentTimerDisplay(
  expiresAt: agent.expiresAt!,
  compact: true, // Pour affichage dans card
)
```

## Intégration

Voir `lib/screens/agents_screen.dart` pour un exemple complet d'intégration de tous les widgets.

## Architecture

Les widgets suivent les patterns Flutter standards :
- **StatelessWidget** pour widgets sans état interne
- **StatefulWidget** pour AgentTimerDisplay (timer périodique)
- **Provider** pour accès au GameState
- **Material Design** pour cohérence visuelle

## Performance

- AgentTimerDisplay utilise un Timer périodique qui se nettoie automatiquement dans `dispose()`
- Les widgets sont optimisés pour éviter les rebuilds inutiles
- Utilisation de `const` constructors quand possible
