// test/unit/rare_resources_display_test.dart
// Tests pour le widget RareResourcesDisplay (correction I2)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/widgets/appbar/rare_resources_display.dart';

void main() {
  group('AUDIT I2 - RareResourcesDisplay Widget', () {
    testWidgets('Affiche correctement Quantum et Points Innovation', (WidgetTester tester) async {
      // Arrange
      const quantum = 150;
      const innovationPoints = 75;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RareResourcesDisplay(
              quantum: quantum,
              innovationPoints: innovationPoints,
            ),
          ),
        ),
      );

      // Assert : Vérifier que les valeurs sont affichées
      expect(find.text('150'), findsOneWidget,
          reason: 'Quantum value doit être affiché');
      expect(find.text('75'), findsOneWidget,
          reason: 'Innovation Points value doit être affiché');
    });

    testWidgets('Affiche les icônes correctes', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RareResourcesDisplay(
              quantum: 100,
              innovationPoints: 50,
            ),
          ),
        ),
      );

      // Assert : Vérifier la présence des icônes
      expect(find.byIcon(Icons.flash_on), findsOneWidget,
          reason: 'Icône Quantum (flash_on) doit être présente');
      expect(find.byIcon(Icons.lightbulb), findsOneWidget,
          reason: 'Icône Innovation Points (lightbulb) doit être présente');
    });

    testWidgets('Affiche zéro correctement', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RareResourcesDisplay(
              quantum: 0,
              innovationPoints: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('0'), findsNWidgets(2),
          reason: 'Les deux valeurs à 0 doivent être affichées');
    });

    testWidgets('Affiche de grandes valeurs correctement', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RareResourcesDisplay(
              quantum: 999999,
              innovationPoints: 888888,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('999999'), findsOneWidget);
      expect(find.text('888888'), findsOneWidget);
    });

    testWidgets('Widget est compact (taille appropriée)', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RareResourcesDisplay(
                quantum: 100,
                innovationPoints: 50,
              ),
            ),
          ),
        ),
      );

      // Assert : Vérifier que le widget n'est pas trop grand
      final widget = tester.widget<RareResourcesDisplay>(
        find.byType(RareResourcesDisplay),
      );
      expect(widget, isNotNull);

      // Vérifier la présence de Row (layout horizontal)
      expect(find.byType(Row), findsWidgets,
          reason: 'Le widget doit utiliser un Row pour layout horizontal');
    });

    testWidgets('Les couleurs sont appliquées correctement', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RareResourcesDisplay(
              quantum: 100,
              innovationPoints: 50,
            ),
          ),
        ),
      );

      // Assert : Vérifier la présence de Container avec couleurs
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, greaterThan(0),
          reason: 'Des containers doivent être présents pour le style');

      // Vérifier que les icônes ont des couleurs
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      for (final icon in icons) {
        expect(icon.color, isNotNull,
            reason: 'Les icônes doivent avoir une couleur définie');
      }
    });

    testWidgets('Widget se reconstruit correctement avec nouvelles valeurs', (WidgetTester tester) async {
      // Arrange : Valeurs initiales
      int quantum = 100;
      int innovationPoints = 50;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    RareResourcesDisplay(
                      quantum: quantum,
                      innovationPoints: innovationPoints,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          quantum = 200;
                          innovationPoints = 100;
                        });
                      },
                      child: Text('Update'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Assert : Valeurs initiales
      expect(find.text('100'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);

      // Act : Mettre à jour
      await tester.tap(find.text('Update'));
      await tester.pump();

      // Assert : Nouvelles valeurs
      expect(find.text('200'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('50'), findsNothing,
          reason: 'Ancienne valeur ne doit plus être affichée');
    });
  });
}
