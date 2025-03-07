import 'package:flutter/material.dart';

class ButtonStyles {
  static ButtonStyle primaryButton({
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.blue,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minimumSize: minimumSize ?? const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  static ButtonStyle secondaryButton({
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
  }) {
    return TextButton.styleFrom(
      foregroundColor: foregroundColor ?? Colors.blue,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      minimumSize: minimumSize ?? const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  static ButtonStyle iconButton({
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
  }) {
    return IconButton.styleFrom(
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? Colors.blue,
      padding: padding ?? const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
} 