import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChampTextePersonnalise extends StatelessWidget {
  final String? etiquette;
  final String? indice;
  final TextEditingController? controleur;
  final String? messageErreur;
  final bool obscurTexte;
  final TextInputType? typeClavier;
  final List<TextInputFormatter>? formateurs;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final int? maxLignes;
  final int? minLignes;
  final Widget? prefixeIcone;
  final Widget? suffixeIcone;
  final bool readOnly;
  final String? Function(String?)? validateur;

  const ChampTextePersonnalise({
    Key? key,
    this.etiquette,
    this.indice,
    this.controleur,
    this.messageErreur,
    this.obscurTexte = false,
    this.typeClavier,
    this.formateurs,
    this.onChanged,
    this.onEditingComplete,
    this.maxLignes = 1,
    this.minLignes = 1,
    this.prefixeIcone,
    this.suffixeIcone,
    this.readOnly = false,
    this.validateur,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (etiquette != null) ...[
          Text(
            etiquette!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controleur,
          obscureText: obscurTexte,
          keyboardType: typeClavier,
          inputFormatters: formateurs,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          maxLines: maxLignes,
          minLines: minLignes,
          readOnly: readOnly,
          validator: validateur,
          decoration: InputDecoration(
            hintText: indice,
            errorText: messageErreur,
            prefixIcon: prefixeIcone,
            suffixIcon: suffixeIcone,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            filled: true,
            fillColor: readOnly 
                ? theme.disabledColor.withOpacity(0.1)
                : theme.cardColor,
          ),
        ),
      ],
    );
  }
} 