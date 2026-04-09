// test/unit/agents/production_optimizer_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/agent.dart';
import 'package:paperclip2/agents/production_optimizer_agent.dart';

void main() {
  group('ProductionOptimizerAgent', () {
    late ProductionOptimizerAgent executor;
    late Agent agent;

    setUp(() {
      executor = ProductionOptimizerAgent();
      agent = Agent(
        id: 'production_optimizer',
        name: 'Production Optimizer',
        description: 'Test',
        type: AgentType.PRODUCTION,
        activationCost: 5,
        actionIntervalMinutes: 0,
        status: AgentStatus.ACTIVE,
        activatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
    });

    test('PRODUCTION_BONUS est 0.25 (25%)', () {
      expect(ProductionOptimizerAgent.PRODUCTION_BONUS, 0.25);
    });

    test('canExecute retourne true si agent actif', () {
      // Note: GameState sera testé lors de l'intégration Jour 3
      // Pour l'instant, on teste uniquement la logique de l'agent
      expect(executor.canExecute(agent, null as dynamic), true);
    });

    test('canExecute retourne false si agent inactif', () {
      agent.status = AgentStatus.UNLOCKED;
      expect(executor.canExecute(agent, null as dynamic), false);
    });

    test('execute retourne true (agent passif)', () {
      // Agent passif n'a pas besoin de GameState
      expect(executor.execute(agent, null as dynamic), true);
    });

    test('getActionDescription retourne description correcte', () {
      final description = executor.getActionDescription(agent);
      expect(description, contains('Bonus production'));
      expect(description, contains('25%'));
    });
  });
}
