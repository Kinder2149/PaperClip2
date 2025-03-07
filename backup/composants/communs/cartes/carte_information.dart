import 'package:flutter/material.dart';

class CarteInformation extends StatelessWidget {
  final String titre;
  final Widget contenu;
  final VoidCallback? onTap;
  final Color? couleurBordure;
  final EdgeInsetsGeometry? padding;
  final Widget? icone;
  final List<Widget>? actions;

  const CarteInformation({
    Key? key,
    required this.titre,
    required this.contenu,
    this.onTap,
    this.couleurBordure,
    this.padding,
    this.icone,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: couleurBordure != null
            ? BorderSide(color: couleurBordure!, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (icone != null) ...[
                    icone!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (actions != null) ...[
                    const SizedBox(width: 8),
                    ...actions!,
                  ],
                ],
              ),
              if (titre.isNotEmpty) const SizedBox(height: 12),
              contenu,
            ],
          ),
        ),
      ),
    );
  }
} 