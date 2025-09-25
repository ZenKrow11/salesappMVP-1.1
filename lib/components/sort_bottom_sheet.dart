// lib/components/sort_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SortBottomSheet extends ConsumerWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final currentSortOption = ref.watch(filterStateProvider).sortOption;
    final theme = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.secondary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.accent),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ...SortOption.values.map((option) {
                final bool isSelected = option == currentSortOption;

                return Card(
                  elevation: 0,
                  color: isSelected ? theme.secondary : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide.none
                        : BorderSide(color: theme.primary, width: 1.5),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      option.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.primary : theme.inactive,
                      ),
                    ),
                    onTap: () {
                      filterNotifier.update((state) => state.copyWith(sortOption: option));
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}