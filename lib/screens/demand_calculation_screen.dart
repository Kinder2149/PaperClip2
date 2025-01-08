import 'package:flutter/material.dart';

class DemandCalculationScreen extends StatelessWidget {
  const DemandCalculationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcul de la demande'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Calcul de la Demande',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'La demande pour les trombones est influencée par plusieurs facteurs :',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Prix de Vente : Des prix plus bas augmentent la demande, tandis que des prix plus élevés la réduisent.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Niveau de Marketing : Un niveau de marketing plus élevé augmente la demande.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Réputation : Une meilleure réputation augmente la demande, tandis qu\'une mauvaise réputation la diminue.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '- Conditions du Marché : Les conditions du marché peuvent influencer positivement ou négativement la demande.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}