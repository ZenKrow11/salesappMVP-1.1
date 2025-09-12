// lib/widgets/quantity_stepper.dart

import 'package:flutter/material.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Color? color; // FIX: This parameter was missing

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.color, // FIX: Added to the constructor
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          // Use the color parameter
          icon: Icon(Icons.remove_circle_outline, color: color),
          // Disable button if quantity is 1 to prevent going to zero
          onPressed: quantity > 1 ? onDecrement : null,
          tooltip: 'Decrease quantity',
          splashRadius: 20,
        ),
        Text(
          quantity.toString(),
          // Use the color parameter
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        IconButton(
          // Use the color parameter
          icon: Icon(Icons.add_circle_outline, color: color),
          onPressed: onIncrement,
          tooltip: 'Increase quantity',
          splashRadius: 20,
        ),
      ],
    );
  }
}