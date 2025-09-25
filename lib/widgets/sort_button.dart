// lib/widgets/sort_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/sort_bottom_sheet.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SortButton extends ConsumerWidget {
  const SortButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return ElevatedButton.icon(
      icon: Icon(Icons.sort, color: theme.secondary, size: 22.0),
      label: Text('Sort', style: TextStyle(color: theme.inactive), overflow: TextOverflow.ellipsis),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const SortBottomSheet(),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.background.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }
}