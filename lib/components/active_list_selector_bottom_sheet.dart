import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/providers/shopping_list_provider.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class ActiveListSelectorBottomSheet extends ConsumerWidget {
  const ActiveListSelectorBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the providers for the list of all shopping lists and the currently active one.
    final shoppingLists = ref.watch(shoppingListsProvider);
    final activeList = ref.watch(activeShoppingListProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Make the sheet only as tall as its content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select an Active List',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Divider(height: 24),

          // Handle the case where no lists exist yet.
          if (shoppingLists.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  "No lists exist yet.\nPlease create one from the 'Lists' page.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inactive),
                ),
              ),
            )
          else
          // Use Flexible and ListView for a scrollable list of items.
            Flexible(
              child: ListView.builder(
                shrinkWrap: true, // Important for ListView inside a Column
                itemCount: shoppingLists.length,
                itemBuilder: (context, index) {
                  final list = shoppingLists[index];
                  final bool isActive = list.name == activeList;

                  return Card(
                    elevation: isActive ? 2 : 0,
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    child: ListTile(
                      title: Text(
                        list.name,
                        style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                      ),
                      // When a list is tapped, set it as active and close the sheet.
                      onTap: () {
                        ref.read(activeShoppingListProvider.notifier).setActiveList(list.name);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}