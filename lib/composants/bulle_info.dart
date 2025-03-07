import 'package:flutter/material.dart';

class BulleInfo extends StatelessWidget {
  final String message;
  final IconData? icone;
  final Color? couleur;
  final VoidCallback? onFermer;

  const BulleInfo({
    Key? key,
    required this.message,
    this.icone,
    this.couleur,
    this.onFermer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: couleur ?? Theme.of(context).primaryColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null) ...[
              Icon(icone, color: Colors.white),
              const SizedBox(width: 8.0),
            ],
            Flexible(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            if (onFermer != null) ...[
              const SizedBox(width: 8.0),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: onFermer,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class InfoBulle extends StatelessWidget {
  final Widget enfant;
  final String message;
  final Duration delai;
  final bool afficherFleche;

  const InfoBulle({
    Key? key,
    required this.enfant,
    required this.message,
    this.delai = const Duration(milliseconds: 500),
    this.afficherFleche = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: delai,
      showDuration: const Duration(seconds: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: const TextStyle(color: Colors.white),
      preferBelow: true,
      verticalOffset: 16,
      child: enfant,
    );
  }
}

class BulleEvenement extends StatefulWidget {
  final String titre;
  final String description;
  final IconData icone;
  final Color? couleur;
  final Duration duree;
  final VoidCallback? onTap;

  const BulleEvenement({
    Key? key,
    required this.titre,
    required this.description,
    required this.icone,
    this.couleur,
    this.duree = const Duration(seconds: 5),
    this.onTap,
  }) : super(key: key);

  @override
  State<BulleEvenement> createState() => _BulleEvenementState();
}

class _BulleEvenementState extends State<BulleEvenement> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    Future.delayed(widget.duree, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Card(
            color: widget.couleur ?? Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(widget.icone, color: Colors.white),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.titre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          widget.description,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 