import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/filter_options_provider.dart';
import 'package:sales_app_mvp/widgets/store_logo.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class StoresFilterTab extends ConsumerWidget {
  final bool isIncludeMode;
  final Set<String> tappedStores;
  final void Function(String store) onToggleStore;
  final VoidCallback onToggleMode;

  const StoresFilterTab({
    super.key,
    required this.isIncludeMode,
    required this.tappedStores,
    required this.onToggleStore,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStoreOptions = ref.watch(storeOptionsProvider);
    final theme = ref.watch(themeProvider);

    return asyncStoreOptions.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (storeOptions) {
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 100,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: storeOptions.length + 1,
          itemBuilder: (context, index) {
            if (index == storeOptions.length) {
              return _buildModeToggleTile(theme);
            }

            final store = storeOptions[index];
            final isSelected = tappedStores.contains(store);
            final selectionColor =
            isIncludeMode ? theme.secondary : theme.accent;

            return GestureDetector(
              onTap: () => onToggleStore(store),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                        isSelected ? selectionColor : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                        child: StoreLogo(storeName: store, height: 40)),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        isIncludeMode
                            ? Icons.check_box
                            : Icons.do_not_disturb_on,
                        color: selectionColor,
                        size: 22,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeToggleTile(AppThemeData theme) {
    final iconData = isIncludeMode ? Icons.add_circle : Icons.remove_circle;
    final iconColor = isIncludeMode ? theme.secondary : theme.accent;

    return GestureDetector(
      onTap: onToggleMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor, width: 2.0),
        ),
        child: Center(
          child: Icon(iconData, color: iconColor, size: 36),
        ),
      ),
    );
  }
}