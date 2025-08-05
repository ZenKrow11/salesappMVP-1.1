import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ADDED
import 'package:sales_app_mvp/widgets/app_theme.dart'; // UPDATED

// UPDATED to ConsumerWidget to access the theme provider
class ItemCountWidget extends ConsumerWidget {
  final int filtered;
  final int total;

  const ItemCountWidget({
    super.key,
    required this.filtered,
    required this.total,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // ADDED WidgetRef
    final theme = ref.watch(themeProvider); // Get theme from provider

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.primary, // UPDATED
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        '$filtered/$total',
        style: TextStyle(
          color: theme.inactive, // UPDATED
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}