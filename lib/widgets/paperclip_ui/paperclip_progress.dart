// lib/widgets/paperclip_ui/paperclip_progress.dart
import 'package:flutter/material.dart';
import '../../theme/paperclip_colors.dart';
import '../../theme/paperclip_typography.dart';

/// Progress bar Paperclip avec label et pourcentage
class PaperclipProgressBar extends StatelessWidget {
  final double value; // 0.0 à 1.0
  final String? label;
  final String? currentValue;
  final String? maxValue;
  final Color? color;
  final double height;
  final bool showPercentage;
  final bool animated;
  
  const PaperclipProgressBar({
    Key? key,
    required this.value,
    this.label,
    this.currentValue,
    this.maxValue,
    this.color,
    this.height = 8,
    this.showPercentage = true,
    this.animated = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final percentage = (value * 100).toStringAsFixed(0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: PaperclipTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (showPercentage)
                Text(
                  '$percentage%',
                  style: PaperclipTypography.bodySmall.copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? PaperclipColors.neutral700
                  : PaperclipColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
        ),
        if (currentValue != null && maxValue != null) ...[
          const SizedBox(height: 4),
          Text(
            '$currentValue / $maxValue',
            style: PaperclipTypography.caption.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }
}

/// Progress circulaire Paperclip
class PaperclipCircularProgress extends StatelessWidget {
  final double value; // 0.0 à 1.0
  final double size;
  final Color? color;
  final double strokeWidth;
  final Widget? child;
  final bool showPercentage;
  
  const PaperclipCircularProgress({
    Key? key,
    required this.value,
    this.size = 80,
    this.color,
    this.strokeWidth = 8,
    this.child,
    this.showPercentage = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final percentage = (value * 100).toStringAsFixed(0);
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? PaperclipColors.neutral700
                  : PaperclipColors.neutral200,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
          if (child != null)
            child!
          else if (showPercentage)
            Text(
              '$percentage%',
              style: PaperclipTypography.h4.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

/// Indicateur de chargement Paperclip
class PaperclipLoadingIndicator extends StatelessWidget {
  final String? message;
  final double size;
  final Color? color;
  
  const PaperclipLoadingIndicator({
    Key? key,
    this.message,
    this.size = 40,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: PaperclipTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Stepper horizontal Paperclip
class PaperclipStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final Color? activeColor;
  final Color? inactiveColor;
  
  const PaperclipStepper({
    Key? key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveActiveColor = activeColor ?? Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor = inactiveColor ?? 
        (isDark ? PaperclipColors.neutral600 : PaperclipColors.neutral300);
    
    return Row(
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isEven) {
          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = stepIndex <= currentStep;
          final isCurrent = stepIndex == currentStep;
          
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? effectiveActiveColor : effectiveInactiveColor,
                  border: isCurrent
                      ? Border.all(color: effectiveActiveColor, width: 3)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${stepIndex + 1}',
                    style: PaperclipTypography.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (stepLabels != null && stepIndex < stepLabels!.length) ...[
                const SizedBox(height: 4),
                Text(
                  stepLabels![stepIndex],
                  style: PaperclipTypography.caption.copyWith(
                    color: isActive ? effectiveActiveColor : effectiveInactiveColor,
                  ),
                ),
              ],
            ],
          );
        } else {
          // Connector line
          final stepIndex = index ~/ 2;
          final isActive = stepIndex < currentStep;
          
          return Expanded(
            child: Container(
              height: 2,
              color: isActive ? effectiveActiveColor : effectiveInactiveColor,
            ),
          );
        }
      }),
    );
  }
}
