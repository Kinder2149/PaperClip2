import 'package:flutter/material.dart';
import 'button_styles.dart';

class ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isFullWidth;
  final bool isSecondary;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget? trailing;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isFullWidth = true,
    this.isSecondary = false,
    this.width,
    this.height,
    this.padding,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = isSecondary
        ? ButtonStyles.secondaryButton(
            foregroundColor: textColor,
            padding: padding,
            minimumSize: Size(width ?? double.infinity, height ?? 48),
          )
        : ButtonStyles.primaryButton(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: padding,
            minimumSize: Size(width ?? double.infinity, height ?? 48),
          );

    Widget button;
    if (icon != null) {
      button = ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: buttonStyle,
      );
    } else {
      button = ElevatedButton(
        onPressed: onPressed,
        style: buttonStyle,
        child: Text(label),
      );
    }

    if (trailing != null) {
      button = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: button),
          const SizedBox(width: 8),
          trailing!,
        ],
      );
    }

    if (!isFullWidth) {
      button = SizedBox(
        width: width,
        child: button,
      );
    }

    return button;
  }
} 