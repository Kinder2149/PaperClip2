// lib/presentation/widgets/production_button.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/game_constants.dart';

class ProductionButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool enabled;
  final double metalCost;
  final int quantity;

  const ProductionButton({
    Key? key,
    required this.onTap,
    this.enabled = true,
    this.metalCost = GameConstants.METAL_PER_PAPERCLIP,
    this.quantity = 1,
  }) : super(key: key);

  @override
  State<ProductionButton> createState() => _ProductionButtonState();
}

class _ProductionButtonState extends State<ProductionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    if (!widget.enabled) return;
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(_) {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.enabled
                  ? [Colors.blue.shade500, Colors.blue.shade700]
                  : [Colors.grey.shade400, Colors.grey.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.enabled
                ? [
              BoxShadow(
                color: Colors.blue.shade500.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Produire ${widget.quantity > 1 ? widget.quantity : ''} Trombone${widget.quantity > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Coût: ${(widget.metalCost * widget.quantity).toStringAsFixed(2)} métal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BulkProductionButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;
  final int quantity;
  final double metalCost;
  final double efficiency;

  const BulkProductionButton({
    Key? key,
    required this.onTap,
    required this.quantity,
    this.enabled = true,
    this.metalCost = GameConstants.METAL_PER_PAPERCLIP,
    this.efficiency = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalCost = metalCost * quantity * (1 - efficiency);
    final savedMetal = metalCost * quantity * efficiency;

    return Card(
      elevation: enabled ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: enabled ? Colors.white : Colors.grey[200],
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? Colors.deepPurple.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'x$quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.deepPurple : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production en masse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$quantity trombones',
                      style: TextStyle(
                        fontSize: 14,
                        color: enabled ? Colors.black54 : Colors.grey,
                      ),
                    ),
                    if (efficiency > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.eco,
                            size: 12,
                            color: enabled ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Économie: ${savedMetal.toStringAsFixed(1)} métal',
                            style: TextStyle(
                              fontSize: 12,
                              color: enabled ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Coût total',
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled ? Colors.black54 : Colors.grey,
                    ),
                  ),
                  Text(
                    '${totalCost.toStringAsFixed(1)} métal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AutoclipperButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;
  final int currentCount;
  final double cost;
  final double productionRate;

  const AutoclipperButton({
    Key? key,
    required this.onTap,
    required this.currentCount,
    required this.cost,
    this.enabled = true,
    this.productionRate = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: enabled ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: enabled ? Colors.amber.shade200 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
              colors: [
                Colors.amber.shade50,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.precision_manufacturing,
                        color: enabled ? Colors.amber.shade700 : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Autoclipper',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: enabled ? Colors.black87 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: enabled ? Colors.amber.withOpacity(0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'x$currentCount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: enabled ? Colors.amber.shade800 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Production automatique de trombones',
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.black54 : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Produit ${productionRate.toStringAsFixed(1)} trombones/sec',
                style: TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.green.shade700 : Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: enabled ? Colors.amber.shade600 : Colors.grey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Acheter: ${cost.toStringAsFixed(1)} €',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (enabled)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        color: Colors.amber.shade800,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}