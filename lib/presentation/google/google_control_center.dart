import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import '../../services/google/identity/google_identity_service.dart';
import '../../services/google/identity/identity_status.dart';
import '../../services/google/achievements/achievements_service.dart';
import '../../services/google/leaderboards/leaderboards_service.dart';
import '../../services/google/cloudsave/cloud_save_service.dart';
import '../../services/google/cloudsave/cloud_save_models.dart';
import '../../services/google/cloudsave/supabase_friends_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase/supabase_auth_linker.dart';
import '../../services/google/sync/sync_orchestrator.dart';
import '../../services/google/sync/sync_readiness_port.dart';
import '../../services/google/sync/sync_opt_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/identity/identity_manager.dart';

/// Écran minimal « Centre de contrôle Google » (Étape 6)
/// - Opt-in explicite
/// - Aucune logique métier, aucun accès direct au core
/// - Utilise des callbacks pour les opérations sensibles (build/apply cloud)
class GoogleControlCenter extends StatefulWidget {
  final GoogleIdentityService identity;
  final AchievementsService achievements;
  final LeaderboardsService leaderboards;
  final CloudSaveService cloud;
  final GoogleSyncOrchestrator orchestrator;
  final SyncReadinessPort readiness;

  /// État de consentement sync (opt-in) géré par l'app
  final ValueNotifier<bool> syncEnabled;

  /// Construit un CloudSaveRecord à partir du snapshot local (fourni par l'app)
  final Future<CloudSaveRecord> Function() buildLocalRecord;

  /// Applique un import cloud (fourni par l'app; ce widget ne touche pas au core)
  final Future<void> Function(CloudSaveRecord record) applyCloudImport;

  const GoogleControlCenter({
    super.key,
    required this.identity,
    required this.achievements,
    required this.leaderboards,
    required this.cloud,
    required this.orchestrator,
    required this.readiness,
    required this.syncEnabled,
    required this.buildLocalRecord,
    required this.applyCloudImport,
  });

  @override
  State<GoogleControlCenter> createState() => _GoogleControlCenterState();
}

class _GoogleControlCenterState extends State<GoogleControlCenter> {
  bool _busy = false;
  String? _lastMessage;
  List<CloudSaveRecord> _cloudRevisions = const [];
  List<FriendEntry> _friends = const [];
  final TextEditingController _friendIdCtrl = TextEditingController();

  String? get _supabaseUid {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshIdentity() async {
    await widget.identity.refresh();
    // ignore: avoid_print
    print('[GCC] refreshIdentity: status=' '${widget.identity.status}' ' pid=' '${widget.identity.playerId}' ' name=' '${widget.identity.displayName}');
    setState(() {});
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] signIn: start');
      await widget.identity.signIn();
      // ignore: avoid_print
      print('[GCC] signIn: status=' '${widget.identity.status}' ' pid=' '${widget.identity.playerId}');
      try {
        if (await SyncOptIn.instance.get()) {
          await SupabaseAuthLinker.ensureGoogleSession().timeout(const Duration(milliseconds: 50), onTimeout: () {});
          final idm = IdentityManager();
          final done = await idm.isMigrationDone();
          if (!done) {
            final local = await widget.buildLocalRecord();
            await widget.cloud.upload(local);
            await idm.markMigrationDone();
          }
        }
      } catch (_) {}
      await widget.orchestrator.processQueues();
      final pid = widget.identity.playerId;
      _setMsg(pid != null ? 'Connecté: $pid' : 'Connecté.');
    } catch (_) {
      // ignore: avoid_print
      print('[GCC] signIn: error');
      _setMsg('Échec de connexion.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] signOut');
      await widget.identity.signOut();
      _setMsg('Déconnecté.');
    } catch (_) {
      _setMsg('Échec de déconnexion.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _toggleSync(bool value) async {
    setState(() => _busy = true);
    try {
      if (value) {
        if (widget.identity.status != IdentityStatus.signedIn) {
          final st = await widget.identity.signIn();
          if (st != IdentityStatus.signedIn) {
            _setMsg('Connexion Google requise pour la synchronisation.');
            return;
          }
        }
        // ignore: avoid_print
        print('[GCC] toggleSync=true: ensure Supabase session');
        await SupabaseAuthLinker.ensureGoogleSession(force: true);
      }
      await SyncOptIn.instance.set(value);
      widget.syncEnabled.value = value;
      setState(() {});
    } catch (_) {
      _setMsg('Échec lors du changement de synchronisation.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _publishQueues() async {
    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] publishQueues');
      await widget.orchestrator.processQueues();
      _setMsg('Publication tentée (succès/scores).');
    } catch (_) {
      _setMsg('Échec publication.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _publishCloudSave() async {
    if (widget.identity.playerId == null) {
      _setMsg('Connectez-vous d\'abord.');
      return;
    }
    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] publishCloudSave: build record');
      final record = await widget.buildLocalRecord();
      // ignore: avoid_print
      print('[GCC] publishCloudSave: upload');
      await widget.cloud.upload(record);
      _setMsg('Révision cloud publiée.');
    } catch (_) {
      _setMsg('Échec publication cloud.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _loadCloudRevisions() async {
    if (_supabaseUid == null) {
      _setMsg('Préparez d\'abord une session cloud.');
      return;
    }
    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] loadCloudRevisions');
      // Provider-agnostic listing: laisser RLS par user_id faire foi, ne pas filtrer par playerId
      final list = await widget.cloud.listByOwner('');
      setState(() => _cloudRevisions = list);
      _setMsg('Révisions cloud: ${list.length}.');
    } catch (_) {
      _setMsg('Échec chargement révisions.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _importCloudRevision(CloudSaveRecord rec) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importer cette sauvegarde ?'),
        content: const Text('Votre état local sera remplacé. Continuer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importer')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] importCloudRevision id=${rec.id}');
      await widget.applyCloudImport(rec);
      _setMsg('Import effectué.');
    } catch (_) {
      _setMsg('Échec import.');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _setMsg(String msg) {
    setState(() => _lastMessage = msg);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void initState() {
    super.initState();
    _refreshIdentity();
    () async {
      final pref = await SyncOptIn.instance.get();
      if (mounted) {
        widget.syncEnabled.value = pref;
        setState(() {});
      }
    }();
  }

  @override
  void dispose() {
    _friendIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _addFriend() async {
    final id = _friendIdCtrl.text.trim();
    if (id.isEmpty) {
      _setMsg('Renseignez un UUID ami.');
      return;
    }
    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] addFriend $id');
      await widget.cloud.addFriend(friendExternalId: id);
      _friendIdCtrl.clear();
      _setMsg('Ami ajouté.');
    } catch (_) {
      _setMsg('Échec ajout ami.');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _loadFriends() async {
    setState(() => _busy = true);
    try {
      // ignore: avoid_print
      print('[GCC] loadFriends');
      final list = await widget.cloud.listFriends();
      setState(() => _friends = list);
      _setMsg('Amis: ${list.length}.');
    } catch (_) {
      _setMsg('Échec chargement amis.');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = widget.identity.status;
    final signedIn = st == IdentityStatus.signedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Centre Google')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(title: 'Identité', children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_statusLabel(st)),
                  Row(children: [
                    if (!signedIn)
                      FilledButton(onPressed: _signIn, child: const Text('Se connecter')),
                    if (signedIn)
                      OutlinedButton(onPressed: _signOut, child: const Text('Se déconnecter')),
                  ]),
                ],
              ),
              if (signedIn && widget.identity.playerId != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'ID joueur: ${widget.identity.playerId}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Synchronisation cloud'),
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.syncEnabled,
                    builder: (_, v, __) => Switch(value: v, onChanged: signedIn ? _toggleSync : null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_supabaseUid != null)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Identifiant cloud: ${_supabaseUid!}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copier',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _supabaseUid!));
                        _setMsg('UID copié dans le presse-papiers');
                      },
                      icon: const Icon(Icons.copy, size: 18),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  setState(() => _busy = true);
                  try {
                    if (kIsWeb) {
                      _setMsg('Session cloud non requise sur Web.');
                    } else {
                      await SupabaseAuthLinker
                          .ensureGoogleSession()
                          .timeout(const Duration(milliseconds: 50), onTimeout: () {});
                      _setMsg('Session cloud prête.');
                    }
                    setState(() {});
                  } catch (_) {
                    _setMsg('Échec de préparation de la session cloud.');
                  } finally {
                    setState(() => _busy = false);
                  }
                },
                icon: const Icon(Icons.link),
                label: const Text('Préparer la session cloud'),
              ),
            ]),

            const SizedBox(height: 16),
            _Section(title: 'Profil', children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: (widget.identity.avatarUrl != null)
                        ? NetworkImage(widget.identity.avatarUrl!)
                        : null,
                    child: (widget.identity.avatarUrl == null)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.identity.displayName ?? '—', style: Theme.of(context).textTheme.titleMedium),
                        Text(widget.identity.playerId ?? '—', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _refreshIdentity,
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraîchir identité'),
              ),
            ]),

            const SizedBox(height: 16),
            _Section(title: 'Succès & Classements', children: [
              Text('Actions manuelles (opt-in).'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _publishQueues,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Publier succès / scores'),
              ),
            ]),

            const SizedBox(height: 16),
            _Section(title: 'Sauvegarde Cloud', children: [
              FilledButton.icon(
                onPressed: _publishCloudSave,
                icon: const Icon(Icons.backup),
                label: const Text('Publier ma sauvegarde locale'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _loadCloudRevisions,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Charger révisions cloud'),
              ),
              const SizedBox(height: 8),
              for (final rec in _cloudRevisions)
                Card(
                  child: ListTile(
                    title: Text(_recordTitle(rec)),
                    subtitle: Text('Version ${rec.meta.appVersion} • ${rec.meta.uploadedAt.toLocal()}'),
                    trailing: FilledButton(
                      onPressed: () => _importCloudRevision(rec),
                      child: const Text('Importer'),
                    ),
                  ),
                )
            ]),

            const SizedBox(height: 16),
            _Section(title: 'Amis (opt-in)', children: [
              const Text('Ajouter et lister vos amis (UUID Supabase demandé).'),
              const SizedBox(height: 8),
              TextField(
                controller: _friendIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Friend UUID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _addFriend,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Ajouter un ami'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _loadFriends,
                    icon: const Icon(Icons.group),
                    label: const Text('Lister mes amis'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final f in _friends)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(f.friendId),
                  subtitle: Text('Depuis ${f.createdAt.toLocal()}'),
                ),
            ]),

            const SizedBox(height: 16),
            _Section(title: 'Tests développeur', children: [
              const Text('Diagnostics Google / Supabase'),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await _refreshIdentity();
                    _setMsg('Status=' '${widget.identity.status}' ' pid=' '${widget.identity.playerId ?? "?"}');
                  },
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Tester Games Services'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    setState(() => _busy = true);
                    try {
                      if (kIsWeb) {
                        _setMsg('Session cloud non requise sur Web.');
                      } else {
                        await SupabaseAuthLinker.ensureGoogleSession();
                        _setMsg('Session cloud prête.');
                      }
                    } catch (_) {
                      _setMsg('Échec préparation session cloud.');
                    } finally {
                      setState(() => _busy = false);
                    }
                  },
                  icon: const Icon(Icons.cloud_sync),
                  label: const Text('Tester session Supabase'),
                ),
              ]),
            ]),

            if (_lastMessage != null) ...[
              const SizedBox(height: 16),
              Text(_lastMessage!, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(IdentityStatus s) {
    switch (s) {
      case IdentityStatus.anonymous:
        return 'Non connecté';
      case IdentityStatus.signedIn:
        final on = widget.syncEnabled.value;
        return on ? 'Connecté • Sync activée' : 'Connecté • Sync désactivée';
    }
  }

  String _recordTitle(CloudSaveRecord r) {
    final dd = r.payload.displayData;
    return '€${dd.money.toStringAsFixed(0)} • ${dd.paperclips.toStringAsFixed(0)} trombones • ${dd.autoClipperCount} auto';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}
