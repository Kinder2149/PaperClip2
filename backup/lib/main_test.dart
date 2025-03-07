import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/jeu_provider.dart';
import 'navigation/routes.dart';
import 'utils/themes/app_theme.dart';

void main() {
  runApp(const MonApplicationTest());
}

class MonApplicationTest extends StatelessWidget {
  const MonApplicationTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JeuProvider(),
      child: MaterialApp(
        title: 'Paperclip Game',
        theme: AppTheme.themeClair,
        darkTheme: AppTheme.themeSombre,
        initialRoute: Routes.production,
        routes: Routes.routes,
      ),
    );
  }
} 