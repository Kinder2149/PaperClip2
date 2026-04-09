// test/unit/agents/agent_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/models/agent.dart';
import 'package:paperclip2/widgets/agents/agent_card.dart';

void main() {
  group('AgentCard Widget Tests', () {
    testWidgets('Affiche agent verrouillé correctement', (tester) async {
      final agent = Agent(
        id: 'test_agent',
        name: 'Test Agent',
        description: 'Test description',
        type: AgentType.PRODUCTION,
        status: AgentStatus.LOCKED,
        activationCost: 5,
        durationMinutes: 60,
        actionIntervalMinutes: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentCard(
              agent: agent,
              canActivate: false,
            ),
          ),
        ),
      );

      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.text('Verrouillé'), findsOneWidget);
      expect(find.text('Recherche requise pour débloquer cet agent'), findsOneWidget);
    });

    testWidgets('Affiche agent disponible avec bouton Activer', (tester) async {
      final agent = Agent(
        id: 'test_agent',
        name: 'Test Agent',
        description: 'Test description',
        type: AgentType.PRODUCTION,
        status: AgentStatus.UNLOCKED,
        activationCost: 5,
        durationMinutes: 60,
        actionIntervalMinutes: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentCard(
              agent: agent,
              onActivate: () {},
              canActivate: true,
            ),
          ),
        ),
      );

      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Activer'), findsOneWidget);
      
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Activer'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Affiche agent actif avec timer et bouton Désactiver', (tester) async {
      final agent = Agent(
        id: 'test_agent',
        name: 'Test Agent',
        description: 'Test description',
        type: AgentType.PRODUCTION,
        status: AgentStatus.ACTIVE,
        activationCost: 5,
        durationMinutes: 60,
        actionIntervalMinutes: 0,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentCard(
              agent: agent,
              onDeactivate: () {},
              canActivate: false,
            ),
          ),
        ),
      );

      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.text('Actif'), findsOneWidget);
      expect(find.text('Désactiver'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsWidgets);
    });

    testWidgets('Bouton Activer désactivé si canActivate=false', (tester) async {
      final agent = Agent(
        id: 'test_agent',
        name: 'Test Agent',
        description: 'Test description',
        type: AgentType.PRODUCTION,
        status: AgentStatus.UNLOCKED,
        activationCost: 5,
        durationMinutes: 60,
        actionIntervalMinutes: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentCard(
              agent: agent,
              onActivate: () {},
              canActivate: false,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Activer'),
      );
      expect(button.onPressed, isNull);
      expect(find.text('Quantum insuffisant ou slots pleins'), findsOneWidget);
    });

    testWidgets('Affiche statistiques si totalActions > 0', (tester) async {
      final agent = Agent(
        id: 'test_agent',
        name: 'Test Agent',
        description: 'Test description',
        type: AgentType.PRODUCTION,
        status: AgentStatus.UNLOCKED,
        activationCost: 5,
        durationMinutes: 60,
        actionIntervalMinutes: 0,
        totalActions: 5,
        lastActionAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgentCard(
              agent: agent,
              canActivate: true,
            ),
          ),
        ),
      );

      expect(find.text('5 actions effectuées'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });

    testWidgets('Couleur selon type agent', (tester) async {
      final types = [
        AgentType.PRODUCTION,
        AgentType.MARKET,
        AgentType.RESOURCE,
        AgentType.INNOVATION,
      ];

      for (final type in types) {
        final agent = Agent(
          id: 'test_$type',
          name: 'Test',
          description: 'Test',
          type: type,
          status: AgentStatus.UNLOCKED,
          activationCost: 5,
          durationMinutes: 60,
          actionIntervalMinutes: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgentCard(
                agent: agent,
                canActivate: true,
              ),
            ),
          ),
        );

        // Vérifier que la card est rendue
        expect(find.byType(Card), findsOneWidget);
        
        await tester.pumpWidget(Container()); // Clear widget tree
      }
    });
  });
}
