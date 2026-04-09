// lib/widgets/agents/agent_activation_dialog.dart

import 'package:flutter/material.dart';
import '../../models/agent.dart';

/// Dialog de confirmation pour l'activation d'un agent
class AgentActivationDialog extends StatelessWidget {
  final Agent agent;
  final int availableQuantum;
  final int availableSlots;

  const AgentActivationDialog({
    Key? key,
    required this.agent,
    required this.availableQuantum,
    required this.availableSlots,
  }) : super(key: key);

  /// Affiche le dialog et retourne true si l'utilisateur confirme
  static Future<bool> show(
    BuildContext context, {
    required Agent agent,
    required int availableQuantum,
    required int availableSlots,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AgentActivationDialog(
        agent: agent,
        availableQuantum: availableQuantum,
        availableSlots: availableSlots,
      ),
    );
    return result ?? false;
  }

  String _getActionDescription() {
    switch (agent.type) {
      case AgentType.PRODUCTION:
        return '+25% vitesse de production';
      case AgentType.MARKET:
        return 'Ajuste automatiquement le prix de vente';
      case AgentType.RESOURCE:
        return 'Achète du métal automatiquement';
      case AgentType.INNOVATION:
        return 'Génère +1 Point Innovation toutes les 10 min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = availableQuantum >= agent.activationCost;
    final hasSlotsAvailable = availableSlots > 0;
    final canActivate = canAfford && hasSlotsAvailable;

    return AlertDialog(
      title: Text('Activer: ${agent.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agent.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            
            // Coût Quantum
            Row(
              children: [
                const Icon(Icons.diamond, color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Coût: ${agent.activationCost} Quantum',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Disponible: $availableQuantum Quantum',
                  style: TextStyle(
                    color: canAfford ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Durée
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Durée: 1 heure',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Action: ${_getActionDescription()}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Slots
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: hasSlotsAvailable ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Slots disponibles: $availableSlots',
                  style: TextStyle(
                    color: hasSlotsAvailable ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // Warnings
            if (!canAfford) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quantum insuffisant',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (!hasSlotsAvailable) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tous les slots sont occupés. Désactivez un agent pour libérer un slot.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: canActivate ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: const Text('Activer'),
        ),
      ],
    );
  }
}
