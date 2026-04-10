// lib/widgets/paperclip_ui/paperclip_button.dart
import 'package:flutter/material.dart';
import '../../theme/paperclip_colors.dart';
import '../../theme/paperclip_typography.dart';

/// Types de boutons Paperclip
enum PaperclipButtonType {
  primary,
  secondary,
  outlined,
  text,
  danger,
}

/// Tailles de boutons
enum PaperclipButtonSize {
  small,
  medium,
  large,
}

/// Bouton Paperclip avec styles cohérents
class PaperclipButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PaperclipButtonType type;
  final PaperclipButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  
  const PaperclipButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.type = PaperclipButtonType.primary,
    this.size = PaperclipButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget button;
    switch (type) {
      case PaperclipButtonType.primary:
        button = _buildPrimaryButton(context, isDark);
        break;
      case PaperclipButtonType.secondary:
        button = _buildSecondaryButton(context, isDark);
        break;
      case PaperclipButtonType.outlined:
        button = _buildOutlinedButton(context, isDark);
        break;
      case PaperclipButtonType.text:
        button = _buildTextButton(context, isDark);
        break;
      case PaperclipButtonType.danger:
        button = _buildDangerButton(context, isDark);
        break;
    }
    
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    
    return button;
  }
  
  Widget _buildPrimaryButton(BuildContext context, bool isDark) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? PaperclipColors.electricCyan : PaperclipColors.steelBlue,
        foregroundColor: isDark ? PaperclipColors.neutral900 : Colors.white,
        padding: _getPadding(),
        textStyle: _getTextStyle(),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _buildContent(),
    );
  }
  
  Widget _buildSecondaryButton(BuildContext context, bool isDark) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? PaperclipColors.copperOrangeLight : PaperclipColors.copperOrange,
        foregroundColor: isDark ? PaperclipColors.neutral900 : Colors.white,
        padding: _getPadding(),
        textStyle: _getTextStyle(),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _buildContent(),
    );
  }
  
  Widget _buildOutlinedButton(BuildContext context, bool isDark) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? PaperclipColors.electricCyan : PaperclipColors.steelBlue,
        side: BorderSide(
          color: isDark ? PaperclipColors.electricCyan : PaperclipColors.steelBlue,
          width: 1.5,
        ),
        padding: _getPadding(),
        textStyle: _getTextStyle(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _buildContent(),
    );
  }
  
  Widget _buildTextButton(BuildContext context, bool isDark) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isDark ? PaperclipColors.electricCyan : PaperclipColors.steelBlue,
        padding: _getPadding(),
        textStyle: _getTextStyle(),
      ),
      child: _buildContent(),
    );
  }
  
  Widget _buildDangerButton(BuildContext context, bool isDark) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? PaperclipColors.errorLight : PaperclipColors.error,
        foregroundColor: Colors.white,
        padding: _getPadding(),
        textStyle: _getTextStyle(),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (isLoading) {
      return SizedBox(
        height: _getIconSize(),
        width: _getIconSize(),
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }
    
    return Text(label);
  }
  
  EdgeInsets _getPadding() {
    switch (size) {
      case PaperclipButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case PaperclipButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case PaperclipButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }
  
  TextStyle _getTextStyle() {
    switch (size) {
      case PaperclipButtonSize.small:
        return PaperclipTypography.buttonSmall;
      case PaperclipButtonSize.medium:
      case PaperclipButtonSize.large:
        return PaperclipTypography.button;
    }
  }
  
  double _getIconSize() {
    switch (size) {
      case PaperclipButtonSize.small:
        return 16;
      case PaperclipButtonSize.medium:
        return 20;
      case PaperclipButtonSize.large:
        return 24;
    }
  }
}

/// Bouton icône Paperclip
class PaperclipIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  
  const PaperclipIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size = 24,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon, size: size),
      onPressed: onPressed,
      color: color,
      tooltip: tooltip,
    );
    
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}
