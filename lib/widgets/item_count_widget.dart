// lib/widgets/item_count_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ItemCountWidget extends ConsumerWidget {
  final int filtered;
  final int total;
  final bool showBackground; // This field will store the value

  const ItemCountWidget({
    super.key,
    required this.filtered,
    required this.total,
    // We make showBackground optional with a default value of true.
    // This way, existing widgets that don't pass it will still have a background.
    this.showBackground = true,
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
      // The padding should also be conditional, or it will leave empty space
      padding: showBackground
          ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0)
          : EdgeInsets.zero,
      decoration: showBackground
      // ===================== FIX START =====================
      // If showBackground is true, apply the decoration.
          ? BoxDecoration(
        color: theme.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.0),
      )
      // Otherwise, apply no decoration (null).
          : null,
      // ====================== FIX END ======================
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