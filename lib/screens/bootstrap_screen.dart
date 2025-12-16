import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_bootstrap_controller.dart';
import 'start_screen.dart';

class BootstrapScreen extends StatefulWidget {
  final WidgetBuilder startScreenBuilder;

  const BootstrapScreen({
    Key? key,
    WidgetBuilder? startScreenBuilder,
  })  : startScreenBuilder = startScreenBuilder ?? _defaultStartScreenBuilder,
        super(key: key);

  static Widget _defaultStartScreenBuilder(BuildContext context) => const StartScreen();

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Démarre le bootstrap après la première construction.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bootstrap = context.read<AppBootstrapController>();
      bootstrap.bootstrap();
    });
  }

  @override
  void didUpdateWidget(covariant BootstrapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppBootstrapController>(
      builder: (context, bootstrap, _) {
        if (bootstrap.isReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: widget.startScreenBuilder),
            );
          });
        }

        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      bootstrap.hasError
                          ? 'Erreur de démarrage'
                          : 'Initialisation…',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (bootstrap.currentStep != null)
                      Text(
                        bootstrap.currentStep!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    if (bootstrap.hasError) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${bootstrap.lastError}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          bootstrap.retry();
                        },
                        child: const Text('Réessayer'),
                      ),
                      if (kDebugMode && bootstrap.lastStackTrace != null) ...[
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          child: Text(
                            bootstrap.lastStackTrace.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
