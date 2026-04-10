// lib/widgets/paperclip_ui/paperclip_card.dart
import 'package:flutter/material.dart';
import '../../theme/paperclip_colors.dart';
import '../../utils/responsive_utils.dart';

/// Types de cards Paperclip
enum PaperclipCardType {
  elevated,
  outlined,
  filled,
}

/// Card Paperclip avec styles cohérents et responsive
class PaperclipCard extends StatelessWidget {
  final Widget child;
  final PaperclipCardType type;
  final Color? color;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool responsive;
  
  const PaperclipCard({
    Key? key,
    required this.child,
    this.type = PaperclipCardType.elevated,
    this.color,
    this.borderColor,
    this.padding,
    this.onTap,
    this.responsive = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePadding = padding ?? _getResponsivePadding(context);
    
    Widget card;
    switch (type) {
      case PaperclipCardType.elevated:
        card = _buildElevatedCard(context, isDark, effectivePadding);
        break;
      case PaperclipCardType.outlined:
        card = _buildOutlinedCard(context, isDark, effectivePadding);
        break;
      case PaperclipCardType.filled:
        card = _buildFilledCard(context, isDark, effectivePadding);
        break;
    }
    
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    
    return card;
  }
  
  Widget _buildElevatedCard(BuildContext context, bool isDark, EdgeInsetsGeometry padding) {
    return Card(
      elevation: isDark ? 4 : 2,
      color: color ?? (isDark ? PaperclipColors.neutral800 : Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
  
  Widget _buildOutlinedCard(BuildContext context, bool isDark, EdgeInsetsGeometry padding) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? (isDark ? PaperclipColors.neutral800 : Colors.white),
        border: Border.all(
          color: borderColor ?? (isDark ? PaperclipColors.dividerDark : PaperclipColors.divider),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
  
  Widget _buildFilledCard(BuildContext context, bool isDark, EdgeInsetsGeometry padding) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? (isDark ? PaperclipColors.neutral700 : PaperclipColors.neutral100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
  
  EdgeInsetsGeometry _getResponsivePadding(BuildContext context) {
    if (!responsive) return const EdgeInsets.all(16);
    
    if (context.isDesktop) {
      return const EdgeInsets.all(20);
    }
    
    if (context.isTablet) {
      return const EdgeInsets.all(16);
    }
    
    return const EdgeInsets.all(12);
  }
}

/// Card stat avec icône, label et valeur
class PaperclipStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final String? trend; // "+5%" ou "-2%"
  final VoidCallback? onTap;
  
  const PaperclipStatCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.trend,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    
    return PaperclipCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: effectiveColor),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            _buildTrend(context),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTrend(BuildContext context) {
    final isPositive = trend!.startsWith('+');
    final trendColor = isPositive ? PaperclipColors.success : PaperclipColors.error;
    final trendIcon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(trendIcon, size: 14, color: trendColor),
        const SizedBox(width: 4),
        Text(
          trend!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: trendColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Card info avec titre et contenu
class PaperclipInfoCard extends StatelessWidget {
  final String title;
  final Widget content;
  final IconData? icon;
  final Color? iconColor;
  final List<Widget>? actions;
  
  const PaperclipInfoCard({
    Key? key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.actions,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return PaperclipCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
