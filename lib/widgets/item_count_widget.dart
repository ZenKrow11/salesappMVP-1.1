// lib/widgets/item_count_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ItemCountWidget extends ConsumerWidget {
  final int filtered;
  final int total;

  const ItemCountWidget({
    super.key,
    required this.filtered,
    required this.total, required bool showBackground,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    final style = TextStyle(
      color: theme.inactive,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'RobotoMono',
    );

    final widestText = '$total/$total';
    final actualText = '$filtered/$total';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        // ===================== FIX START =====================
        // Changed from theme.primary to match the other app bar elements.
        color: theme.background.withOpacity(0.5),
        // ====================== FIX END ======================
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.0,
            child: Text(widestText, style: style),
          ),
          Text(actualText, style: style),
        ],
      ),
    );
  }
}