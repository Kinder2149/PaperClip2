import 'package:flutter/material.dart';

class CardStyles {
  static BoxDecoration marketCard({
    required Color color,
    double elevation = 2,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  static BoxDecoration infoCard({
    required Color color,
    double elevation = 2,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  static BoxDecoration upgradeCard({
    required Color color,
    bool isMaxed = false,
    bool canBuy = false,
    double elevation = 2,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isMaxed
            ? Colors.green.shade200
            : canBuy
                ? Colors.blue.shade200
                : Colors.grey.shade200,
        width: isMaxed || canBuy ? 1 : 0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }
} 