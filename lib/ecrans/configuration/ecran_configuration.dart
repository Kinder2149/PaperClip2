import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/jeu_provider.dart';
import '../../composants/mise_en_page_base.dart';
import '../../composants/carte_information.dart';
import '../../services/theme_service.dart';

class EcranConfiguration extends StatelessWidget {
  const EcranConfiguration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<JeuProvider>(
      builder: (context, jeuProvider, child) {
        return MiseEnPageBase(
          titre: 'Configuration',
          corps: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Thème
              CarteInformation(
                titre: 'Apparence',
                contenu: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: const Text('Mode Sombre'),
                      value: jeuProvider.theme.modeSombre,
                      onChanged: (value) => jeuProvider.theme.changerModeSombre(value),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Thème de Couleur'),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ThemeCouleur.values.map((couleur) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () => jeuProvider.theme.changerThemeCouleur(couleur),
                              child: CircleAvatar(
                                backgroundColor: _getCouleurTheme(couleur),
                                child: jeuProvider.theme.themeCouleur == couleur
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notifications
              CarteInformation(
                titre: 'Notifications',
                contenu: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notifications du Jeu'),
                      subtitle: const Text('Événements, récompenses, etc.'),
                      value: jeuProvider.parametres.notificationsJeuActivees,
                      onChanged: (value) => jeuProvider.parametres.changerNotificationsJeu(value),
                    ),
                    SwitchListTile(
                      title: const Text('Notifications Système'),
                      subtitle: const Text('Production automatique, ventes, etc.'),
                      value: jeuProvider.parametres.notificationsSystemeActivees,
                      onChanged: (value) => jeuProvider.parametres.changerNotificationsSysteme(value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sauvegarde
              CarteInformation(
                titre: 'Sauvegarde',
                contenu: Column(
                  children: [
                    ListTile(
                      title: const Text('Dernière sauvegarde'),
                      subtitle: Text(
                        jeuProvider.derniereSauvegarde != null
                            ? _formaterDate(jeuProvider.derniereSauvegarde!)
                            : 'Jamais',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () => jeuProvider.sauvegarderJeu(),
                      ),
                    ),
                    if (jeuProvider.firebaseService.estConnecte)
                      SwitchListTile(
                        title: const Text('Sauvegarde Cloud'),
                        subtitle: const Text('Synchroniser avec Google'),
                        value: jeuProvider.parametres.sauvegardeCloudActivee,
                        onChanged: (value) => jeuProvider.parametres.changerSauvegardeCloud(value),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Compte
              if (jeuProvider.firebaseService.estConnecte)
                CarteInformation(
                  titre: 'Compte Google',
                  contenu: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        jeuProvider.firebaseService.photoUrl ?? '',
                      ),
                    ),
                    title: Text(jeuProvider.firebaseService.nomUtilisateur ?? ''),
                    subtitle: Text(jeuProvider.firebaseService.email ?? ''),
                    trailing: TextButton(
                      onPressed: () => jeuProvider.firebaseService.deconnexion(),
                      child: const Text('Déconnexion'),
                    ),
                  ),
                )
              else
                CarteInformation(
                  titre: 'Connexion',
                  contenu: Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.google),
                      label: const Text('Se connecter avec Google'),
                      onPressed: () => jeuProvider.firebaseService.connexionGoogle(),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Réinitialisation
              CarteInformation(
                titre: 'Réinitialisation',
                contenu: ListTile(
                  title: const Text('Réinitialiser le Jeu'),
                  subtitle: const Text('Cette action est irréversible'),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmerReinitialisation(context, jeuProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réinitialiser'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getCouleurTheme(ThemeCouleur couleur) {
    switch (couleur) {
      case ThemeCouleur.bleu:
        return Colors.blue;
      case ThemeCouleur.vert:
        return Colors.green;
      case ThemeCouleur.rouge:
        return Colors.red;
      case ThemeCouleur.violet:
        return Colors.purple;
      case ThemeCouleur.orange:
        return Colors.orange;
    }
  }

  String _formaterDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _confirmerReinitialisation(BuildContext context, JeuProvider jeu) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le Jeu'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser le jeu ? '
          'Toutes vos données seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      jeu.reinitialiserJeu();
    }
  }
} 