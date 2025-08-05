import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/models/filter_state.dart';
import 'package:sales_app_mvp/providers/filter_state_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart'; // UPDATED

class SortButton extends ConsumerWidget {
  const SortButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider); // Get theme

    return TextButton.icon(
      icon: Icon(Icons.sort, color: theme.secondary, size: 24.0), // UPDATED
      label: Text(
        'Sort',
        style: TextStyle(color: theme.inactive), // UPDATED
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const _SortOptionsBottomSheet(),
        );
      },
      style: TextButton.styleFrom(
        backgroundColor: theme.primary, // UPDATED
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      ),
    );
  }
}

class _SortOptionsBottomSheet extends ConsumerWidget {
  const _SortOptionsBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterStateProvider);
    final filterNotifier = ref.read(filterStateProvider.notifier);
    final currentSortOption = filterState.sortOption;
    final theme = ref.watch(themeProvider); // Get theme

    return Container(
      decoration: BoxDecoration(
        color: theme.background, // UPDATED
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
                      color: theme.secondary, // UPDATED
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.accent), // UPDATED
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              ...SortOption.values.map((option) {
                final bool isSelected = option == currentSortOption;

                return Card(
                  elevation: 0,
                  color: isSelected ? theme.secondary : Colors.transparent, // UPDATED
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      option.displayName,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.primary : theme.inactive, // UPDATED
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